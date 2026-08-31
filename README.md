This project stands as basic docker lamp that fit my needs. Its purpose is to be production ready (for small projects)

It's shipped with
- Php8.2 / Apache
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

## Connecting to the database

MySQL and Redis are published on `127.0.0.1` only (see `docker-compose.yml`).
They are **never** reachable from the network, on a local machine or on a
server. Everything below relies on that.

### From another container

Use the compose service name as the host — this is what the apps' `.env` should
contain:

```
DB_HOST=database
DB_PORT=3306
REDIS_HOST=redis
REDIS_PORT=6379
```

Credentials come from the root `.env` (`MYSQL_USER`, `MYSQL_PASSWORD`,
`MYSQL_DATABASE`, `REDIS_PASSWORD`).

### From the host machine

MySQL is exposed on the loopback interface, on the port set by
`HOST_MACHINE_MYSQL_PORT`:

```
Host      127.0.0.1
Port      3306          # HOST_MACHINE_MYSQL_PORT
User      root          # MYSQL_USER for a non-privileged account
Password  see .env
```

Any client works: TablePlus, DBeaver, Beekeeper Studio, HeidiSQL, the database
panel of PhpStorm...

For a shell instead:

```bash
make mysql              # bash inside the database container
mysql -u root -p        # then, inside it
```

### With Adminer

A web UI is available as an optional container, bound to `127.0.0.1` as well:

```bash
docker compose up -d adminer
```

Then open <http://127.0.0.1:8080> (`HOST_MACHINE_ADMINER_PORT`). The server
field is pre-filled with `database`.

> Do **not** put Adminer behind a vhost. Serving it over HTTP exposes a full
> database admin panel to the whole internet, and Adminer has a track record of
> CVEs. The container above keeps the same UI with nothing exposed.

### From a remote server

Nothing is open on the server: connect through an SSH tunnel. Pick **one** of
the two targets below depending on the tool you want to use — they are
alternatives, not successive steps.

**Using the Adminer web UI** — the container must be running on the server
(`docker compose up -d adminer`, once):

```bash
make adminer VPS=user@your-server
```

Leave it running, then open <http://127.0.0.1:8080> in your browser.

**Using a SQL client** (TablePlus, DBeaver, Beekeeper Studio, the `mysql` CLI…):

```bash
make db-tunnel VPS=user@your-server
```

Leave it running, then point your client at `127.0.0.1:3307`, with the
credentials from the server's `.env`. Local port 3307 is used so it does not
collide with a MySQL already running on your machine.

Both run in the foreground and `Ctrl+C` closes the tunnel. Running both at once
is fine but only useful if you actually use both tools.

To make it permanent, declare the forwards in your `~/.ssh/config` instead:

```
Host myvps
    HostName <ip>
    User <user>
    LocalForward 8080 127.0.0.1:8080
    LocalForward 3307 127.0.0.1:3306
```

A plain `ssh myvps` then opens both, and any client can point at
`127.0.0.1:3307`.
