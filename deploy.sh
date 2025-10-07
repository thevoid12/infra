#!/bin/bash

set -e

# Source .env if exists
if [ -f .env ]; then
  source .env
fi

# Usage: ./deploy.sh <env> where env is 'local' or 'prod'

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: $0 <local|prod>"
  exit 1
fi

SSH_URL=${SSH_URL:-}
REPO=${DEPLOY_REPO:-$(git remote get-url origin)}

if [ -z "$SSH_URL" ]; then
  echo "Set SSH_URL in .env"
  exit 1
fi

# Determine SSH command
SSH_CMD="ssh"
if [ -f .password ]; then
  PASSWORD=$(cat .password)
  SSH_CMD="sshpass -p '$PASSWORD' ssh"
fi

# SECRET_KEY is sourced from .env

# SSH and deploy
$SSH_CMD $SSH_URL << EOF
  set -e
  echo "Deploying $ENV to $SSH_URL..."

  # Check tools
  command -v git >/dev/null 2>&1 || { echo "git not installed"; exit 1; }
  command -v make >/dev/null 2>&1 || { echo "make not installed"; exit 1; }
  command -v openssl >/dev/null 2>&1 || { echo "openssl not installed"; exit 1; }

  # Clone or update repo
  REPO_DIR=\$(basename "$REPO" .git)
  if [ ! -d "\$REPO_DIR" ]; then
    git clone "$REPO"
  fi
  cd "\$REPO_DIR"
  git pull

  # Use environment-specific nginx configs
  if [ "$ENV" == "local" ]; then
    cp nginx/conf.d/local/* nginx/conf.d/
  else
    cp nginx/conf.d/prod/* nginx/conf.d/
  fi

  # Run commands
  make dec-wpsecrets
  make bootstrap

  echo "Deployment complete."
EOF