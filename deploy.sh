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
  export SECRET_KEY="$SECRET_KEY"
  echo "Deploying $ENV to $SSH_URL..."

  # Check tools
  command -v git >/dev/null 2>&1 || { echo "git not installed"; exit 1; }
  command -v make >/dev/null 2>&1 || { echo "make not installed"; exit 1; }
  command -v openssl >/dev/null 2>&1 || { echo "openssl not installed"; exit 1; }

    # --- Install Docker if not present ---
  if ! command -v docker &> /dev/null; then
      echo "Installing Docker..."

      sudo apt-get update -y
      sudo apt-get install -y ca-certificates curl gnupg lsb-release

      # Determine the correct distro (ubuntu or debian)
      DISTRO=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
      CODENAME=$(lsb_release -cs)

      sudo install -m 0755 -d /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/${DISTRO}/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/${DISTRO} ${CODENAME} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

      sudo apt-get update -y
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo systemctl enable --now docker
  fi

  echo "Docker version: $(docker --version)"

  # --- Install Docker Compose standalone if missing ---
  if ! command -v docker-compose &> /dev/null; then
      echo "Installing Docker Compose standalone..."
      sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
          -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
  fi

  echo "Docker Compose version: $(docker-compose version --short || docker compose version --short)"

  # Clone or update repo
  REPO_DIR=\$(basename "$REPO" .git)
  if [ ! -d "\$REPO_DIR" ]; then
    git clone "$REPO"
  fi
  cd "\$REPO_DIR"
  git pull

  # Set executable permissions
  chmod +x bootstrap.sh deploy.sh nginx/issue_certs.sh nginx/renew_certs.sh


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