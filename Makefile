include .env
export

.PHONY: start
start:
	docker-compose up -d

.PHONY: certs
certs:
	sh certify.sh