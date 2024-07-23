#!/bin/bash

set -e
set -o pipefail

tail

if [ "$1" = "build" ]
then
  dnf install -y ~/rpmbuild/RPMS/noarch/xdmod-supremm*.rpm
  ~/bin/importmongo.sh
  wget -nv https://raw.githubusercontent.com/ubccr/xdmod-supremm/xdmod11.0/tests/integration/scripts/mongo_auth.mongojs
  mongo mongodb://root:admin@mongodb:27017 mongo_auth.mongojs
  rm -rf mongo_auth.mongojs
  # wget -nv https://github.com/ubccr/xdmod-supremm/blob/xdmod11.0/tests/integration/scripts/xdmod-setup.tcl && \
  # wget -nv https://raw.githubusercontent.com/ubccr/xdmod-supremm/xdmod11.0/tests/integration/scripts/xdmod-setup.tcl && \
  wget -nv https://raw.githubusercontent.com/ShixinWu16/xdmod-supremm/dockersplit/tests/integration/scripts/xdmod-setup.tcl
  expect xdmod-setup.tcl | col -b || true
  rm -rf xdmod-setup.tcl
  rm -rf /root/xdmod-supremm /root/xdmod
  acl-config
  /usr/sbin/postfix start
  php-fpm
  rm -f /var/run/httpd/httpd.pid
  /usr/sbin/httpd -DFOREGROUND
fi

if [ "$1" = "testbuild" ]
then
  dnf install -y ~/rpmbuild/RPMS/noarch/xdmod-supremm*.rpm
  ~/bin/importmongo.sh
  wget -nv https://raw.githubusercontent.com/ubccr/xdmod-supremm/xdmod11.0/tests/integration/scripts/mongo_auth.mongojs
  mongo mongodb://root:admin@mongodb:27017 mongo_auth.mongojs
  rm -rf mongo_auth.mongojs
  # wget -nv https://github.com/ubccr/xdmod-supremm/blob/xdmod11.0/tests/integration/scripts/xdmod-setup.tcl && \
  # wget -nv https://raw.githubusercontent.com/ubccr/xdmod-supremm/xdmod11.0/tests/integration/scripts/xdmod-setup.tcl && \
  wget -nv https://raw.githubusercontent.com/ShixinWu16/xdmod-supremm/dockersplit/tests/integration/scripts/xdmod-setup.tcl
  expect xdmod-setup.tcl | col -b || true
  rm -rf xdmod-setup.tcl
  aggregate_supremm.sh
  rm -rf /root/xdmod-supremm /root/xdmod
  acl-config
  /usr/sbin/postfix start
  php-fpm
  rm -f /var/run/httpd/httpd.pid
  /usr/sbin/httpd -DFOREGROUND
fi


if [ "$1" = "start" ]
then
  /usr/sbin/postfix start
  php-fpm
  rm -f /var/run/httpd/httpd.pid
  /usr/sbin/httpd -DFOREGROUND
fi

exec "$@"
