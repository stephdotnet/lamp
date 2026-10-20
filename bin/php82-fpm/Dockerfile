# Variante de bin/php82 : meme PHP, memes extensions, mais PHP-FPM + Apache en
# mpm_event au lieu de mod_php + prefork.
#
# Avec mod_php, Apache est force en prefork : un processus de ~35 Mo par
# connexion, et une websocket proxifiee vers Reverb garde le sien tant qu'elle
# reste ouverte (40 workers ~ 30 joueurs connectes). En mpm_event une connexion
# ne coute qu'un thread, et PHP tourne dans un pool FPM plafonne a part :
# la limite redevient le CPU.
#
# Apache et FPM tournent dans le meme conteneur (cf. start.sh) : le service
# `webserver`, ses montages, `docker compose exec webserver php ...` et certbot
# ne changent pas. Bascule et retour arriere : WEBSERVER_BUILD dans .env.
#
# Debian 12 "bookworm", meme raison que bin/php82 : pas de -buster (EOL).
FROM php:8.2-fpm-bookworm

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update --fix-missing && \
    apt-get upgrade -y && \
    apt-get --no-install-recommends install -y apt-utils && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get -y update && \
    apt-get -y --no-install-recommends install nano wget \
    dialog \
    libsqlite3-dev \
    libsqlite3-0 && \
    apt-get -y --no-install-recommends install default-mysql-client \
    zlib1g-dev \
    libzip-dev \
    libicu-dev && \
    apt-get -y --no-install-recommends install --fix-missing apt-utils \
    build-essential \
    git \
    curl \
    libonig-dev && \
    apt-get install -y iputils-ping && \
    apt-get install -y libgmp-dev && \
    apt-get install -y libxslt-dev && \
    apt-get -y --no-install-recommends install --fix-missing libcurl4 \
    libcurl4-openssl-dev \
    zip \
    openssl && \
    rm -rf /var/lib/apt/lists/* && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN pecl install redis-5.3.3 && \
    docker-php-ext-enable redis

RUN pecl install pcov && docker-php-ext-enable pcov

RUN apt-get update && \
    apt-get -y --no-install-recommends install --fix-missing libmagickwand-dev && \
    rm -rf /var/lib/apt/lists/*

ARG IMAGICK_COMMIT="661405abe21d12003207bc8eb0963fafc2c02ee4"

RUN cd /usr/local/src && \
    git clone https://github.com/Imagick/imagick && \
    cd imagick && \
    git checkout ${IMAGICK_COMMIT} && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf imagick && \
    docker-php-ext-enable imagick

RUN docker-php-ext-install pdo_mysql && \
    docker-php-ext-install pdo_sqlite && \
    docker-php-ext-install bcmath && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install curl && \
    docker-php-ext-install zip && \
    docker-php-ext-install -j$(nproc) intl && \
    docker-php-ext-install mbstring && \
    docker-php-ext-install gettext && \
    docker-php-ext-install calendar && \
    docker-php-ext-install exif && \
    docker-php-ext-install xsl && \
    docker-php-ext-install gmp && \
    docker-php-ext-install pcntl

RUN apt-get -y update && \
    apt-get --no-install-recommends install -y libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd

# Apache de Debian, en mpm_event. Memes modules que l'image php:apache de
# bin/php82, plus proxy_fcgi pour passer les .php a FPM. certbot comme avant.
RUN apt-get update && \
    apt-get install -y --no-install-recommends apache2 certbot python3-certbot-apache && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    (a2dismod -q mpm_prefork mpm_worker || true) && \
    a2enmod -q mpm_event proxy proxy_fcgi proxy_http proxy_wstunnel setenvif ssl rewrite headers expires deflate macro

# Ce que l'image php:apache posait dans docker-php.conf, avec FPM comme handler
COPY php-fpm.conf /etc/apache2/conf-available/lamp-php-fpm.conf
RUN a2enconf -q lamp-php-fpm

# Valeurs par defaut, aussi montees par docker-compose.yml pour les ajuster
# sans reconstruire l'image
COPY mpm_event.conf /etc/apache2/mods-available/mpm_event.conf
COPY pool.conf /usr/local/etc/php-fpm.d/zz-lamp.conf

RUN mkdir -p /etc/apache2/ssl

# DocumentRoot du vhost catch-all :80. Doit exister et rester vide : c'est ce
# qui empeche Apache de retomber sur /var/www/html et de servir toute
# l'arborescence de www/ en clair.
RUN mkdir -p /var/www/empty

COPY start.sh /usr/local/bin/lamp-start
RUN chmod +x /usr/local/bin/lamp-start

RUN rm -rf /usr/src/*

# php:fpm pose SIGQUIT, que bash en PID 1 ignorerait : start.sh attend SIGTERM
STOPSIGNAL SIGTERM
EXPOSE 80 443
CMD ["lamp-start"]
