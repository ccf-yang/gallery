#!/usr/bin/env bash
# Download the prebuilt linux/arm64 image from the GitHub release and load it
# into the local Docker engine.
#
#   bash build/load.sh
#   FORCE_DOWNLOAD=1 bash build/load.sh   # refetch even if the tar is cached
#   CHECKSUM=1 bash build/load.sh         # verify sha256 after download
#
set -euo pipefail

REPO="${REPO:-ccf-yang/gallery}"
TAG="${TAG:-arm64}"
ASSET="${ASSET:-gallery-linux-arm64.tar.gz}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${OUT:-${HERE}/${ASSET}}"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"

for cmd in curl docker; do
	command -v "$cmd" >/dev/null 2>&1 || {
		echo "missing command: $cmd" >&2
		exit 1
	}
done

if [ "${FORCE_DOWNLOAD:-0}" = "1" ]; then
	rm -f "$OUT" "${OUT}.sha256"
fi

if [ -s "$OUT" ]; then
	echo "==> reusing ${OUT} (FORCE_DOWNLOAD=1 to refetch)"
else
	echo "==> downloading ${URL}"
	# -C - resumes an interrupted transfer
	curl -fL --retry 3 --retry-delay 3 --connect-timeout 20 -C - -o "$OUT" "$URL"
fi

bytes=$(wc -c <"$OUT" | tr -d ' ')
if [ "${bytes}" -lt 20000000 ]; then
	echo "!! ${OUT} is only ${bytes} bytes -- looks truncated, deleting" >&2
	rm -f "$OUT"
	exit 1
fi
echo "==> ${OUT}: ${bytes} bytes"

if [ "${CHECKSUM:-0}" = "1" ]; then
	echo "==> verifying sha256"
	curl -fL --retry 3 -o "${OUT}.sha256" "${URL}.sha256"
	(cd "$(dirname "$OUT")" && sha256sum -c "$(basename "$OUT").sha256")
fi

echo "==> docker load -i ${OUT}"
docker load -i "$OUT"

echo
echo "Image loaded. Start it (data lives next to the repo):"
cat <<'EOF'
  mkdir -p data/config data/db data/tmp photos
  docker run -d --name gallery --restart unless-stopped \
    -p 80:80 \
    -v "$PWD/data/config:/app/data/config" \
    -v "$PWD/data/db:/app/data/db" \
    -v "$PWD/photos:/app/data/images:ro" \
    -v "$PWD/data/tmp:/app/data/tmp" \
    gallery:arm64
EOF
echo "Then open http://<host>/  (admin / admin)"
