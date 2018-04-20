FROM php:7.2.4-fpm

MAINTAINER Angelo Landino <angelo.landino@hotmail.it>

RUN apt-get update
RUN apt-get install -y autoconf pkg-config libssl-dev
RUN pecl install mongodb-1.4.3
RUN docker-php-ext-install bcmath
RUN echo "extension=mongodb.so" >> /usr/local/etc/php/conf.d/mongodb.ini

# Install Laravel dependencies
RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev

RUN docker-php-ext-install iconv mcrypt mbstring \
    && docker-php-ext-install zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

WORKDIR /code

COPY . /code
