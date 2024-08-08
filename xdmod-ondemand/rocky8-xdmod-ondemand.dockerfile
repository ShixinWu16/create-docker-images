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

COPY entrypoint.sh /root/xdmod-ondemand/tests/scripts/entrypoint.sh

#RUN dnf install -y https://github.com/ubccr/xdmod-ondemand/releases/download/${XDMOD_ONDEMAND_GITHUB_TAG}/${XDMOD_ONDEMAND_RPM}
#RUN git clone --branch=${XDMOD_GITHUB_TAG} --depth=1 "https://github.com/${XDMOD_GITHUB_USER}/xdmod.git" /root/xdmod
#RUN git clone --branch=${XDMOD_ONDEMAND_GITHUB_TAG} --depth=1 "https://github.com/${XDMOD_ONDEMAND_GITHUB_USER}/xdmod-ondemand.git" /root/xdmod-ondemand

#RUN git clone -b xdmod11.0 https://github.com/ubccr/xdmod.git /root/xdmod
# RUN git clone https://github.com/ubccr/xdmod-ondemand.git /root/xdmod-ondemand
RUN git clone -b main --depth=1 https://github.com/ShixinWu16/xdmod-ondemand /root/xdmod-ondemand && \
    ln -s /root/xdmod-ondemand/ /root/xdmod/open_xdmod/modules/ondemand && \
    cd xdmod && \
    composer install && \
    cd xdmod-ondemand && \
    composer install && \
    dnf clean all && \
    RUN /root/bin/buildrpm xdmod ondemand && \
    RUN dnf install -y ~/rpmbuild/RPMS/noarch/xdmod*.rpm && \
    rm /var/cache/dnf

ENTRYPOINT [ "/root/xdmod-ondemand/tests/scripts/entrypoint.sh" ]

WORKDIR /root