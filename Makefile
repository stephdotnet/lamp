include .env
export

.PHONY: start
start:
	docker-compose up -d

.PHONY: certs
certs:
	docker-compose exec webserver -it sh certify.sh