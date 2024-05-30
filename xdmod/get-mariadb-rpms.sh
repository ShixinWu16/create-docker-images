#!/bin/bash

# Create the directory that will contain the specific MariaDB RPMs needed for v10.5.0
mkdir -p $(pwd)/xdmod/assets/mariadb-rpms

# hop in to the new directory and download the RPMS.
pushd $(pwd)/xdmod/assets/mariadb-rpms
wget https://dlm.mariadb.com/2269864/MariaDB/mariadb-10.3.35/yum/rhel8-amd64/rpms/MariaDB-client-10.3.35-1.el8.x86_64.rpm
wget https://dlm.mariadb.com/2269854/MariaDB/mariadb-10.3.35/yum/rhel8-amd64/rpms/MariaDB-common-10.3.35-1.el8.x86_64.rpm
wget https://dlm.mariadb.com/2269861/MariaDB/mariadb-10.3.35/yum/rhel8-amd64/rpms/MariaDB-server-10.3.35-1.el8.x86_64.rpm
wget https://dlm.mariadb.com/2269859/MariaDB/mariadb-10.3.35/yum/rhel8-amd64/rpms/MariaDB-shared-10.3.35-1.el8.x86_64.rpm

popd
