#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-$(grep -E '^DOMAIN=' .env 2>/dev/null | cut -d= -f2- || true)}"

docker version >/dev/null
docker compose version >/dev/null || docker-compose version >/dev/null

missing=0
for f in secrets/*.txt; do
  # Skip empty check for optional tailscale_authkey.txt
  [[ "$f" == "secrets/tailscale_authkey.txt" ]] && continue
  [[ -s "$f" ]] || { echo "MISSING: $f"; missing=1; }
done

[[ $missing -eq 0 ]] || { echo "Run ./scripts/generate-secrets.sh"; exit 1; }
[[ -n "$DOMAIN" ]] || { echo "DOMAIN not set in env or .env"; exit 1; }

docker compose config >/dev/null
echo "[ok] Preflight passed for DOMAIN=$DOMAIN"
