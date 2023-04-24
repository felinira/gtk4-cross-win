#!/bin/bash
set -euo pipefail

GTK=${GTK:-"main"}
ADW=${ADW:-"main"}
BASE=${BASE:-"gtk4-cross-win-$GTK-$ADW"}
IMAGE="gtk4-cross-win"

# Set a name for the newly built image.
TAG=${TAG:-"$IMAGE-$GTK-$ADW"}

mkdir -p "tmp/$IMAGE"
cp -rL "$IMAGE" "tmp/"
# Replace GTK and Adwaita versions.
sed -i "s/%GTKTAG%/$GTK/g" "tmp/$IMAGE/Dockerfile" && sed -i "s/%ADWTAG%/$ADW/g" "tmp/$IMAGE/Dockerfile"

cd "tmp/$IMAGE" || exit
# Start the image build.
docker build . -t "$TAG"
# Clean up the tmp directory.
rm -rf "tmp/$IMAGE"