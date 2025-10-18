#!/usr/bin/env bash
set -euo pipefail

USE_URANDOM=0
DO_SEED=0
for arg in "${@:-}"; do
  case "$arg" in
    --urandom) USE_URANDOM=1 ;;
    --seed|--seed-urandom) DO_SEED=1 ;;
    -h|--help)
      cat <<'HLP'
Usage: ./scripts/generate-secrets.sh [--urandom] [--seed]

--urandom      use /dev/urandom with custom charset
--seed         block once on /dev/random to ensure entropy
HLP
      exit 0 ;;
  esac
done

SECRETS_DIR="secrets"
mkdir -p "$SECRETS_DIR"

# mode schema:
#   hex:N           -> N bytes as hex
#   b64:N           -> N bytes as base64
#   plain:VALUE     -> write VALUE literally
#   empty           -> create empty file if absent
declare -A MAP=(
  [authentik_secret_key.txt]="hex:32"
  [postgres_password.txt]="b64:32"
  [redis_password.txt]="b64:32"
  [mysql_password.txt]="b64:32"
  [coredns_api_key.txt]="hex:32"
  [smtp_username.txt]="plain:smtp-user"
  [smtp_password.txt]="b64:24"
  [grafana_oauth_secret.txt]="b64:48"
  [souin_redis_password.txt]="b64:24"
  [crowdsec_bouncer_api_key.txt]="hex:32"
  [headscale_oidc_secret.txt]="b64:48"
  [headscale_noise_private_key.txt]="b64:32"
  [headscale_private_key.txt]="b64:32"
  # leave this as 'empty' so you can paste a real TS auth key later if you want auto-join
  [tailscale_authkey.txt]="empty"
  [homarr_encryption_key.txt]="hex:32"
  # Byrne Accounting secrets
  [erpnext_db_password.txt]="b64:32"
  [erpnext_admin_password.txt]="b64:24"
  [erpnext_redis_cache_password.txt]="b64:24"
  [erpnext_redis_queue_password.txt]="b64:24"
)

need(){ command -v "$1" >/dev/null || { echo "Missing $1"; exit 1; }; }
need openssl
[[ $USE_URANDOM -eq 1 ]] && need tr

seed(){ [[ $DO_SEED -eq 1 ]] && head -c 32 </dev/random >/dev/null 2>&1 || true; }

hex(){ openssl rand -hex "$1"; }
b64(){ openssl rand -base64 "$1"; }
urand(){ LC_ALL=C tr -dc 'A-Za-z0-9!#$%*+,-.:=@^_~' </dev/urandom | head -c "$1"; }

seed
echo "[*] Writing secrets into: $SECRETS_DIR"

for name in "${!MAP[@]}"; do
  path="$SECRETS_DIR/$name"
  [[ -f "$path" ]] && { echo "[skip] $name"; continue; }
  mode="${MAP[$name]}"

  printf "[make] %s ... " "$name"

  case "$mode" in
    hex:*)
      size="${mode#hex:}"; hex "$size" > "$path"
      ;;
    b64:*)
      size="${mode#b64:}"
      if [[ "$name" == "smtp_password.txt" || "$name" == "grafana_oauth_secret.txt" ]] && [[ $USE_URANDOM -eq 1 ]]; then
        urand "$size" > "$path"
      else
        b64 "$size" > "$path"
      fi
      ;;
    plain:*)
      value="${mode#plain:}"
      printf '%s' "$value" > "$path"
      ;;
    empty)
      : > "$path"
      ;;
    *)
      echo "unknown mode '$mode' for $name" >&2; exit 1
      ;;
  esac

  chmod 600 "$path"
  echo "ok"
done

cat <<'TIP'
[ok] Secrets generated.
- Keep authentik_secret_key.txt stable after first run.
- If you want Tailscale auto-join, paste your auth key into secrets/tailscale_authkey.txt.
TIP
