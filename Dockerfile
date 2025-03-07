FROM alpine:3.21 AS builder

ARG MS_VER=8.4.0

RUN apk update \
 && apk add bash curl wget \
 && apk upgrade

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
ARG MAPSERVER_CONFIG_FILE=/etc/ms.conf
ENV MAPSERVER_CONFIG_FILE=${MAPSERVER_CONFIG_FILE}
COPY ms.conf ${MAPSERVER_CONFIG_FILE}

# configure apache
RUN apk add --update apache2 apache2-utils \
 && echo 'LANG="en_US.utf8"' > /etc/locale.conf \
 && ln -s $(which mapserv) /var/www/localhost/cgi-bin \
 && sed -Ei'' 's/#(LoadModule cgid?_module modules\/mod_cgid?\.so)/\1/g' /etc/apache2/httpd.conf \
 && printf ' \n\
<Directory "/var/www/localhost/cgi-bin"> \n\
    AllowOverride None \n\
    Options +ExecCGI -MultiViews -SymLinksIfOwnerMatch +FollowSymLinks \n\
    Require all granted \n\
</Directory> \n' > /etc/apache2/conf.d/ms.conf

ENTRYPOINT ["sh", "-c"]
CMD ["httpd -k start && sh"]
