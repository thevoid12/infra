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
# Wait for services to be ready, then reload nginx to apply new configs
# echo "Waiting for services to start..."
# sleep 10
# echo "Reloading nginx..."
# docker exec nginx nginx -s reload || true


echo "Infra bootstrapped successfully. Woodpecker server and agent are running."
echo "Access Woodpecker at http://localhost:8000 (or configured host)"