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
# ENV XDMOD_TEST_MODE=fresh_install

COPY assets /tmp/assets
COPY bin /root/bin
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN openssl genrsa -rand /proc/cpuinfo:/proc/filesystems:/proc/interrupts:/proc/ioports:/proc/uptime 2048 > /etc/pki/tls/private/localhost.key && \
    openssl req -new -key /etc/pki/tls/private/localhost.key -x509 -sha256 -days 365 -set_serial $RANDOM -extensions v3_req -out /etc/pki/tls/certs/localhost.crt -subj "/C=XX/L=Default City/O=Default Company Ltd" && \
    rm -rf /tmp/assets/mariadb-rpms /tmp/assets/mariadb-server.cnf /tmp/assets/mysql-server.cnf && \
    rm -rf /root/bin/imagehash /root/bin/mariadb-wait-ready && \
    mkdir -p /root/rpmbuild/RPMS/noarch && \
    git clone --branch=file_updates_for_refactoring_docker_files --depth=1 "https://github.com/ShixinWu16/xdmod.git" /root/xdmod && \
    cd /root/xdmod && \
    composer install && \
    /root/bin/buildrpm xdmod && \
    cd /root && \
    dnf install -y mysql && \
    dnf install -y /root/rpmbuild/RPMS/*/*.rpm && \
    dnf clean all && rm -rf /var/cache/dnf

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

WORKDIR /root
