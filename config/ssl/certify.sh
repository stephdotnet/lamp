#!/bin/sh

# Define the path to the virtual host file
VIRTUAL_HOST_FILE="/etc/apache2/sites-enabled/default.conf"

# Extract a list of ServerName and ServerAlias domains from the virtual host file
DOMAINS=$(grep -E 'ServerName|ServerAlias' "$VIRTUAL_HOST_FILE" | awk '{print $2}' | xargs | sed 's/ / /g')

echo "Certifying for $DOMAINS"

# Loop through the list of domains and request/renew SSL certificates for each one
for domain in $DOMAINS
do
  certbot certonly --apache -d "$domain"  --agree-tos --email "$EMAIL_ADMIN" --no-eff-email
done

service apache2 restart