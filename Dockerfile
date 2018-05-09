FROM nginx:1.10.1-alpine
LABEL maintainer "Giuseppe Iannelli <giuseppe.iannelli@mosaicoon.com>, Pietro Bonaccorso <pietro.b@mosaicoon.com>"
LABEL description "Nginx, PHP 7 stack running on alpine with supervisord"

###############################################################################
################################ GLOBAL ENVS ##################################
###############################################################################

ENV APP_CWD='/app/code' \
  NGINX_SERVER_START="ON" \
  NGINX_CLIENTMAXBODYSIZE='8M' \
  VHOST_ROOT='/app/code' \
  VHOST_INDEX='index.php' \
  PHP_MAXEXECUTIONTIME='30' \
  PHP_MEMORYLIMIT='128M' \
  PHP_DISPLAYERRORS='Off' \
  PHP_DISPLASTARTUPERRORS='Off' \
  PHP_ERRORREPORTING='E_ALL & ~E_DEPRECATED & ~E_STRICT' \
  PHP_VARIABLESORDER='GPCS' \
  PHP_POSTMAXSIZE='8M' \
  PHP_UPLOADMAXFILESIZE='2M' \
  PHP_SHORTOPENTAG='Off' \
  PHP_MODULE_PTHREADS_ENABLE="OFF" \
  PHP_MODULE_MONGODB_ENABLE="ON" \
  PHP_MODULE_KAFKA_ENABLE="ON" \
  FPM_USER='application' \
  FPM_GROUP='application' \
  FPM_LISTEN='127.0.0.1:9000' \
  FPM_CLEARENV='no' \
  FPM_CUSTOM_LOGFILE_BASE="/var/log/php-fpm/" \
  FPM_CUSTOM_LOGFILE="$FPM_CUSTOM_LOGFILE_BASE/custom.log" \
  APP_USER=${FPM_USER} \
  APP_GROUP=${FPM_GROUP}

###############################################################################
################################## BUILD PHP ##################################
###############################################################################

ENV PHP_INI_DIR='/usr/local/etc/php' \
  PHP_EXTRA_CONFIGURE_ARGS='--enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --enable-maintainer-zts --enable-zip --with-libdir=/usr/lib' \
  GPG_KEYS='1A4E8B7277C42E53DBA9C7B9BCAA30EA9C0D5763' \
  PHP_VERSION='7.0.11' \
  PHP_FILENAME='php-7.0.11.tar.xz' \
  PHP_SHA256='d4cccea8da1d27c11b89386f8b8e95692ad3356610d571253d00ca67d524c735'

# persistent / runtime deps
RUN apk add --no-cache --virtual .persistent-deps \
		ca-certificates \
		curl \
    freetype \
    libjpeg \
    libpng \
    libvpx \
    libldap \
    libmcrypt \
		tar \
		xz

# ensure www-data user exists
RUN set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data \
  && mkdir -p $PHP_INI_DIR/conf.d
# 82 is the standard uid/gid for "www-data" in Alpine
# http://git.alpinelinux.org/cgit/aports/tree/main/apache2/apache2.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/lighttpd/lighttpd.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/nginx-initscripts/nginx-initscripts.pre-install?h=v3.3.2

#Downloading PHP
RUN set -xe \
	&& apk add --no-cache --virtual .fetch-deps \
		gnupg \
	&& mkdir -p /usr/src \
	&& cd /usr/src \
	&& curl -fSL "https://secure.php.net/get/$PHP_FILENAME/from/this/mirror" -o php.tar.xz \
	&& echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c - \
	&& curl -fSL "https://secure.php.net/get/$PHP_FILENAME.asc/from/this/mirror" -o php.tar.xz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done \
	&& gpg --batch --verify php.tar.xz.asc php.tar.xz \
	&& rm -r "$GNUPGHOME" \
	&& apk del .fetch-deps

#Install build dependences
RUN set -xe \
	&& apk add --no-cache --virtual .build-deps \
    autoconf \
    bison \
    curl-dev \
    file \
    freetype-dev \
    g++ \
    gcc \
    libc-dev \
    libedit-dev \
    libjpeg-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
		libxml2-dev \
    make \
    pkgconf \
    re2c \
    openldap-dev \
		openssl-dev \
		sqlite-dev

#Configure and build PHP
RUN  mkdir -p /usr/src/php \
  && tar -Jxf /usr/src/php.tar.xz -C /usr/src/php --strip-components=1 \
	&& cd /usr/src/php \
	&& ./configure \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--disable-cgi \
    --enable-exif \
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
		--enable-ftp \
    --enable-fpm \
    --enable-mailparse \
    --enable-maintainer-zts \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
    --enable-pcntl \
    --enable-soap \
    --enable-sockets \
    --enable-zip \
		--with-curl \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data \
    --with-gd \
    --with-freetype-dir=/usr/lib/ \
    --with-jpeg-dir=/usr/lib \
    --with-png-dir=/usr/lib \
    --with-vpx-dir=/usr/lib \
    # --with-imap \
    # --with-ldap \
    --with-ldap-sasl \
    --with-libdir=/usr/lib \
		--with-libedit \
    --with-mcrypt  \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
		--with-openssl \
		--with-zlib \
  && make -j"$(getconf _NPROCESSORS_ONLN)" \
	&& make install \
	&& make test \
	&& make clean

