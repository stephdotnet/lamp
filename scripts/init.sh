#!/bin/bash

if [ ! -f .env ]; then
    cp .env.example .env
    echo ".env file created from .env.example"
else
    echo ".env file already exists, no action taken"
fi

if [ ! -f config/vhosts/default.conf ]; then
    cp templates/vhosts/default.conf config/vhosts/default.conf
    echo "default.conf file created"
else
    echo "default.conf file exists, no action taken"
fi

if [ ! -f config/php/php-local.ini ]; then
    mkdir -p config/php
    cp templates/php/php-local.ini config/php/php-local.ini
    echo "php-local.ini file created"
else
    echo "php-local.ini file exists, no action taken"
fi
