#!/bin/env bash
# $Id: entrypoint.sh,v 0.1 2016/04/10 $ $Author: Angelo Landino $

if [ "$1" = "start-stack" ]; then

    # while :
    # do
    #     echo "Press [CTRL+C] to stop.."
    #     sleep 5
    # done

    #bootloading for configuration
    #/bin/bash /docker/scripts/bootloader.sh

    #call supervisord to launch the whole stack
    /usr/bin/supervisord --nodaemon --configuration=/docker/configuration/supervisord/supervisor.conf

fi