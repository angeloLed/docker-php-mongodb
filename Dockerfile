FROM alpine:edge

MAINTAINER Pietro Bonaccorso 'angelolandino@hotmail.it'
LABEL description='This image embeds Nginx 1.9 and php-fpm using PHP 7'

ENV APP_CWD='/app/code' \
APP_USER='application' \
APP_GROUP='application' \
VHOST_ROOT='/app/code' \
VHOST_INDEX='index.php' \
VHOST_TRYFILES='try_files $uri $uri/ /index.php?$query_string;' \
PHP_MAXEXECUTIONTIME='30' \
PHP_MEMORYLIMIT='128M' \
PHP_DISPLAYERRORS='Off' \
PHP_DISPLASTARTUPERRORS='Off' \
PHP_ERRORREPORTING='E_ALL & ~E_DEPRECATED & ~E_STRICT' \
PHP_VARIABLESORDER='GPCS' \
PHP_POSTMAXSIZE='8M' \
PHP_UPLOADMAXFILESIZE='2M' \
PHP_SHORTOPENTAG='Off' \
FPM_USER='application' \
FPM_GROUP='application' \
FPM_LISTEN='127.0.0.1:9000' \
FPM_CLEARENV='no'

#install bash
RUN apk --update add bash

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

#install php 7
RUN apk --update add php7 \
php7-redis php7-memcached php7-xsl php7-zlib php7-session \
php7-sqlite3 php7-xml php7-xmlreader php7-mcrypt php7-mysqli \
php7-odbc php7-openssl php7-pdo php7-pdo_dblib php7-pdo_mysql php7-pdo_odbc \
php7-pdo_pgsql php7-pdo_sqlite php7-phar php7-posix php7-ctype php7-curl \
php7-dba php7-ftp php7-gd php7-gmp php7-iconv \
php7-json php7-ldap php7-mbstring php7-bcmath \
php7-phpdbg php7-mongodb \
php7-xdebug php7-fpm

# php7-json php7-zlib php7-xml php7-phar php7-openssl \
# php7-gd php7-iconv php7-mcrypt php7-posix \
# php7-curl php7-opcache php7-ctype php7-apcu \
# php7-pdo php7-mysql php7-pdo_mysql php7-mysqli \
# php7-pdo_sqlite php7-sqlite3 \
# php7-intl php7-bcmath php7-dom php7-xmlreader \
# php7-fpm php7-xdebug

#packages extra


#rename bins
RUN mv /usr/sbin/php-fpm7 /usr/sbin/php-fpm && mv /usr/bin/php7 /usr/bin/php

#install nginx
RUN apk --update add nginx openssl

#install composer
RUN wget https://getcomposer.org/composer.phar -O /usr/bin/composer && chmod +x /usr/bin/composer

#install supervisord
RUN apk --update add supervisor

#Add configuration files
COPY . /docker

#remove apk cache
RUN rm -rf /var/cache/apk/* && rm -rf /tmp/*

#expose ports
EXPOSE 80 443

ENTRYPOINT ["bash", "/docker/scripts/entrypoint.sh"]
CMD ["start-stack"]

WORKDIR $APP_CWD