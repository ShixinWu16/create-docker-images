FROM mariadb:10.3.35

ENV HOSTNAME=mariadb

ENV MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1
ENV MYSQL_DATABASE=shared-database

RUN cp -r /var/lib/mysql/ /var/lib/db/

COPY ./my.cnf /etc/mysql/my.cnf

EXPOSE 3306

CMD ["mysqld", "--datadir", "/var/lib/db"]