#Create php.ini
RUN cp /usr/src/php/php.ini-production $PHP_INI_DIR/php.ini

###############################################################################
############################# PHP EXTRA MODULES ###############################
###############################################################################

#Copy files needed to configuring and booting stack
COPY docker/ /docker/

#Install pthreads PHP modules
RUN touch /docker/configurations/php/conf.d/pthreads.ini \
  && pecl config-set php_ini /docker/configurations/php/conf.d/pthreads.ini \
 	&& pear config-set php_ini /docker/configurations/php/conf.d/pthreads.ini \
 	&& pecl install pthreads

#Install MongoDB Driver (http://php.net/manual/en/set.mongodb.php)
RUN touch /docker/configurations/php/conf.d/mongodb.ini \
  && pecl config-set php_ini /docker/configurations/php/conf.d/mongodb.ini \
 	&& pear config-set php_ini /docker/configurations/php/conf.d/mongodb.ini \
 	&& pecl install mongodb

#Install redis PHP modules
RUN touch $PHP_INI_DIR/conf.d/redis.ini \
  && pecl config-set php_ini $PHP_INI_DIR/conf.d/redis.ini \
 	&& pear config-set php_ini $PHP_INI_DIR/conf.d/redis.ini \
 	&& pecl install redis

#Install SSH2 Driver (http://pecl.php.net/package/ssh2)
RUN touch $PHP_INI_DIR/conf.d/ssh.ini \
  && pecl config-set php_ini /docker/configurations/php/conf.d/ssh.ini \
 	&& pear config-set php_ini /docker/configurations/php/conf.d/ssh.ini \
 	&& pecl install ssh2-1.0

# #Install mailparser PHP modules
# RUN touch $PHP_INI_DIR/conf.d/mailparser.ini \
#   && pecl config-set php_ini $PHP_INI_DIR/conf.d/mailparser.ini  \
#  	&& pear config-set php_ini $PHP_INI_DIR/conf.d/mailparser.ini  \
#  	&& pecl install mailparse

#Install dependences to clone kafka lib from git repositories
RUN apk add --no-cache git bash python

#Install librdkafka and php-rdkafka
RUN cd /usr/src/ \
  && git clone https://github.com/edenhill/librdkafka.git \
  && cd librdkafka/ \
  && ./configure \
  && make -j"$(getconf _NPROCESSORS_ONLN)" \
  && make install \
  && cd /usr/src/ \
  && rm -rf /usr/src/librdkafka/ \
  && echo "librdkafka built" \
  && git clone https://github.com/arnaud-lb/php-rdkafka.git \
  && cd php-rdkafka/ \
  && git checkout php7 \
  && git reset --hard 4e6a07438bf1664f995c76ad74800d57100e525d \
  && phpize \
  && ./configure \
  && make all -j"$(getconf _NPROCESSORS_ONLN)" \
  && make install \
  && cd /usr/src/ \
  && rm -rf /usr/src/php-rdkafka \
  && echo 'extension="rdkafka.so"' > /docker/configurations/php/conf.d/kafka.ini

#Remove PHP source code and install php run dependences
RUN cd /usr/src \
  && rm -rf /usr/src/php* \
	&& runDeps="$( \
		scanelf --needed --nobanner --recursive /usr/local \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --no-cache --virtual .php-rundeps $runDeps \
	&& apk del .build-deps

#Create extra configuration files for php-fpm and docker
RUN set -ex \
	&& cd /usr/local/etc \
	&& if [ -d php-fpm.d ]; then \
		# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		# PHP 5.x don't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
		{ \
			echo '[global]'; \
			echo 'include=etc/php-fpm.d/*.conf'; \
		} | tee php-fpm.conf; \
	fi \
	&& { \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
    #echo 'error_log = /var/log/php-fpm/error.log'; \
		echo; \
		echo '[www]'; \
		echo '; if we send this to /proc/self/fd/1, it never appears'; \
		echo 'access.log = /proc/self/fd/2'; \
    #echo 'access.log = /var/log/php-fpm/access.log'; \
		echo; \
		echo 'clear_env = <FPM_CLEARENV>;' \
    echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
	} | tee php-fpm.d/docker.conf \
	&& { \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = [::]:9000'; \
	} | tee php-fpm.d/zz-docker.conf


#install composer for PHP
RUN curl -fSL https://getcomposer.org/composer.phar -o /usr/bin/composer && chmod +x /usr/bin/composer

###############################################################################
################################ SETUP STACK ##################################
###############################################################################

#install supervisord
RUN apk --update add supervisor

###############################################################################
################################ START STACK ##################################
###############################################################################

# store php-fpm and supervisord log
RUN mkdir -p $FPM_CUSTOM_LOGFILE_BASE /var/log/supervisord/ \
    && mkfifo -m 666 $FPM_CUSTOM_LOGFILE \
    && touch /var/log/supervisord/supervisord.log \
    && mkdir /crontabs

EXPOSE 80 443

#Install extra package
RUN apk --update add openssh

#This procedure is called in every images built FROM this image
ONBUILD RUN bash /docker/scripts/bootstrap.sh
RUN bash /docker/scripts/bootstrap.sh

ENTRYPOINT ["bash", "/docker/scripts/entrypoint.sh"]

WORKDIR $APP_CWD

CMD ["start-stack"]
