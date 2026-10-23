# linux/arm64 image for Armbian.
# Frontend/backend JS is built on the host; this file only installs
# native modules (sharp, bcrypt, better-sqlite3) and runtime libs.

FROM node:22-alpine3.23 AS builder

ENV SHARP_FORCE_GLOBAL_LIBVIPS=1 \
    NODE_ENV=production

RUN apk add --no-cache --update \
    vips vips-dev vips-heif vips-magick \
    libheif libpng libjpeg-turbo libde265 libwebp libraw-dev \
    g++ make gcc build-base python3 pkgconfig

COPY pigallery2-release /app
WORKDIR /app
RUN npm install --omit=dev --no-package-lock \
      node-addon-api@8.5.0 node-gyp@11.5.0 \
    && npm cache clean --force \
    && mkdir -p /app/data/config /app/data/db /app/data/images /app/data/tmp

FROM node:22-alpine3.23

WORKDIR /app
ENV NODE_ENV=production \
    default-Database-dbFolder=/app/data/db \
    default-Media-folder=/app/data/images \
    default-Media-tempFolder=/app/data/tmp \
    default-Extensions-folder=/app/data/config/extensions \
    PI_DOCKER=true

EXPOSE 80

RUN apk add --no-cache vips vips-cpp vips-heif vips-magick ffmpeg \
    && rm -rf /var/cache/apk/*

COPY --from=builder /app /app

HEALTHCHECK --interval=40s --timeout=30s --retries=3 --start-period=60s \
  CMD wget --quiet --tries=1 --no-check-certificate --spider \
  http://127.0.0.1:80/heartbeat || exit 1

ENTRYPOINT ["node", "--expose-gc", "./src/backend/index", "--config-path=/app/data/config/config.json"]
