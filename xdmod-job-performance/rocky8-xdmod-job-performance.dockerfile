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

RUN dnf install -y https://github.com/ubccr/xdmod-supremm/releases/download/${XDMOD_SUPREMM_GITHUB_TAG}/${XDMOD_SUPREMM_RPM}

RUN dnf clean all
RUN rm -rf /var/cache/dnf

COPY assets/ /root/assets/
COPY bin/ /root/bin

WORKDIR /root

## Copy XDMoD configuration files and fix defaults
RUN sed -i 's/^#nojournal = true/nojournal = true/; s/^#noprealloc = true/noprealloc = true/' /etc/mongod.conf

## Start services, setup database and ingest SUPReMM data.
## note that we make sure to clean shutdown the database so the data are flushed properly
RUN ~/bin/services start && \
    mongod -f /etc/mongod.conf --fork && \
    ~/bin/importmongo.sh && \
    wget -nv https://raw.githubusercontent.com/${XDMOD_SUPREMM_GITHUB_USER}/xdmod-supremm/${XDMOD_SUPREMM_GITHUB_TAG}/tests/integration_tests/scripts/mongo_auth.mongojs && \
    mongo mongo_auth.mongojs && \
    rm -rf mongo_auth.mongojs && \
    mongod -f /etc/mongod.conf --shutdown && \
    mongod --fork -f /etc/mongod.conf --auth && \
    wget -nv https://raw.githubusercontent.com/${XDMOD_SUPREMM_GITHUB_USER}/xdmod-supremm/${XDMOD_SUPREMM_GITHUB_TAG}/tests/integration_tests/scripts/xdmod-setup.tcl && \
    expect xdmod-setup.tcl | col -b && \
    rm -rf xdmod-setup.tcl && \
    aggregate_supremm.sh && \
    acl-config && \
    mongod -f /etc/mongod.conf --shutdown && \
    ~/bin/services stop

# ~/bin/services-mongo also manages mongod, so mv it into place now.
RUN \mv ~/bin/services-mongo ~/bin/services

