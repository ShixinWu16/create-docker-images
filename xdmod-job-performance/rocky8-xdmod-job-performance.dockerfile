ARG BASE_IMAGE_PLATFORM
ARG XDMOD_IMAGE
FROM --platform=${BASE_IMAGE_PLATFORM} ${XDMOD_IMAGE}

LABEL description="The XDMoD Job Performance image used in our CI builds or local testing."

ARG BASE_IMAGE_ARCHITECTURE
ARG XDMOD_SUPREMM_GITHUB_TAG
ARG XDMOD_SUPREMM_RPM
ARG XDMOD_SUPREMM_GITHUB_USER

ENV TERM=xterm-256color
ENV XDMOD_TEST_MODE=fresh_install

COPY assets/mongodb-org-${BASE_IMAGE_ARCHITECTURE}.repo /etc/yum.repos.d

# RUN dnf install -y https://github.com/ubccr/xdmod-supremm/releases/download/${XDMOD_SUPREMM_GITHUB_TAG}/${XDMOD_SUPREMM_RPM}

COPY assets/ /root/assets/
COPY bin/ /root/bin

WORKDIR /root

RUN dnf install -y mongodb-org && \
    sed -i 's/^#nojournal = true/nojournal = true/; s/^#noprealloc = true/noprealloc = true/' /etc/mongod.conf && \
    git clone -b dockersplit --depth=1 https://github.com/ShixinWu16/xdmod-supremm.git /root/xdmod-supremm && \
    ln -s ~/xdmod-supremm/ ~/xdmod/open_xdmod/modules/supremm && \
    cd xdmod-supremm && \
    composer install --no-dev --working-dir=/root/xdmod-supremm && \
    cd xdmod && \
    composer install && \
    /root/bin/buildrpm xdmod supremm && \
    dnf install -y ~/rpmbuild/RPMS/noarch/xdmod-supremm*.rpm && \
    dnf clean all && \
    rm -rf /var/cache/dnf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

WORKDIR /root