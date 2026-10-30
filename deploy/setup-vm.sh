#!/usr/bin/env bash
# Sets up a fresh Oracle Cloud VM (Ubuntu 24.04, arm64) to run FreshCart.
# See DEPLOYMENT.md, "Moving to a new server". Run as `ubuntu` on the new VM:
#
#   bash setup-vm.sh
#
# It installs Postgres, Dart, Caddy and Git, opens ports 80 and 443, creates
# the database, clones the repo with a read-only deploy key, and installs the
# systemd service and Caddy config. It does NOT copy secrets (passwords.yaml),
# the VM's production.yaml, the web app or any data: those come from the old
# VM, never through git. Safe to run again: each step skips what's done.
set -euo pipefail

DOMAIN="freshcart-nikos.duckdns.org"
REPO="git@github.com:Sporidis/freshcart.git"
APP_DIR="$HOME/freshcart"

step() { printf '\n== %s\n' "$*"; }

step "System packages"
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
sudo apt-get install -y -qq postgresql git rsync curl gpg \
  debian-keyring debian-archive-keyring apt-transport-https netfilter-persistent

step "Dart (Google's apt repository)"
if ! command -v dart >/dev/null; then
  curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub \
    | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
  echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64,arm64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' \
    | sudo tee /etc/apt/sources.list.d/dart_stable.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq dart
fi
dart --version

step "Caddy (official apt repository)"
if ! command -v caddy >/dev/null; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq caddy
fi

step "Firewall: allow 80 and 443 (Oracle's images reject everything but SSH)"
for port in 80 443; do
  if ! sudo iptables -C INPUT -p tcp -m state --state NEW --dport "$port" -j ACCEPT 2>/dev/null; then
    # Before the image's final REJECT rule.
    sudo iptables -I INPUT 5 -p tcp -m state --state NEW --dport "$port" -j ACCEPT
  fi
done
sudo netfilter-persistent save

step "Database: role and database 'freshcart'"
if ! sudo -u postgres psql -tAc "select 1 from pg_roles where rolname='freshcart'" | grep -q 1; then
  read -r -s -p "Password for the 'freshcart' database role (the 'database' value under production: in passwords.yaml): " DB_PASSWORD
  echo
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE ROLE freshcart LOGIN PASSWORD '${DB_PASSWORD//\'/\'\'}';"
fi
if ! sudo -u postgres psql -tAc "select 1 from pg_database where datname='freshcart'" | grep -q 1; then
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE freshcart OWNER freshcart;"
fi

step "GitHub deploy key (read-only access to the repo)"
if [ ! -f "$HOME/.ssh/github_deploy" ]; then
  ssh-keygen -t ed25519 -N '' -C "freshcart-vm-deploy" -f "$HOME/.ssh/github_deploy" >/dev/null
fi
if ! grep -q "github_deploy" "$HOME/.ssh/config" 2>/dev/null; then
  printf 'Host github.com\n  IdentityFile ~/.ssh/github_deploy\n  IdentitiesOnly yes\n' >> "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
fi
if [ ! -d "$APP_DIR/.git" ]; then
  echo "Add this key on GitHub: repo Settings → Deploy keys → Add (read-only):"
  cat "$HOME/.ssh/github_deploy.pub"
  read -r -p "Press Enter once it's added... "
  ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
  git clone "$REPO" "$APP_DIR"
fi

step "systemd service 'freshcart-server'"
sudo tee /etc/systemd/system/freshcart-server.service >/dev/null <<UNIT
[Unit]
Description=FreshCart Serverpod server
After=network-online.target postgresql.service
Wants=network-online.target

[Service]
User=ubuntu
WorkingDirectory=$APP_DIR/freshcart_server
ExecStart=/usr/bin/dart run bin/main.dart --mode production
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable freshcart-server

step "Caddy: /app to the web server, everything else to the API"
sudo tee /etc/caddy/Caddyfile >/dev/null <<CADDY
$DOMAIN {
	handle /app* {
		reverse_proxy localhost:8082
	}
	handle {
		reverse_proxy localhost:8080
	}
}
CADDY
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy

step "Done. Next: DEPLOYMENT.md, 'Moving to a new server', from step 3."
