FROM fedora:39
WORKDIR /root
RUN dnf install -y git cmake gcc-c++ boost-devel
RUN git clone https://github.com/gsauthof/pe-util
WORKDIR /root/pe-util
RUN git submodule update --init
RUN mkdir build
WORKDIR /root/pe-util/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release
RUN make

FROM fedora:39
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# RUN . ~/.cargo/env 
# Set the rust linker to gcc
# RUN echo "[target.x86_64-pc-windows-gnu]\nlinker = \"x86_64-w64-mingw32-gcc\"\nar = \"x86_64-w64-mingw32-gcc-ar\"" > /home/rust/.cargo/config
RUN dnf install -y gcc
RUN . ~/.cargo/env && cargo install --git https://github.com/mglolenstine/peldd_dependency_scanner.git

FROM fedora:39
COPY --from=0 /root/pe-util/build/peldd /usr/bin/peldd
COPY --from=1 /root/.cargo/bin/peldd_dependency_scanner /usr/bin/pds
RUN dnf install git mingw64-binutils mingw64-gcc meson mingw64-pango mingw64-gdk-pixbuf mingw64-libepoxy mingw64-winpthreads-static mingw64-glib2 glib2-devel gobject-introspection-devel mingw64-gstreamer1-plugins-bad-free vala wine cmake gcc zip boost boost-system dos2unix sassc mingw64-librsvg2 intltool itstool gtk-update-icon-cache adwaita-icon-theme mingw64-adwaita-icon-theme mingw64-gettext mingw64-libyaml mingw64-libxmlb gperf libcurl-devel libyaml-devel libxml2-devel libzstd-devel libxmlb-devel libxslt-devel docbook-style-xsl -y && dnf clean all -y

# Install appstream 1.0 on host
WORKDIR /tmp
ADD "https://api.github.com/repos/ximion/appstream/commits?per_page=1" latest_commit
RUN git clone --depth=1 --branch main https://github.com/ximion/appstream.git

WORKDIR /tmp/appstream
RUN meson build -Dprefix=/usr -Dstemming=false -Dsystemd=false -Dgir=false -Dsvg-support=false -Ddocs=false -Dapidocs=false -Dinstall-docs=false
RUN ninja -C build
RUN ninja -C build install

# Make the meson use mingw
ADD x86_64-meson /usr/bin
RUN dos2unix /usr/bin/x86_64-meson
RUN chmod +x /usr/bin/x86_64-meson

# Add mingw-env
ADD mingw-env /usr/bin
RUN dos2unix /usr/bin/mingw-env
RUN chmod +x /usr/bin/mingw-env

# Add package.sh
ADD package.sh /usr/bin/package
RUN dos2unix /usr/bin/package
RUN chmod +x /usr/bin/package

# Update with the new toolchain file
ADD toolchain-mingw64.meson /usr/share/mingw
RUN dos2unix /usr/share/mingw/toolchain-mingw64.meson

# Clone the gtk4 repository
WORKDIR /tmp
RUN git clone --depth=1 --branch %GTKTAG% https://gitlab.gnome.org/GNOME/gtk.git

# Hacks for GTK4 to compile
#ENV PKG_CONFIG_PATH /usr/x86_64-w64-mingw32/lib/pkgconfig
RUN cp /usr/x86_64-w64-mingw32/sys-root/mingw/include/windows.h /usr/x86_64-w64-mingw32/sys-root/mingw/include/Windows.h

RUN if [[ -e /tmp/gtk/gdk/loaders/gdkjpeg.c ]] ; then echo -e "#include <stdlib.h>\n$(cat /tmp/gtk/gdk/loaders/gdkjpeg.c)" > /tmp/gtk/gdk/loaders/gdkjpeg.c ; fi

# Enable Iphlpapi (on windows, they're case-insensitive, on linux they're not.)
RUN cp /usr/x86_64-w64-mingw32/sys-root/mingw/lib/libiphlpapi.a /usr/x86_64-w64-mingw32/sys-root/mingw/lib/libIphlpapi.a

# Add compiler paths
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/sys-root/mingw/lib/pkgconfig/:/usr/x86_64-w64-mingw32/lib/pkgconfig/
ENV GTK_INSTALL_PATH=/usr/x86_64-w64-mingw32/sys-root/mingw
ENV MINGW_PREFIX=/usr/x86_64-w64-mingw32/sys-root/mingw

# Fix paths in the pixbuf loaders.cache
    # Required for gdk-pixbuf-query-loaders.exe and other tools to work
ENV LANG="en_GB.utf8"
RUN wine --version
RUN wine $MINGW_PREFIX/bin/gdk-pixbuf-query-loaders.exe --update-cache


# Build and install GTK4
WORKDIR /tmp/gtk
RUN x86_64-meson build -Dintrospection=disabled -Dvulkan=disabled -Dtracker=disabled --wrap-mode=default
WORKDIR /tmp/gtk/build
RUN meson configure -Db_lto=false -Dc_link_args="['-lssp']" -Dc_args=-DG_ENABLE_DEBUG -Dbuild-examples=false -Dbuild-tests=false
RUN ninja all && ninja install

# Clone the libadwaita repository (Move after the mingw setup for efficiency later)
WORKDIR /tmp
RUN git clone --depth 1 --branch %ADWTAG% https://gitlab.gnome.org/GNOME/libadwaita.git

# Build and install libadwaita
WORKDIR /tmp/libadwaita

# Patch adw
ADD libadwaita-1-4-update-appstream.patch /tmp/libadwaita
RUN if [[ "%ADWTAG%" == "1.4.0" ]]; then git apply libadwaita-1-4-update-appstream.patch; fi

RUN x86_64-meson -Dintrospection=disabled -Dexamples=false -Dvapi=false build --wrap-mode=default
WORKDIR /tmp/libadwaita/build
RUN meson configure -Db_lto=false -Dc_link_args="['-lssp']"
RUN ninja all && ninja install

# Return to the current working directory
WORKDIR /mnt

## Commonly used packages
RUN dnf install wget yelp-tools librsvg2-tools ImageMagick -y
RUN dnf clean all -y

## RUST
# Setup rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
RUN . ~/.cargo/env && \
    rustup target add x86_64-pc-windows-gnu

# Set default linker to the GCC linker
ADD rust/cargo.config ~/.cargo/config

# Cleanup /tmp
RUN rm -rf /tmp/*

CMD ["/bin/bash"]
