This project stands as basic docker lamp that fit my needs. Its purpose is to be production ready (for small projects)

It's shipped with
- Php8.1 / Apache
- Mysql8
- Redis
- Node

It also comes with a Makefile, and a set of useful commands (list available by running `make help`)

## Setup

### 1. Init

- You can run `make init`

Or

- Create `.env` from `.env.example` file
- Create the default vhost in `config/vhosts/default.conf` (you can use the template in `templates/vhosts/default.conf`)

You'll have then to configure you first vhost **before running the certification**

### 2. Build and run the containers


- You can run `make up` (Linux / Mac OS)

Or

- Run `docker-compose up -d`

### 3. Configure vhost

- Add your virtual hosts rules in `config/vhosts/default.conf`. You just need to define your non ssl rules. 
  - The certification script will create a `default-le-ssl.conf` file based on the domains defined in the `default.conf` file
  - You can change the base file in your `.env` by changing the value for `CERTIFY_BASE_VIRTUAL_HOST` 

### 4. Run certification (optional for local development)
- Run `make certs`
