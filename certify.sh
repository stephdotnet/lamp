#!/bin/sh

# Define the path to the virtual host file
VIRTUAL_HOST_FILE="$VHOSTS_DIR/$CERTIFY_BASE_VIRTUAL_HOST"

# Extract a list of domains from the virtual host file
DOMAINS=$(grep ServerName "$VIRTUAL_HOST_FILE" | awk '{print $2}')

# Loop through the list of domains and request/renew SSL certificates for each one
for domain in $DOMAINS
do
  certbot certonly --apache -d "$domain"  --agree-tos --email "$EMAIL_ADMIN"
done