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

# Une paire "lineage domaine" par vhost declare. Le lineage est le 3e argument
# de chaque macro (champ 5 de la ligne), le domaine servi est le 1er (champ 3).
#   Use RedirectSite      <from>   <to>      <cert>
#   Use LaravelSite       <domain> <approot> <cert>
#   Use LaravelReverbSite <domain> <approot> <cert> <wsbackend>
#
# Le filtre porte sur le NOM DE MACRO : toute nouvelle macro de site doit etre
# ajoutee ici, sinon les domaines qu'elle declare sont silencieusement absents
# de `make certs` et leur certificat n'est jamais renouvele. La panne
# n'apparait que ~90 jours plus tard, en erreur TLS.
#
# Le lineage doit rester en 3e position dans toute nouvelle macro, c'est ce qui
# permet de toutes les lire avec une seule regle.
PAIRS=$(awk '
    $1 == "Use" \
    && ($2 == "RedirectSite" || $2 == "LaravelSite" || $2 == "LaravelReverbSite") \
    && NF >= 5 {
        print $5, $3
    }
' "$VIRTUAL_HOST_FILE")

if [ -z "$PAIRS" ]; then
    echo "Aucune ligne 'Use RedirectSite' / 'Use LaravelSite' / 'Use LaravelReverbSite' dans $VIRTUAL_HOST_FILE." >&2
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
