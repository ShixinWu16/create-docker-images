#!/bin/bash
# Bootstrap script that either sets up a fresh XDMoD test instance or upgrades
# an existing one.  This code is only designed to work inside the XDMoD test
# docker instances. However, since it is designed to test a real install, the
# set of commands that are run would work on a real production system.
function copy_template_httpd_conf {
  cp /usr/share/xdmod/templates/apache.conf /etc/httpd/conf.d/xdmod.conf
}

if [ -z $XDMOD_REALMS ]; then
  export XDMOD_REALMS=jobs,storage,cloud,resourcespecifications
fi

set -e
set -o pipefail
user=root
pass=''

if [ "$1" = "build" ]
then
  BASEDIR=/root/xdmod/tests/ci
  REPODIR=`realpath $BASEDIR/../../`
  user=root
  pass=''
  tableexist=$(mysql -u${user} -p${pass} --host mariadb -e "SHOW DATABASES LIKE 'modw'")

  if [[ -z "$tableexist" ]]; then
#    dnf install -y ~/rpmbuild/RPMS/*/*.rpm
    copy_template_httpd_conf
    mysql -h mariadb -e "CREATE USER 'root'@'xdmod' IDENTIFIED BY '';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'xdmod' WITH GRANT OPTION;
    FLUSH PRIVILEGES;"

    # TODO: Replace diff files with hard fixes
    # Modify integration sso tests to work with cloud realm
    if [ "$XDMOD_REALMS" = "cloud" ]; then
      if ! patch --dry-run -Rfsup1 --directory=$REPODIR < $BASEDIR/diff/SSOLoginTest.php.diff >/dev/null; then
        # -- Fix users searched in SSO test
        patch -up1 --directory=$REPODIR < $BASEDIR/diff/SSOLoginTest.php.diff
      fi
    else
      if patch --dry-run -Rfsup1 --directory=$REPODIR < $BASEDIR/diff/SSOLoginTest.php.diff >/dev/null; then
          # -- Reverse previous patch
          patch -R -up1 --directory=$REPODIR < $BASEDIR/diff/SSOLoginTest.php.diff
      fi
    fi

    expect $BASEDIR/scripts/xdmod-setup-start.tcl | col -b

    if [[ "$XDMOD_REALMS" == *"jobs"* ]]; then
      expect $BASEDIR/scripts/xdmod-setup-jobs.tcl | col -b
    fi
    if [[ "$XDMOD_REALMS" == *"storage"* ]]; then
      expect $BASEDIR/scripts/xdmod-setup-storage.tcl | col -b
    fi
    if [[  "$XDMOD_REALMS" == *"cloud"* ]]; then
      expect $BASEDIR/scripts/xdmod-setup-cloud.tcl | col -b
    fi
    expect $BASEDIR/scripts/xdmod-setup-finish.tcl | col -b
  fi

  sudo -u xdmod xdmod-ingestor

  dnf clean all
  rm -rf /var/cache/yum /var/cache/dnf
  rm -rf /root/xdmod /root/rpmbuild
  rm -f /var/run/httpd/httpd.pid
  /usr/sbin/postfix start
  php-fpm
  /usr/sbin/httpd -DFOREGROUND
fi

if [ "$1" = "testbuild" ]
then
  git clone -b xdmod11.0 --depth=1 https://github.com/ShixinWu16/xdmod /root/xdmod
  BASEDIR=/root/xdmod/tests/ci
  REPODIR=`realpath $BASEDIR/../../`
  REF_SOURCE=`realpath $BASEDIR/../artifacts/xdmod/referencedata`
  REF_DIR=/var/tmp/referencedata
  function set_resource_spec_end_times {
    # Adding end time for each resource in resourcespecs.json. This is to get consistant results for
    # the raw data regression tests. The jq command does not do well with overwriting the existing file
    # so writing to a temp file and then renaming seems to be the best way to go.
    cat /etc/xdmod/resource_specs.json | jq '[.[] | .["end_date"] += "2020-01-01"]' > /etc/xdmod/resource_specs2.json
    jq . /etc/xdmod/resource_specs2.json > /etc/xdmod/resource_specs.json
    rm -f /etc/xdmod/resource_specs2.json
    }
  cp -r $REF_SOURCE /var/tmp/
  # PYTHON_SCIPY=python3-scipy
  if [ `rpm -E %{rhel}` = 7 ]; then
    PYTHON_SCIPY=python36-scipy
  fi

  # Install python dependencies for the image hash comparison algorithm
  yum install -y python3 python3-six python3-numpy python3-pillow ${PYTHON_SCIPY}
  pip3 install imagehash==4.2.1
  cp $REPODIR/tests/ci/scripts/imagehash /root/bin

  # ensure php error logging is set to E_ALL (recommended setting for development)
  sed -i 's/^error_reporting = .*/error_reporting = E_ALL/' /etc/php.ini

  # ensure php command-line errors are logged to a file
  sed -i 's/^;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/' /etc/php.ini
  xdmod-import-csv -t hierarchy -i $REF_DIR/hierarchy.csv
  xdmod-import-csv -t group-to-hierarchy -i $REF_DIR/group-to-hierarchy.csv

  if [[ "$XDMOD_REALMS" == *"jobs"* ]];
  then
    for resource in $REF_DIR/*.log; do
      sudo -u xdmod xdmod-shredder -r `basename $resource .log` -f slurm -i $resource;
    done
  fi

  set_resource_spec_end_times
  sudo -u xdmod xdmod-ingestor

  if [[ "$XDMOD_REALMS" == *"cloud"* ]];
  then
    last_modified_start_date=$(date +'%F %T')
    sudo -u xdmod xdmod-shredder -r openstack -d $REF_DIR/openstack -f openstack
    sudo -u xdmod xdmod-shredder -r nutsetters -d $REF_DIR/nutsetters -f openstack

    sudo -u xdmod xdmod-import-csv -t cloud-project-to-pi -i $REF_DIR/cloud-pi-test.csv
    sudo -u xdmod xdmod-shredder -r openstack -d $REF_DIR/openstack_error_sessions -f openstack
    sudo -u xdmod xdmod-ingestor --datatype openstack
    sudo -u xdmod xdmod-ingestor --aggregate=cloud --last-modified-start-date "$last_modified_start_date"
  fi

  if [[ "$XDMOD_REALMS" == *"storage"* ]];
  then
    for storage_dir in $REF_DIR/storage/*; do
        sudo -u xdmod xdmod-shredder -f storage -r $(basename $storage_dir) -d $storage_dir
    done
    last_modified_start_date=$(date +'%F %T')
    sudo -u xdmod xdmod-ingestor --datatype storage
    sudo -u xdmod xdmod-ingestor --aggregate=storage --last-modified-start-date "$last_modified_start_date"
  fi

  sudo -u xdmod xdmod-import-csv -t names -i $REF_DIR/names.csv
  sudo -u xdmod xdmod-ingestor
  php $BASEDIR/scripts/create_xdmod_users.php
  dnf clean all
  rm -rf /var/cache/yum /var/cache/dnf
  rm -rf /root/xdmod /root/rpmbuild
  rm -f /var/run/httpd/httpd.pid
  /usr/sbin/postfix start
  php-fpm
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