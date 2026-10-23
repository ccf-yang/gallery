#!/usr/bin/env bash
# Build a linux/arm64 image and save it as build/gallery-linux-arm64.tar
#
# On Armbian:
#   git clone https://github.com/ccf-yang/gallery.git
#   docker load -i gallery/build/gallery-linux-arm64.tar
#   docker run --rm -p 80:80 \
#     -v "$PWD/data/config:/app/data/config" \
#     -v "$PWD/data/db:/app/data/db" \
#     -v "$PWD/photos:/app/data/images:ro" \
#     -v "$PWD/data/tmp:/app/data/tmp" \
#     gallery:arm64
set -euo pipefail

cd "$(dirname "$0")"

IMAGE_NAME="${IMAGE_NAME:-gallery:arm64}"
OUT_DIR="${OUT_DIR:-build}"
TAR_NAME="${TAR_NAME:-gallery-linux-arm64.tar}"
PLATFORM="${PLATFORM:-linux/arm64}"

need() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "missing command: $1" >&2
		exit 1
	}
}

need node
need npm
need docker

echo "==> node $(node -v), npm $(npm -v)"

if [ ! -d node_modules ]; then
	echo "==> npm ci"
	if [ -f package-lock.json ]; then
		npm ci
	else
		npm install
	fi
fi

echo "==> create-release"
npm run create-release -- --languages=en,cn

if [ ! -d release ]; then
	echo "release/ was not created" >&2
	exit 1
fi

# keep the image small: diagnostics fixtures are not needed at runtime
rm -rf release/src/backend/model/diagnostics/image_formats

rm -rf pigallery2-release
mv release pigallery2-release

mkdir -p "$OUT_DIR"
out="$OUT_DIR/$TAR_NAME"

echo "==> docker build --platform $PLATFORM"
if docker buildx version >/dev/null 2>&1; then
	docker buildx create --name gallerybuilder --use >/dev/null 2>&1 || docker buildx use gallerybuilder
	docker buildx inspect --bootstrap >/dev/null
	docker buildx build \
		--platform "$PLATFORM" \
		--load \
		-t "$IMAGE_NAME" \
		-f Dockerfile \
		.
else
	docker build --platform "$PLATFORM" -t "$IMAGE_NAME" -f Dockerfile .
fi

echo "==> docker save $IMAGE_NAME -> $out"
docker save "$IMAGE_NAME" -o "$out"
chmod 0644 "$out"

echo
echo "built $IMAGE_NAME"
ls -lh "$out"
echo
echo "load on arm64:"
echo "  docker load -i $out"
echo "  docker run --rm -p 80:80 $IMAGE_NAME"
