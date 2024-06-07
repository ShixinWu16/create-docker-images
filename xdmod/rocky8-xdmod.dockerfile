ARG BASE_IMAGE_PLATFORM
ARG XDMOD_BASE_IMAGE
FROM --platform=${BASE_IMAGE_PLATFORM} ${XDMOD_BASE_IMAGE}

LABEL description="The main XDMoD image used in our CI builds or local testing."

ARG COMPOSER
ARG COMPOSER_ALLOW_SUPERUSER
ARG XDMOD_GITHUB_TAG
ARG XDMOD_GITHUB_USER

ENV TERM=xterm-256color
ENV XDMOD_REALMS=jobs,storage,cloud,resourcespecifications
ENV XDMOD_TEST_MODE=fresh_install

# We have some caches that we put in place for automated builds.
# This will copy them into place if they exist
COPY assets /tmp/assets
COPY bin /root/bin

COPY assets/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf

# Copy mariadb
#RUN mv /root/bin/mariadb-wait-ready /usr/libexec/

# Generate SSL Key
RUN openssl genrsa -rand /proc/cpuinfo:/proc/filesystems:/proc/interrupts:/proc/ioports:/proc/uptime 2048 > /etc/pki/tls/private/localhost.key

# Generate SSL Certificate
RUN /usr/bin/openssl req -new -key /etc/pki/tls/private/localhost.key -x509 -sha256 -days 365 -set_serial $RANDOM -extensions v3_req -out /etc/pki/tls/certs/localhost.crt -subj "/C=XX/L=Default City/O=Default Company Ltd"

#RUN mkdir -p /var/log/mariadb && chown -R :root /var/log/mariadb
#RUN mkdir -p /run/mariadb && chown -R :root /run/mariadb

# RUN mysql_install_db --user=root --basedir=/usr --datadir=/var/lib/mysql

WORKDIR /root
RUN mkdir -p /root/rpmbuild/RPMS/noarch
# RUN git clone --branch=${XDMOD_GITHUB_TAG} --depth=1 "https://github.com/${XDMOD_GITHUB_USER}/xdmod.git" /root/xdmod
COPY xdmod/ /root/xdmod

WORKDIR /root/xdmod
RUN composer install
RUN /root/bin/buildrpm xdmod

# WORKDIR /root

# Once the `ryanrath:xdmod11-php8` branch is merged into ${XDMOD_GITHUB_TAG}, this line will no longer be needed:
# RUN sed -i 's|rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql||g' /root/xdmod/tests/ci/bootstrap.sh

RUN chmod +x /root/xdmod/tests/ci/bootstrap.sh
CMD  /root/xdmod/tests/ci/bootstrap.sh ; tail -f /dev/null
# RUN /root/xdmod/tests/ci/bootstrap.sh

# RUN dnf clean all
# RUN rm -rf /var/cache/yum /root/xdmod /root/rpmbuild /var/cache/dnf

# WORKDIR /

