#!/bin/env bash
#Maintainer Giuseppe Iannelli <giuseppe.iannelli@mosaicoon.com>

if [ "$1" = "start-stack" ]; then

    #init and start stack
    if [ "$PHP_MODULE_PTHREADS_ENABLE" != "ON" ]; then
        cat '/docker/configurations/supervisord/conf.d/php-fpm.conf' >> /docker/configurations/supervisord/supervisor.conf
        cat '/docker/configurations/supervisord/conf.d/php-fpm-logger.conf' >> /docker/configurations/supervisord/supervisor.conf
        cp -f /docker/configurations/php-fpm/conf.d/www.conf /usr/local/etc/php-fpm.d/www.conf
        echo 'PHP-fpm enabled in supervisor stack'
    else
        echo 'PHP-fpm disabled in supervisor stack'
    fi

    if [ "$NGINX_SERVER_START" != "ON" ]; then
        echo 'Nginx disabled in supervisor stack'
    else
        cp -f /docker/configurations/nginx/conf.d/nginx.conf /etc/nginx/nginx.conf
        #sed  -i ' 5 s/.*/&user '$APP_USER' '$APP_GROUP'/' /etc/nginx/nginx.conf
        cp -f /docker/configurations/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
        cat /docker/configurations/supervisord/conf.d/nginx.conf >> /docker/configurations/supervisord/supervisor.conf
        echo 'Nginx enabled in supervisor stack'
    fi

    #Parse configuration files with env variables
    for var in $(printenv); do

        #explode vars to retrive key/value pairs
        IFS='=' read -r -a array <<< $var

        export KEY=${array[0]}

        if [[ $KEY =~ APP_|NGINX_|VHOST_|PHP_|FPM_ ]]; then

            export VALUE=${array[1]}

            sed -i -e 's|<'$KEY'>|'$VALUE'|g' '/etc/nginx/nginx.conf'
            sed -i -e 's|<'$KEY'>|'$VALUE'|g' '/etc/nginx/conf.d/default.conf'
            sed -i -e 's|<'$KEY'>|'$VALUE'|g' '/usr/local/etc/php/conf.d/app-php.ini'
            sed -i -e 's|<'$KEY'>|'$VALUE'|g' '/usr/local/etc/php-fpm.d/www.conf'
            sed -i -e 's|<'$KEY'>|'$VALUE'|g' '/usr/local/etc/php-fpm.d/docker.conf'

        fi

    done

      echo "Starting supervisord..."
      /usr/bin/supervisord --configuration=/docker/configurations/supervisord/supervisor.conf

elif [ "$1" = "cron" ]; then

  #put your crontab in crontabs
  crond -f  -c /crontabs

else
  #Run every command passed when running container
  $@

fi
