#!/bin/sh
# Install MemoryBear as a boot-started service on this machine.
#
# Idempotent: safe to re-run after a `git pull`, and re-running is how a config
# change is applied. Nothing here is specific to one host -- the address is
# discovered at each service start, so the same command works on any machine and
# survives a DHCP lease change or a move to another network.
#
#   sudo deploy/memorybear/install.sh
#
# What it does NOT do: build. The client artifacts are build-time branded, so run
# `pnpm run build:memorybear` first (or after any source change) -- this script
# checks for the result and refuses rather than starting a service that would
# serve a stale or unbranded bundle.
#
# What it deliberately leaves off: authentication. Anyone who reaches port 443
# can drive the agent, and the agent runs shell commands, so on an untrusted
# network add the auth_basic pair the nginx template documents.
set -eu

PORT="${MB_PORT:-3081}"
SERVICE_USER="${MB_USER:-$(stat -c '%U' "$(dirname "$0")")}"
TLS_DIR=/etc/nginx/tls
TLS_CRT="$TLS_DIR/memorybear.crt"
TLS_KEY="$TLS_DIR/memorybear.key"

log() { printf '  %s\n' "$*"; }
die() { printf 'install: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die 'must run as root (use sudo)'

CHECKOUT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$CHECKOUT"

# ── preconditions ───────────────────────────────────────────────────────────
NODE="$(command -v node || true)"
[ -n "$NODE" ] || die 'node not found on PATH'
[ -f apps/cli/lib/bin.js ] \
  || die 'apps/cli/lib/bin.js missing; run: pnpm run build:memorybear'
[ -f apps/web/dist/index.html ] \
  || die 'apps/web/dist missing; run: pnpm run build:memorybear'
command -v nginx >/dev/null 2>&1 || die 'nginx not installed'
command -v openssl >/dev/null 2>&1 || die 'openssl not installed'
id "$SERVICE_USER" >/dev/null 2>&1 || die "service user $SERVICE_USER does not exist"

GROUP="$(id -gn "$SERVICE_USER")"
NODE_DIR="$(dirname "$NODE")"
DSH_HOME="$(getent passwd "$SERVICE_USER" | cut -d: -f6)/.memorybear"

printf 'MemoryBear installer\n'
log "checkout   $CHECKOUT"
log "node       $NODE"
log "user       $SERVICE_USER:$GROUP"
log "port       $PORT (loopback; nginx serves 443)"

# Warn rather than fail: a brand mismatch is a cosmetic regression, not a reason
# to leave the machine without a service.
if [ -f .dsh-build/client-build-environment.json ] \
  && ! grep -q '"DSH_CLIENT_TITLE": "MemoryBear"' .dsh-build/client-build-environment.json; then
  log 'WARNING: built client is not the memorybear profile; run pnpm run build:memorybear'
fi

# ── TLS ─────────────────────────────────────────────────────────────────────
# Generated here, never committed: a private key in a repository is readable by
# anyone who can clone it. Kept if present so re-running does not invalidate a
# certificate a browser has already been told to trust.
#
# The SAN names this machine's addresses at install time. A later address change
# does not need a new certificate -- the name simply stops matching, which adds
# nothing to a warning the browser already shows for a self-signed issuer.
if [ -f "$TLS_CRT" ] && [ -f "$TLS_KEY" ]; then
  log 'tls        reusing existing certificate'
else
  mkdir -p "$TLS_DIR"
  PRIMARY="$(deploy/memorybear/local-authorities.sh primary)"
  SAN="IP:$PRIMARY,DNS:$(hostname),DNS:localhost,IP:127.0.0.1"
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "$TLS_KEY" -out "$TLS_CRT" \
    -subj "/CN=MemoryBear ($PRIMARY)" \
    -addext "subjectAltName=$SAN" >/dev/null 2>&1 \
    || die 'certificate generation failed'
  chmod 640 "$TLS_KEY"
  chgrp "$(id -gn "$(stat -c '%U' /etc/nginx)" 2>/dev/null || echo root)" "$TLS_KEY" 2>/dev/null || true
  log "tls        generated ($SAN)"
fi

# ── nginx ───────────────────────────────────────────────────────────────────
sed -e "s|@PORT@|$PORT|g" -e "s|@TLS_CRT@|$TLS_CRT|g" -e "s|@TLS_KEY@|$TLS_KEY|g" \
  deploy/memorybear/nginx-memorybear.conf.in > /etc/nginx/sites-available/memorybear
cp deploy/memorybear/nginx-websocket-upgrade.conf /etc/nginx/conf.d/websocket-upgrade.conf
ln -sfn /etc/nginx/sites-available/memorybear /etc/nginx/sites-enabled/memorybear
# Debian's default site owns port 80 with its own catch-all, which would answer
# ahead of the redirect on a fresh install.
rm -f /etc/nginx/sites-enabled/default

# nginx binds the wildcard, so it cannot fail on a missing address literal --
# but a cold boot can still race a DHCP lease, and Debian's unit only orders
# after network.target, which is satisfied while interfaces are coming up.
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/override.conf <<'OVERRIDE'
[Unit]
After=network-online.target
Wants=network-online.target
[Service]
# Retry instead of leaving the front door dead until someone notices.
Restart=on-failure
RestartSec=5
OVERRIDE

nginx -t >/dev/null 2>&1 || { nginx -t; die 'nginx config rejected'; }
log 'nginx      config installed and valid'

# ── service ─────────────────────────────────────────────────────────────────
mkdir -p /etc/memorybear
[ -f /etc/memorybear/memorybear.env ] \
  || cp deploy/memorybear/memorybear.env.example /etc/memorybear/memorybear.env

sed -e "s|@NODE@|$NODE|g" -e "s|@NODE_DIR@|$NODE_DIR|g" \
    -e "s|@USER@|$SERVICE_USER|g" -e "s|@GROUP@|$GROUP|g" \
    -e "s|@CHECKOUT@|$CHECKOUT|g" -e "s|@PORT@|$PORT|g" \
    -e "s|@DSH_HOME@|$DSH_HOME|g" \
  deploy/memorybear/memorybear.service.in > /etc/systemd/system/memorybear.service

# The preset has to arrive through the one root the app does not overwrite, and
# it must be the whole directory: discovery keeps only readdir entries where
# isDirectory() is true, which a symlink to a directory is not.
su -s /bin/sh -c "mkdir -p '$DSH_HOME'" "$SERVICE_USER"
ln -sfn "$CHECKOUT/deploy/memorybear/agent-presets" "$DSH_HOME/.agent-presets"
chown -h "$SERVICE_USER:$GROUP" "$DSH_HOME/.agent-presets"
log "preset     $DSH_HOME/.agent-presets -> checkout"

systemctl daemon-reload
systemctl enable memorybear >/dev/null 2>&1
systemctl restart memorybear
systemctl reload nginx 2>/dev/null || systemctl restart nginx
systemctl enable nginx >/dev/null 2>&1

sleep 3
systemctl is-active --quiet memorybear || die 'memorybear failed to start; see journalctl -u memorybear'
systemctl is-active --quiet nginx || die 'nginx failed to start; see journalctl -u nginx'

printf '\nMemoryBear is running.\n'
printf '  address   https://%s\n' "$(deploy/memorybear/local-authorities.sh primary)"
printf '  boot      enabled (memorybear + nginx)\n'
printf '\nAny name or address pointed at this machine works; nginx accepts every\n'
printf 'Host and the app sees each request as loopback.\n'
printf '\nThe certificate is self-signed, so accept the browser warning once.\n'
printf 'There is NO authentication and no Host fence: anyone who reaches this\n'
printf 'address can run shell commands on this machine. See the auth_basic note\n'
printf 'in /etc/nginx/sites-available/memorybear.\n'
