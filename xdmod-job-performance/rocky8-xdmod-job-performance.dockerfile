ARG BASE_IMAGE_PLATFORM
ARG XDMOD_IMAGE
FROM --platform=${BASE_IMAGE_PLATFORM} tools-int-01.ccr.xdmod.org/xdmod:x86_64-rockylinux8.5-v11.0-1.0-01-populated2

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

COPY xdmod-supremm/ /root/xdmod-supremm

WORKDIR /root/xdmod-supremm

RUN composer install

WORKDIR /root/xdmod

RUN composer install

RUN ln -s ~/xdmod-supremm/ ~/xdmod/open_xdmod/modules/supremm

RUN /root/bin/buildrpm supremm

RUN dnf install -y ~/rpmbuild/RPMS/noarch/xdmod-supremm*.rpm

RUN chmod +x ~/bin/importmongo.sh

#RUN rm -rf xdmod

#RUN rm -rf xdmod-supremm

CMD ~/bin/services start && \
    # mongod -f /etc/mongod.conf --fork && \
    # ~/bin/importmongo.sh && \
    wget -nv https://raw.githubusercontent.com/ubccr/xdmod-supremm/xdmod11.0/tests/integration/scripts/mongo_auth.mongojs && \
    mongo mongodb://root:admin@mongodb:27017 mongo_auth.mongojs && \
    rm -rf mongo_auth.mongojs && \
    # mongod -f /etc/mongod.conf --shutdown && \
    # mongod --fork -f /etc/mongod.conf --auth && \
    # wget -nv https://github.com/ubccr/xdmod-supremm/blob/xdmod11.0/tests/integration/scripts/xdmod-setup.tcl && \
    # wget -nv https://raw.githubusercontent.com/ubccr/xdmod-supremm/xdmod11.0/tests/integration/scripts/xdmod-setup.tcl && \
    expect xdmod-setup.tcl | col -b || true && \
    # rm -rf xdmod-setup.tcl && \
    aggregate_supremm.sh  && \
    acl-config \
    # mongod -f /etc/mongod.conf --shutdown && \
    ; tail -f /dev/null

WORKDIR /root