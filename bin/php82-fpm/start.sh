#!/bin/bash
# PID 1 du conteneur : PHP-FPM et Apache, cote a cote. Si l'un s'arrete, l'autre
# est arrete aussi et le conteneur sort en erreur : `restart: always` relance
# les deux, plutot qu'un Apache qui repondrait 503 sans FPM derriere.
#
# Apache est lance comme apache2-foreground de l'image php:apache, pour que
# `apachectl -k graceful` (make apache-restart) retrouve ses envvars et son PID.

: "${APACHE_CONFDIR:=/etc/apache2}"
. "$APACHE_CONFDIR/envvars"
mkdir -p "$APACHE_RUN_DIR" "$APACHE_LOCK_DIR" "$APACHE_LOG_DIR"
rm -f "$APACHE_PID_FILE"

trap 'kill -TERM $(jobs -p) 2>/dev/null; wait; exit 0' TERM INT

php-fpm --nodaemonize &
apache2 -DFOREGROUND &

wait -n
kill -TERM $(jobs -p) 2>/dev/null
wait
exit 1
