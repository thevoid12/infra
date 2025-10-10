#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
DOCKER_PACKAGES=(
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)

# --- UTILITIES ---
log() { echo -e "\033[1;32m[+] $*\033[0m"; }
warn() { echo -e "\033[1;33m[!] $*\033[0m"; }
err() { echo -e "\033[1;31m[✗] $*\033[0m"; exit 1; }

# --- PRECHECKS ---
if command -v docker &>/dev/null; then
  log "Docker already installed: $(docker --version)"
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
  warn "Re-running with sudo..."
  exec sudo bash "$0" "$@"
fi

# --- DETECT OS AND ARCH ---
if [[ -e /etc/os-release ]]; then
  . /etc/os-release
  OS=$ID
  VER=$VERSION_CODENAME
else
  err "Cannot detect OS. Missing /etc/os-release."
fi

ARCH=$(dpkg --print-architecture)
log "Detected OS: $OS, Codename: $VER, Arch: $ARCH"

# Map raspbian to debian
if [[ "$OS" == "raspbian" ]]; then
  OS="debian"
fi

# --- REMOVE OLD VERSIONS ---
apt-get remove -y docker docker-engine docker.io containerd runc || true

# --- INSTALL DEPENDENCIES ---
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

# --- ADD OFFICIAL DOCKER REPO ---
install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL "https://download.docker.com/linux/${OS}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/${OS} ${VER:-stable} stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# --- INSTALL DOCKER ENGINE + COMPOSE ---
apt-get update -y
apt-get install -y "${DOCKER_PACKAGES[@]}"

# --- ENABLE AND START SERVICE ---
systemctl enable docker
systemctl start docker

# --- ADD USER TO GROUP ---
CURRENT_USER=${SUDO_USER:-$USER}
if id -nG "$CURRENT_USER" | grep -qw docker; then
  log "User '$CURRENT_USER' already in docker group."
else
  usermod -aG docker "$CURRENT_USER"
  log "Added '$CURRENT_USER' to docker group. Log out/in for it to apply."
fi

# --- VERIFY ---
log "Verifying Docker installation..."
docker --version
docker compose version || docker-compose version || true

log "Docker installation completed successfully."
