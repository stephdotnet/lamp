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
certs: ## Certifie les sites declares dans le vhost. [ARGS=--dry-run]
	docker compose exec \
		-e EMAIL_ADMIN=$(EMAIL_ADMIN) \
		-e CERTIFY_BASE_VIRTUAL_HOST=$(CERTIFY_BASE_VIRTUAL_HOST) \
		-e CERTBOT_EXTRA_ARGS="$(ARGS)" \
		webserver sh /etc/apache2/ssl/certify.sh

.PHONY: certs-renew
certs-renew:
	docker compose exec webserver certbot renew

# `service apache2 restart` tuerait PID 1 (apache2 tourne en foreground), donc le
# conteneur entier : exit 143 et coupure de service. `-k graceful` recharge le
# master en place. `-t` d'abord, car graceful renvoie 0 meme en echec et garde
# alors silencieusement l'ancienne config.
.PHONY: apache-restart
apache-restart: ## Recharge la config Apache sans couper les connexions
	docker compose exec webserver apachectl -t
	docker compose exec webserver apachectl -k graceful

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
