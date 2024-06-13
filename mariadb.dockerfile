FROM mariadb:11.4.2

ENV HOSTNAME=mariadb

ENV MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1

COPY ./50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

EXPOSE 3306
