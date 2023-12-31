# GTK4 Cross compile for Windows

## Prebuilt images

Images can be found on [GitHub container repository](https://github.com/felinira/gtk4-cross-win/pkgs/container/gtk4-cross-win).

### To pull from GitHub container repository

Example for GTK 4.10:

```bash
docker pull ghcr.io/felinira/gtk4-cross-win:gtk-4.10
```

Or nightly

```bash
docker pull ghcr.io/felinira/gtk4-cross-win:gtk-nightly
```

## Cross compilation

### Rust project

Create a container inside your project and run it

```bash
docker run -ti -v `pwd`:/mnt gtk4-cross-win
```

If your Docker host uses SELinux and you're getting errors about Cargo.toml not being found when trying to build, you may need to add `:z` to the end of the volume mount path, like so:

```bash
docker run -ti -v `pwd`:/mnt:z gtk4-cross-win
```

Then run `build` to build the project and `package` to package it into a zip file.

`package.zip` will be present in your project directory.

## Image building

To create required images, clone the repository and cd into the root.

To build any images other than the base one, you will need to have prebuilt the base image.

### Build script

There's a file `build_image.sh` present in the root of the repository.
It takes environment variables and one cmdline argument to build the image you want.

|ENV|Default|Description|
|---|---|---|
|GTK|"main"|GTK version to be built|
|ADW|"main"|ADW version to be built|
|BASE|"gtk4-cross-base-$GTK-$ADW"|Base image name for Docker, only used on images built on top of the base image|
|TAG|"$IMAGE-$GTK-$ADW"|A name set for the output image|

The script takes one argument, which can be
|Argument|Description|
|---|---|
|`base`|Which builds the base image.|
|`rust`|Which builds the rust image.|

## Image creation

If you want to create your own project builder

- create a new directory with your own name `gtk4-cross-<language>` (`<language>` should be replaced with whatever your project relies on and makes it recognisable)
- `cd` into the new directory
- create a file `build.sh` that's going to contain your building code.
- link `package.sh` from the root into the directory

```bash
ln ../package.sh package.sh
```

- create a new `Dockerfile`, and put in the following boilerplate to have a runnable container.

```docker
FROM gtk4-cross-win

ADD build.sh /usr/bin
RUN chmod +x /usr/bin/build.sh

ADD package.sh /usr/bin
RUN chmod +x /usr/bin/package.sh

CMD ["/bin/bash"]
```

- build the image

```bash
docker build gtk4-cross-<language> -t gtk4-cross-<language>
```

- use the image

```bash
docker run -ti -v `pwd`:/mnt gtk4-cross-<language>
```

- add a section about your new builder to this `README.md`
- contribute :)
