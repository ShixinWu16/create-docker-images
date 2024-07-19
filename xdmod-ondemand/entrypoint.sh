#!/bin/bash

set -e
set -o pipefail

if [ "$1" = "testbuild" ];
then
    BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    LOGPATH=/tmp/ondemand
    XDMOD_SRC_DIR=${XDMOD_SRC_DIR:-$BASEDIR/../../../xdmod}
    # Run the interactive setup to add a new resource and setup the database.
    expect $BASEDIR/setup.tcl | col -b

    # run xdmod-ingestor to add the new resource to the datawarehouse.
    sudo -u xdmod xdmod-ingestor

    mkdir $LOGPATH
    cp $BASEDIR/../artifacts/*.log $LOGPATH

    sudo -u xdmod xdmod-ondemand-ingestor -d $LOGPATH -r styx --debug
    /usr/sbin/postfix start
    php-fpm
    rm -f /var/run/httpd/httpd.pid
    /usr/sbin/httpd -DFOREGROUND
fi

if [ "$1" = "build" ];
then
    BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    # Run the interactive setup to add a new resource and setup the database.
    expect $BASEDIR/setup.tcl | col -b
    /usr/sbin/postfix start
    php-fpm
    rm -f /var/run/httpd/httpd.pid
    /usr/sbin/httpd -DFOREGROUND
fi

if [ "$1" = "start" ];
then
    /usr/sbin/postfix start
    php-fpm
    rm -f /var/run/httpd/httpd.pid
    /usr/sbin/httpd -DFOREGROUND
fi

