#!/bin/env bash
#Maintainer Giuseppe Iannelli <giuseppe.iannelli@mosaicoon.com>

#Questo script viene eseguito soltanto durante la build dell'immagine.
#Specificare i moduli da attivare alla build dell'immagine

#load PHP external modules
if [ "$PHP_MODULE_PTHREADS_ENABLE" != "ON" ]; then
    #rm -f $PHP_INI_DIR'/conf.d/pthreads.ini'
    echo 'PHP Pthreads module disabled'
else
    cp -f /docker/configurations/php/conf.d/pthreads.ini $PHP_INI_DIR'/conf.d/pthreads.ini'
    echo 'PHP Pthreads module enabled'
fi

if [ "$PHP_MODULE_MONGODB_ENABLE" != "ON" ]; then
    #rm -f $PHP_INI_DIR'/conf.d/mongodb.ini'
    echo 'PHP mongoDB module disabled'
else
    cp -f /docker/configurations/php/conf.d/mongodb.ini $PHP_INI_DIR'/conf.d/mongodb.ini'
    echo 'PHP mongoDB module enabled'
fi

if [ "$PHP_MODULE_KAFKA_ENABLE" != "ON" ]; then
    #rm -f $PHP_INI_DIR'/conf.d/kafka.ini'
    echo 'PHP kafka module disabled'
else
    cp -f /docker/configurations/php/conf.d/kafka.ini $PHP_INI_DIR'/conf.d/kafka.ini'
    echo 'PHP kafka module enabled'
fi

echo "Copying PHP custom configurations file"
cp /docker/configurations/php/conf.d/app-php.ini /usr/local/etc/php/conf.d/app-php.ini

#create group if not exists
getent group $FPM_GROUP || addgroup $FPM_GROUP

#create application user if not exists and assig it to the specified application group
id -u $FPM_USER &> /dev/null || adduser -D -s /bin/bash -G $FPM_GROUP $FPM_USER

#create application folder if not exists
if ! [[ -d $APP_CWD ]] ; then mkdir -p $APP_CWD ; fi

#assign user and group permission to application folder
chown -Rf $FPM_USER:$FPM_GROUP $APP_CWD
