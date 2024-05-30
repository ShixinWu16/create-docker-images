ARG BASE_IMAGE_PLATFORM
ARG XDMOD_IMAGE
FROM --platform=${BASE_IMAGE_PLATFORM} ${XDMOD_IMAGE}

LABEL description="The XDMoD OnDemand image used in our CI builds or local testing."

ARG XDMOD_ONDEMAND_GITHUB_TAG
ARG XDMOD_ONDEMAND_RPM
ARG XDMOD_GITHUB_TAG
ARG XDMOD_GITHUB_USER
ARG XDMOD_ONDEMAND_GITHUB_USER

ENV TERM=xterm-256color
ENV XDMOD_TEST_MODE=fresh_install

RUN dnf install -y https://github.com/ubccr/xdmod-ondemand/releases/download/${XDMOD_ONDEMAND_GITHUB_TAG}/${XDMOD_ONDEMAND_RPM}

RUN dnf clean all
RUN rm -rf /var/cache/dnf

RUN git clone --branch=${XDMOD_GITHUB_TAG} --depth=1 "https://github.com/${XDMOD_GITHUB_USER}/xdmod.git" /root/xdmod
RUN git clone --branch=${XDMOD_ONDEMAND_GITHUB_TAG} --depth=1 "https://github.com/${XDMOD_ONDEMAND_GITHUB_USER}/xdmod-ondemand.git" /root/xdmod-ondemand

# Once the `aaronweeden:use-new-docker-container` branch is merged into ${XDMOD_ONDEMAND_GITHUB_TAG}, this line will no longer be needed:
RUN wget -nv -O /root/xdmod-ondemand/tests/scripts/bootstrap.sh https://raw.githubusercontent.com/aaronweeden/xdmod-ondemand/use-new-docker-container/tests/scripts/bootstrap.sh

RUN ~/bin/services start && \
    /root/xdmod-ondemand/tests/scripts/bootstrap.sh && \
    ~/bin/services stop

RUN rm -rf /root/xdmod /root/xdmod-ondemand
