#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="$(dirname "${BASH_SOURCE[0]}")/config.json"
ENV=$(jq -r '.ENV' "$CONFIG_FILE")
EMAILID=$(jq -r '.EMAILID' "$CONFIG_FILE")
CERT_DIR="/etc/letsencrypt"
NGINX_CONF_DIR="$(dirname "${BASH_SOURCE[0]}")/conf.d"

# Clean up any stale PID file
rm -f /var/run/nginx.pid

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
echo "Nginx setup complete ($ENV mode)."
