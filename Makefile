include .env
export

.PHONY: help
help:
	make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);print A[1]}' | sort

.PHONY: init
init:
	scripts/init.sh

.PHONY: start
start:
	docker-compose up -d

.PHONY: build
build:
	docker-compose build

.PHONY: php
php:
	docker-compose exec webserver bash

.PHONY: node
node: ## [CMD=]
	docker-compose run node sh -c ${CMD}

.PHONY: restart-apache
restart-apache:
	docker-compose exec webserver service apache2 restart

.PHONY: certs
certs:
	docker-compose exec -e EMAIL_ADMIN=$(EMAIL_ADMIN) webserver sh /etc/apache2/ssl/certify.sh

.PHONY: certs-renew
certs-renew:
	docker-compose exec webserver certbot renew --dry-run