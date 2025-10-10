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

# --- LOGGING ---
if [[ ! -t 1 ]]; then
  NOCOLOR=1
fi

log() {
  if [[ -n "${NOCOLOR:-}" ]]; then
    echo "[+] $*"
  else
    echo -e "\033[1;32m[+] $*\033[0m"
  fi
}

warn() {
  if [[ -n "${NOCOLOR:-}" ]]; then
    echo "[!] $*" >&2
  else
    echo -e "\033[1;33m[!] $*\033[0m" >&2
  fi
}

err() {
  if [[ -n "${NOCOLOR:-}" ]]; then
    echo "[✗] $*" >&2
  else
    echo -e "\033[1;31m[✗] $*\033[0m" >&2
  fi
  exit 1
}

# --- CHECK EXISTING INSTALLATION ---
if command -v docker &>/dev/null && (command -v docker-compose &>/dev/null || docker compose version &>/dev/null); then
  log "Docker and Docker Compose already installed. Skipping installation."
  exit 0
fi

# --- RUN AS ROOT ---
if [[ $EUID -ne 0 ]]; then
  warn "Re-running with sudo..."
  exec sudo -E bash "$0" "$@"
fi

# --- DETECT OS AND ARCH ---
if [[ -e /etc/os-release ]]; then
  . /etc/os-release
  OS=$ID
  CODENAME=${VERSION_CODENAME:-stable}
else
  err "Cannot detect OS. Missing /etc/os-release."
fi

ARCH=$(dpkg --print-architecture)
log "Detected OS: $OS, Codename: $CODENAME, Arch: $ARCH"

# Map Raspbian to Debian
if [[ "$OS" == "raspbian" ]]; then
  OS="debian"
fi

# Fix misreporting: some Pi OSes report Ubuntu
if [[ "$OS" == "ubuntu" && "$CODENAME" == "bookworm" ]]; then
  log "Bookworm detected on Ubuntu ID — forcing Debian repo."
  OS="debian"
fi

# --- CLEAN PREVIOUS DOCKER SOURCE LIST ---
if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
  log "Removing old Docker APT source list..."
  rm -f /etc/apt/sources.list.d/docker.list
fi

# --- INSTALL DEPENDENCIES ---
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

# --- ADD OFFICIAL DOCKER REPO ---
install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  log "Adding Docker GPG key..."
  curl -fsSL "https://download.docker.com/linux/${OS}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

log "Adding Docker APT repository..."
cat <<EOF | tee /etc/apt/sources.list.d/docker.list
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS} ${CODENAME} stable
EOF

# --- INSTALL DOCKER ENGINE + PLUGIN ---
apt-get update -y
log "Installing Docker packages..."
apt-get install -y "${DOCKER_PACKAGES[@]}"

# --- ENABLE AND START DOCKER SERVICE ---
systemctl enable docker
systemctl start docker

# --- ADD USER TO DOCKER GROUP ---
CURRENT_USER=${SUDO_USER:-$USER}
if id -nG "$CURRENT_USER" | grep -qw docker; then
  log "User '$CURRENT_USER' already in docker group."
else
  usermod -aG docker "$CURRENT_USER"
  log "Added '$CURRENT_USER' to docker group. Log out/in for it to apply."
fi

# --- VERIFY INSTALLATION ---
log "Verifying Docker installation..."
docker --version
docker compose version || docker-compose version || true

log "Docker installation completed successfully."
