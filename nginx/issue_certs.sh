#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$BASE_DIR/config.json"
ENV=$(jq -r '.ENV' "$CONFIG_FILE")
EMAILID=$(jq -r '.EMAILID' "$CONFIG_FILE")
CERT_DIR="/etc/letsencrypt"
NGINX_CONF_DIR="$BASE_DIR/conf.d"

if [[ "$ENV" == "prod" ]]; then
    for conf in "$NGINX_CONF_DIR"/*.conf; do
        DOMAIN=$(grep -Po '(?<=server_name\s)[^;]+' "$conf" | head -1)
        if [[ -n "$DOMAIN" ]]; then
            echo "Ensuring certificate for $DOMAIN..."
            if [[ ! -d "$CERT_DIR/live/$DOMAIN" ]]; then
                certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAILID"
            fi
        fi
    done
else
    echo "Running in local mode — HTTPS disabled."
fi

nginx -t
nginx -s reload
echo "Nginx setup complete ($ENV mode)."
