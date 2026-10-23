# gallery

Trimmed PiGallery2 photo gallery for Armbian (linux/arm64).

Developer: ccf-yang

The arm64 Docker image is built by GitHub Actions on every push to `master` and
published as a plain `docker save` tar under the rolling release tag `arm64`.
On the board you only need `git clone` + `docker load`.

## Armbian (linux/arm64)

```bash
git clone https://github.com/ccf-yang/gallery.git
cd gallery
bash build/load.sh          # downloads build/gallery-linux-arm64.tar.gz, docker load
mkdir -p data/config data/db data/tmp photos
docker run -d --name gallery --restart unless-stopped \
  -p 80:80 \
  -v "$PWD/data/config:/app/data/config" \
  -v "$PWD/data/db:/app/data/db" \
  -v "$PWD/photos:/app/data/images:ro" \
  -v "$PWD/data/tmp:/app/data/tmp" \
  gallery:arm64
```

Put photos in `photos/`. Open `http://<host>/` and log in with `admin` / `admin`.

`build/load.sh` options: `FORCE_DOWNLOAD=1` refetches the tar, `CHECKSUM=1`
verifies its sha256 before loading. The downloaded tar stays in `build/` so
reloading after a Docker wipe costs no bandwidth.

## Building the image

CI (`.github/workflows/build-arm64-image.yml`) does the whole chain:
`npm ci` -> `npm run create-release -- --languages=en,cn` -> `docker build
--platform linux/arm64` -> `docker save | gzip` -> release tag `arm64`.
Trigger it manually from the Actions tab if you skipped it with a push.

To build locally instead, on a machine that has Node.js 22, npm and Docker:

```bash
./build_image.sh            # writes build/gallery-linux-arm64.tar
```

Set `PLATFORM`, `IMAGE_NAME`, `TAR_NAME` to override. The build runs on a
GitHub-hosted `linux/arm64` runner, so native modules (sharp, bcrypt,
better-sqlite3) are compiled for arm64, not emulated.
