FROM php:7.2.4-fpm

LABEL maintainer "Angelo Landino <angelo.landino@hotmail.it>"

ARG MONGODB_DRIVER_VERSION=1.4.3

RUN apt-get update
RUN apt-get install -y autoconf pkg-config libssl-dev
RUN docker-php-ext-install bcmath

#Install MongoDB Driver (http://php.net/manual/en/set.mongodb.php)
RUN touch /usr/local/etc/php/conf.d/mongodb.ini \
&& pecl config-set php_ini /usr/local/etc/php/conf.d/mongodb.ini \
&& pear config-set php_ini /usr/local/etc/php/conf.d/mongodb.ini \
&& pecl install mongodb-${MONGODB_DRIVER_VERSION}


# Install Laravel dependencies
#RUN apt-get install -y \
#        libfreetype6-dev \
#        libjpeg62-turbo-dev \

#RUN docker-php-ext-install iconv mbstring \
#    && docker-php-ext-install zip --with-zlib-dir=/usr/include/ \
#    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
#    && docker-php-ext-install gd

WORKDIR /code

COPY . /code
