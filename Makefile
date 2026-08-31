include .env
export

.PHONY: help
help:
	make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);print A[1]}' | sort

.PHONY: init
init:
	scripts/init.sh

.PHONY: up
up:
	make start

.PHONY: up
up-build:
	make start-build

.PHONY: start
start:
	docker compose up -d

.PHONY: start-build
start-build:
	docker compose up --build -d

.PHONY: down
down:
	make stop

.PHONY: stop
stop:
	docker compose down

.PHONY: build
build:
	docker compose build

.PHONY: php
php:
	docker compose exec -u 1000 webserver bash

.PHONY: mysql
mysql:
	docker compose exec database bash

.PHONY: php
php-www:
	docker compose exec -u www-data webserver bash

.PHONY: php-su
php-su:
	docker compose exec webserver bash

.PHONY: node
node: ## [CMD=]
	docker compose run node sh -c "${CMD}"

node-cli: ## [CMD=]
	docker compose exec -it node bash

.PHONY: certs
certs:
	docker compose exec -e EMAIL_ADMIN=$(EMAIL_ADMIN) webserver sh /etc/apache2/ssl/certify.sh

.PHONY: certs-renew
certs-renew:
	docker compose exec webserver certbot renew

.PHONY: apache-restart
apache-restart:
	docker compose exec webserver service apache2 restart

# Tunnels SSH vers les services bindes sur 127.0.0.1 du VPS.
# Rien n'est expose sur Internet : c'est le tunnel qui donne l'acces.
.PHONY: adminer
adminer: ## Adminer du VPS sur http://127.0.0.1:$(HOST_MACHINE_ADMINER_PORT). Usage : make adminer VPS=user@ip
	@test -n "$(VPS)" || { echo "Usage: make adminer VPS=user@ip"; exit 1; }
	@echo "Adminer -> http://127.0.0.1:$(HOST_MACHINE_ADMINER_PORT)  (Ctrl+C pour fermer)"
	ssh -N -L $(HOST_MACHINE_ADMINER_PORT):127.0.0.1:$(HOST_MACHINE_ADMINER_PORT) $(VPS)

.PHONY: db-tunnel
db-tunnel: ## MySQL du VPS sur 127.0.0.1:3307. Usage : make db-tunnel VPS=user@ip
	@test -n "$(VPS)" || { echo "Usage: make db-tunnel VPS=user@ip"; exit 1; }
	@echo "MySQL -> 127.0.0.1:3307  (Ctrl+C pour fermer)"
	ssh -N -L 3307:127.0.0.1:$(HOST_MACHINE_MYSQL_PORT) $(VPS)

.PHONY: mailhog
mailhog:
	docker run -d -p 1025:1025 -p 8025:8025 mailhog/mailhog
