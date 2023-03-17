This project stands as basic docker lamp that fit my needs. It's shipped with 
- Php8.1 / Apache (based on php-81-apache-buster)
- Mysql8
- Redis

## Installation
- Create `.env` from `.env.example` file
- Add your virtual hosts (non https) as `default.conf` (or other but specify it in your `.env` in  `CERTIFY_BASE_VIRTUAL_HOST`) 

## Setup

### Linux / Mac OS
- `make up`

### Windows
- `docker-compose up -d`

## Certification
- run `make certs`

## Credits