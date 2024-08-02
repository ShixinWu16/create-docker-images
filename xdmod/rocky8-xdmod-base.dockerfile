ARG BASE_IMAGE_PLATFORM
ARG BASE_IMAGE
FROM --platform=${BASE_IMAGE_PLATFORM} ${BASE_IMAGE}

LABEL description="Base image containing XDMoD required software."

# Install the software requirements for installing xdmod
RUN dnf makecache && \
    dnf -y install epel-release && \
    dnf module -y enable nodejs:16 && \
    dnf module -y enable php:7.4 && \
    dnf -y install \
        rpm-build \
        httpd \
        sudo \
        wget \
        vim \
        git \
        expect \
        openssl \
        rsync \
        cronie \
        logrotate \
        ghostscript \
        jq \
        gnu-free-sans-fonts \
        chromium-headless \
        postfix \
        python39 \
        procps-ng \
        libzip-devel \
        nodejs \
        make && \
    dnf -y install \
        php \
        php-common \
        php-opcache \
        php-cli \
        php-gd \
        php-curl \
        php-pear \
        php-zip \
        php-gmp \
        php-pdo \
        php-xml \
        php-mbstring \
        php-mysqlnd \
        php-pecl-apcu \
        php-pecl-json \
        php-devel \
        openssl-devel && \
    yes '' | pecl install mongodb && \
    echo "extension=mongodb.so" > /etc/php.d/40-mongodb.ini && \
    dnf remove -y php-devel && \
    mkdir -p /run/php-fpm && \
    sed -i 's/.*date.timezone[[:space:]]*=.*/date.timezone = UTC/' /etc/php.ini && \
    sed -i 's/.*memory_limit[[:space:]]*=.*/memory_limit = -1/' /etc/php.ini && \
    rm /etc/localtime && ln -s /usr/share/zoneinfo/UTC /etc/localtime && \
    sed -ie 's/inet_interfaces = localhost/#inet_interfaces = localhost/' /etc/postfix/main.cf  && \
    sed -ie 's/smtp      inet  n       -       n       -       -       smtpd/#smtp      inet  n       -       n       -       -       smtpd/' /etc/postfix/master.cf && \
    sed -ie 's/smtp      unix  -       -       n       -       -       smtp/smtp      unix  -       -       n       -       -       local/' /etc/postfix/master.cf && \
    sed -ie 's/relay     unix  -       -       n       -       -       smtp/relay     unix  -       -       n       -       -       local/' /etc/postfix/master.cf && \
    echo '/.*/ root' >> /etc/postfix/virtual && \
    postmap /etc/postfix/virtual && \
    echo 'virtual_alias_maps = regexp:/etc/postfix/virtual' >> /etc/postfix/main.cf && \
    newaliases && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)" && \
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")" && \
    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then echo 'ERROR: Invalid composer signature'; exit 1; fi && \
    php composer-setup.php --install-dir=/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    dnf clean all && rm -rf /var/cache/dnf

WORKDIR /root
