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

RUN dnf install -y mongodb-org

# RUN dnf install -y https://github.com/ubccr/xdmod-supremm/releases/download/${XDMOD_SUPREMM_GITHUB_TAG}/${XDMOD_SUPREMM_RPM}

RUN dnf clean all
RUN rm -rf /var/cache/dnf

COPY assets/ /root/assets/
COPY bin/ /root/bin

WORKDIR /root

## Copy XDMoD configuration files and fix defaults
RUN sed -i 's/^#nojournal = true/nojournal = true/; s/^#noprealloc = true/noprealloc = true/' /etc/mongod.conf

## Start services, setup database and ingest SUPReMM data.
## note that we make sure to clean shutdown the database so the data are flushed properly

# RUN git clone -b xdmod11.0 https://github.com/ubccr/xdmod.git
# RUN git clone -b xdmod11.0 https://github.com/ubccr/xdmod-supremm.git

RUN git clone -b dockersplit --depth=1 https://github.com/ShixinWu16/xdmod-supremm.git /root/xdmod-supremm && \
    git clone -b xdmod11.0 --depth=1 https://github.com/ShixinWu16/xdmod /root/xdmod && \
    ln -s ~/xdmod-supremm/ ~/xdmod/open_xdmod/modules/supremm

WORKDIR /root/xdmod-supremm

RUN composer install

WORKDIR /root/xdmod

RUN composer install


RUN /root/bin/buildrpm xdmod supremm

RUN dnf install -y ~/rpmbuild/RPMS/noarch/xdmod-supremm*.rpm

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

WORKDIR /root