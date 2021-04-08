# docker build -t misaelgomes/php80-fpm .
# docker run -d -p 3142:3142 misaelgomes/eg_apt_cacher_ng
# acessar localhost:3142 copiar proxy correto e colar abaixo em Acquire
# docker run -d -p 80:80 misaelgomes/tengine-php74

# From PHP 7.4 FPM based on Alpine Linux
FROM php:fpm


ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

RUN echo 'Acquire::http { Proxy "http://172.17.0.2:3142"; };' >> /etc/apt/apt.conf.d/01proxy
VOLUME ["/var/cache/apt-cacher-ng"]

#deps
RUN apt-get update -y
RUN apt-get install -y gcc make autoconf pkg-config software-properties-common build-essential 
RUN apt-get install -y tar zip unzip zlib1g-dev zlib1g libzip-dev libbz2-dev
RUN apt-get install -y optipng gifsicle jpegoptim libfreetype6-dev libjpeg62-turbo-dev libpng-dev
RUN apt-get install -y libgd3 libgd-dev libgd-tools webp libwebp-dev
RUN apt-get install -y ca-certificates openssl curl tzdata libxslt-dev
RUN apt-get install -y libc-dev libssl-dev git libonig-dev libmcrypt-dev
RUN apt-get install -y nano libxml2-dev libjemalloc-dev libjemalloc2 libcurl4-openssl-dev
RUN apt-get install -y libmagickwand-dev libmemcached-dev libmemcached-tools
RUN apt-get install -y sendmail mailutils cron wget

RUN git clone https://github.com/Imagick/imagick \
 && cd imagick \
 && git checkout master && git pull \
 && phpize && ./configure && make && make install \
 && cd .. && rm -Rf imagick 

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Hack to change uid of 'www-data' to 1000
#RUN usermod -u 1000 www-data

RUN pecl channel-update pecl.php.net
#RUN echo yes | pecl install imagick igbinary
RUN echo yes | pecl install igbinary
RUN echo yes | pecl install lzf
RUN echo yes | pecl install redis
RUN echo yes | pecl install xdebug
RUN echo yes | pecl install memcached

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install gd soap pdo_mysql opcache mbstring \
        mysqli gettext calendar calendar bz2 exif gettext \
        sockets sysvmsg sysvsem sysvshm xsl zip
RUN docker-php-ext-enable igbinary redis xdebug lzf imagick memcached

RUN echo "America/Sao_Paulo" > /etc/timezone
RUN date

RUN echo "sendmail_path=/usr/sbin/sendmail -t -i" >> /usr/local/etc/php/conf.d/sendmail.ini

RUN chown www-data:www-data -R /var/www/html

RUN apt-get remove -y gcc flex make bison build-essential pkg-config \
        g++ libtool automake autoconf
RUN apt-get remove --purge --auto-remove -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
        
RUN rm -fr /tmp/*

EXPOSE 9000