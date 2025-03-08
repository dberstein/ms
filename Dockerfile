FROM alpine:3.21 AS builder

ARG MS_VER=8.4.0

RUN apk update \
 && apk add bash curl wget \
 && apk upgrade \
 && echo 'LANG="en_US.utf8"' > /etc/locale.conf

SHELL ["/bin/bash", "-o", "pipefail", "-cux"]

# build mapserver
RUN apk add --update \
     alpine-sdk ca-certificates cairo cmake fcgi freetype fribidi gdal geos giflib harfbuzz harfbuzz-cairo jpeg libjpeg libpq libxml2 libzip proj protobuf protobuf-c unzip \
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

FROM builder AS runtime

SHELL ["/bin/bash", "-o", "pipefail", "-cux"]

# configure mapserver
ARG MAPSERVER_CONFIG_FILE=/etc/ms.map
ENV MAPSERVER_CONFIG_FILE=${MAPSERVER_CONFIG_FILE}
COPY ms.map ${MAPSERVER_CONFIG_FILE}

# configure apache
COPY ms.conf /etc/apache2/conf.d/
RUN apk add apache2 apache2-utils \
 && ln -s $(which mapserv) /var/www/localhost/cgi-bin \
 && sed -Ei'' 's/#(LoadModule cgid?_module modules\/mod_cgid?\.so)/\1/g' /etc/apache2/httpd.conf

ENTRYPOINT ["sh", "-c"]
CMD ["httpd -k start && sh"]
