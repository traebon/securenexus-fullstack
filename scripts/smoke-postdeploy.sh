#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-$(grep -E '^DOMAIN=' .env 2>/dev/null | cut -d= -f2- || true)}"

need(){ command -v "$1" >/dev/null || { echo "Missing $1"; exit 1; }; }
need curl
need openssl

ok(){ echo -e "\033[32m[ok]\033[0m $*"; }
err(){ echo -e "\033[31m[err]\033[0m $*"; }

set +e
curl -fsS https://traefik.${DOMAIN}/ping >/dev/null && ok "Traefik ping" || err "Traefik ping failed"
curl -fsS https://${DOMAIN}/ >/dev/null && ok "Landing page" || err "Landing failed"
curl -I -s https://portal.${DOMAIN}/ | head -n1 | grep -q "HTTP/" && ok "Portal reachable" || err "Portal failed"

code=$(curl -o /dev/null -s -w "%{http_code}" https://authentik.${DOMAIN}/if/flow/)
[[ "$code" =~ ^20|30 ]] && ok "Authentik ($code)" || err "Authentik HTTP $code"

code=$(curl -o /dev/null -s -w "%{http_code}" https://grafana.${DOMAIN}/login)
[[ "$code" =~ ^20|30 ]] && ok "Grafana ($code)" || err "Grafana HTTP $code"

curl -fsS https://prometheus.${DOMAIN}/graph >/dev/null && ok "Prometheus UI" || err "Prometheus UI failed"

echo -e "EHLO test\r\nSTARTTLS\r\n" | openssl s_client -starttls smtp -crlf -connect mail.${DOMAIN}:587 -servername mail.${DOMAIN} >/tmp/smtp.out 2>/dev/null
grep -q "250-STARTTLS" /tmp/smtp.out && ok "SMTP STARTTLS advertised" || err "SMTP STARTTLS not advertised"
rm -f /tmp/smtp.out
set -e
echo "Smoke test complete."
