#!/bin/bash

set -e

echo "Bootstrapping infra..."

# Decrypt secrets if not already decrypted
if [ ! -f woodpecker/woodpecker-server.env ]; then
    echo "Decrypting secrets..."
    make dec-secrets
fi

# Start services
echo "Starting services..."
docker-compose up -d

echo "Infra bootstrapped successfully. Woodpecker server and agent are running."
echo "Access Woodpecker at http://localhost:8000 (or configured host)"