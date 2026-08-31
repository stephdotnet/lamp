#!/bin/sh
#
# Obtient / renouvelle les certificats Let's Encrypt des sites declares dans le
# fichier de vhosts, et recharge Apache.
#
# S'execute DANS le conteneur webserver : `make certs`.
#
# Il lit les lignes `Use RedirectSite` / `Use LaravelSite` du fichier de vhosts,
# et non les directives ServerName. Avec la config a macros, un ServerName vaut
# soit une variable de macro (`$domain`, `$from`), soit un hote factice
# (catchall.invalid, default.invalid) : les extraire produisait des demandes de
# certificat pour des domaines inexistants.
#
# Options supplementaires transmises a certbot via ARGS, par exemple
# `make certs ARGS=--dry-run` pour valider la chaine sans consommer de quota
# Let's Encrypt.

set -eu

VIRTUAL_HOST_FILE="/etc/apache2/sites-enabled/${CERTIFY_BASE_VIRTUAL_HOST:-default.conf}"
WEBROOT="/var/www/empty"

if [ ! -f "$VIRTUAL_HOST_FILE" ]; then
    echo "Fichier de vhosts introuvable : $VIRTUAL_HOST_FILE" >&2
    exit 1
fi

if [ -z "${EMAIL_ADMIN:-}" ]; then
    echo "EMAIL_ADMIN n'est pas defini (voir .env)." >&2
    exit 1
fi

# Une paire "lineage domaine" par vhost declare. Le lineage est le dernier
# argument des deux macros, le domaine servi est le premier.
#   Use RedirectSite <from>   <to>      <cert>
#   Use LaravelSite  <domain> <approot> <cert>
PAIRS=$(awk '
    $1 == "Use" && ($2 == "RedirectSite" || $2 == "LaravelSite") && NF >= 5 {
        print $5, $3
    }
' "$VIRTUAL_HOST_FILE")

if [ -z "$PAIRS" ]; then
    echo "Aucune ligne 'Use RedirectSite' / 'Use LaravelSite' dans $VIRTUAL_HOST_FILE." >&2
    echo "Rien a certifier." >&2
    exit 1
fi

# Un certificat par lineage, couvrant tous les domaines qui le referencent.
# --cert-name force le nom du repertoire sous /etc/letsencrypt/live/ : sans lui
# certbot le nomme d'apres le premier -d, et les vhosts pointeraient a cote.
# --expand couvre l'ajout d'un domaine a un lineage existant, et
# --keep-until-expiring rend le script rejouable sans invite interactive.
for lineage in $(printf '%s\n' "$PAIRS" | awk '{print $1}' | sort -u); do
    set -- # reinitialise les arguments positionnels
    for domain in $(printf '%s\n' "$PAIRS" | awk -v l="$lineage" '$1 == l { print $2 }' | sort -u); do
        set -- "$@" -d "$domain"
    done

    echo "==> $lineage : $*"
    certbot certonly \
        --webroot -w "$WEBROOT" \
        --cert-name "$lineage" \
        "$@" \
        --agree-tos --email "$EMAIL_ADMIN" --no-eff-email \
        --expand --keep-until-expiring \
        ${CERTBOT_EXTRA_ARGS:-}
done

# Pas de `service apache2 restart` : apache2 est PID 1 dans le conteneur, le
# stopper tuerait le conteneur entier. `-t` d'abord car graceful renvoie 0 meme
# en echec et garderait silencieusement l'ancienne config.
apachectl -t && apachectl -k graceful
