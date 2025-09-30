#!/usr/bin/env bash
set -euo pipefail

PDNS_API="${PDNS_API_URL:-http://pdns:8081}"
PDNS_KEY="${PDNS_API_KEY:?missing PDNS_API_KEY}"
ZONE="${DNS_ZONE:-${DOMAIN:?set DOMAIN or DNS_ZONE}}."
TTL="${DNS_TTL:-300}"

die(){ echo "ERR: $*" >&2; exit 1; }

json(){
  jq -c . 2>/dev/null || cat
}

upsert_record(){
  local name="$1" type="$2" content="$3"
  curl -fsS -X PATCH "${PDNS_API}/api/v1/servers/localhost/zones/${ZONE}" \
    -H "X-API-Key: ${PDNS_KEY}" -H "Content-Type: application/json" \
    -d "$(cat <<JSON
{ "rrsets": [ { "name": "${name}.${ZONE}", "type": "${type}", "ttl": ${TTL},
  "changetype": "REPLACE", "records": [ { "content": "${content}", "disabled": false } ] } ] }
JSON
)" >/dev/null
  echo "[dns] ${type} ${name}.${ZONE} -> ${content}"
}

ensure_zone(){
  curl -fsS -H "X-API-Key: ${PDNS_KEY}" "${PDNS_API}/api/v1/servers/localhost/zones/${ZONE}" >/dev/null && return 0
  curl -fsS -X POST "${PDNS_API}/api/v1/servers/localhost/zones" \
    -H "X-API-Key: ${PDNS_KEY}" -H "Content-Type: application/json" \
    -d "{\"name\":\"${ZONE}\",\"kind\":\"Native\",\"nameservers\":[\"ns1.${ZONE}\"]}" >/dev/null
  echo "[dns] created zone ${ZONE}"
}

main(){
  ensure_zone
  # get Traefik router hostnames via docker-proxy (labels)
  local hosts
  hosts=$(docker --host tcp://docker-proxy:2375 ps --format '{{.ID}}' |
    xargs -r docker --host tcp://docker-proxy:2375 inspect --format '{{json .Config.Labels}}' |
    jq -r 'to_entries[]? | select(.key|test("^traefik\\.http\\.routers\\..*\\.rule$")) | .value' |
    sed -nE "s/.*Host\(`([^`]+)`\).*/\1/p" | sort -u)

  local ip4 ip6
  ip4=$(getent hosts traefik | awk '{print $1}' | head -n1)
  ip6=$(getent ahosts traefik | awk '$1 ~ /:/{print $1; exit}')

  for h in $hosts; do
    [[ "$h" == *"${ZONE%?}" ]] || continue
    sub="${h%%.${ZONE%?}}"
    [[ -n "${ip4:-}" ]] && upsert_record "$sub" "A" "$ip4"
    [[ -n "${ip6:-}" ]] && upsert_record "$sub" "AAAA" "$ip6"
  done
}

main "$@"
