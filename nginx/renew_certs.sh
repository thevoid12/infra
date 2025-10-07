#!/usr/bin/env bash
set -euo pipefail
sudo certbot renew --quiet || true
