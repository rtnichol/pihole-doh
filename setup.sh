#!/usr/bin/env bash
# Run this once on the Raspberry Pi before starting the stack.
set -euo pipefail

# ── 1. Disable systemd-resolved stub listener so port 53 is free ─────────────
# systemd-resolved binds 127.0.0.53:53 by default; this conflicts with Pi-hole.
if systemctl is-active --quiet systemd-resolved; then
  echo "Disabling systemd-resolved stub listener..."
  sudo mkdir -p /etc/systemd/resolved.conf.d
  sudo tee /etc/systemd/resolved.conf.d/no-stub.conf > /dev/null <<EOF
[Resolve]
DNSStubListener=no
EOF
  sudo systemctl restart systemd-resolved
  # Point /etc/resolv.conf at the real resolved socket (not the stub)
  sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
  echo "Done. systemd-resolved stub disabled."
fi

# ── 2. Copy .env if missing ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
  echo ""
  echo "Created .env from .env.example — set PIHOLE_PASSWORD and TZ before continuing."
  echo "  nano $SCRIPT_DIR/.env"
  exit 0
fi

# ── 3. Pull images and start the stack ───────────────────────────────────────
cd "$SCRIPT_DIR"
docker compose pull
docker compose up -d

echo ""
echo "Stack is up. Access Pi-hole at http://$(hostname -I | awk '{print $1}'):${PIHOLE_WEB_PORT:-8080}/admin"
echo "Point your router's DHCP DNS option to: $(hostname -I | awk '{print $1}')"
