# gallery

Trimmed PiGallery2 photo gallery. Armbian usage is `git clone` then `docker load`.

Developer: ccf-yang

## Armbian (linux/arm64)

```bash
git clone https://github.com/ccf-yang/gallery.git
cd gallery
docker load -i build/gallery-linux-arm64.tar
mkdir -p data/config data/db data/tmp photos
docker run -d --name gallery --restart unless-stopped \
  -p 80:80 \
  -v "$PWD/data/config:/app/data/config" \
  -v "$PWD/data/db:/app/data/db" \
  -v "$PWD/photos:/app/data/images:ro" \
  -v "$PWD/data/tmp:/app/data/tmp" \
  gallery:arm64
```

Put photos in `photos/`. Open `http://<host>/`.

## Rebuild the image

```bash
./build_image.sh
```

Writes `build/gallery-linux-arm64.tar`. Needs Node.js 22, npm, Docker with arm64 (buildx/qemu on x86_64).
