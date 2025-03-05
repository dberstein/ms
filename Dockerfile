FROM alpine:latest AS builder

ARG MS_VER=8.4.0

RUN apk update \
 && apk upgrade \
 && apk add --update \
     alpine-sdk cairo curl cmake fcgi freetype fribidi gdal geos giflib harfbuzz harfbuzz-cairo jpeg libjpeg libpq libxml2 libzip proj protobuf protobuf-c unzip wget \
     cairo-dev fcgi-dev freetype-dev fribidi-dev gdal-dev geos-dev giflib-dev harfbuzz-dev jpeg-dev libpq-dev libxml2-dev libzip-dev proj-dev protobuf-c-dev \
 && wget -O ms.zip https://github.com/MapServer/MapServer/releases/download/rel-$(echo ${MS_VER} | tr . -)/mapserver-${MS_VER}.zip \
 && unzip -o ms.zip \
 && mkdir -p mapserver-${MS_VER}/build \
 && cd mapserver-${MS_VER}/build \
 && cmake .. \
 && make install \
 && apk del alpine-sdk cairo-dev cmake fcgi-dev freetype-dev fribidi-dev gdal-dev geos-dev giflib-dev harfbuzz-dev jpeg-dev libpq-dev libxml2-dev libzip-dev proj-dev protobuf-c-dev \
 && rm -v ../../ms.zip \
 && rm -rvf ../../mapserver-${MS_VER}
