FROM php:7.2.14-apache


ARG PHALCON_VERSION=3.4.2
ARG PHALCON_EXT_PATH=php7/64bits

RUN set -xe && \
        # Compile Phalcon
        curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
        tar xzf ${PWD}/v${PHALCON_VERSION}.tar.gz && \
        docker-php-ext-install -j $(getconf _NPROCESSORS_ONLN) ${PWD}/cphalcon-${PHALCON_VERSION}/build/${PHALCON_EXT_PATH} && \
        # Remove all temp files
        rm -r \
            ${PWD}/v${PHALCON_VERSION}.tar.gz \
            ${PWD}/cphalcon-${PHALCON_VERSION}

RUN docker-php-ext-enable phalcon 

ENV ACCEPT_EULA=Y

# Update gnupg
RUN apt-get update && apt-get install -my wget gnupg

# Microsoft SQL Server Prerequisites
RUN apt-get update \
   && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
   && curl https://packages.microsoft.com/config/debian/8/prod.list \
       > /etc/apt/sources.list.d/mssql-release.list \
   && apt-get install -y --no-install-recommends \
       locales \
       apt-transport-https \
   && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
   && locale-gen \
   && apt-get update \
   && apt-get -y --no-install-recommends install \
       msodbcsql \
       unixodbc-dev

RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
	&& docker-php-ext-install iconv \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install gd

RUN apt-get install -y libpng-dev libzip-dev zip

RUN docker-php-ext-configure zip --with-libzip

RUN docker-php-ext-install zip mbstring pdo pdo_mysql \
   && pecl install sqlsrv pdo_sqlsrv xdebug \
   && docker-php-ext-enable sqlsrv pdo_sqlsrv xdebug gd zip


ADD www /var/www/html
ADD apache-config.conf /etc/apache2/sites-available/000-default.conf
ADD apache2.conf /etc/apache2/apache2.conf

RUN a2enmod rewrite


RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apt-get upgrade -y

#RUN wget http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u9_amd64.deb
#RUN dpkg -i libssl1.0.0_1.0.1t-1+deb8u9_amd64.deb
