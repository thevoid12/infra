#!/bin/bash

set -e

echo "Bootstrapping infra..."

# Decrypt secrets if not already decrypted
if [ ! -f woodpecker/woodpecker-server.env ]; then
    echo "Decrypting secrets..."
    make dec-wpsecrets
fi

# Start services
echo "Starting services..."
docker  compose up -d

# Reload nginx to apply new configs
echo "Reloading nginx..."
sleep 5 && docker exec nginx nginx -s reload

echo "Infra bootstrapped successfully. Woodpecker server and agent are running."
echo "Access Woodpecker at http://localhost:8000 (or configured host)"