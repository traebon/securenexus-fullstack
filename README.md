# SecureNexus Full Stack

Services

Traefik (reverse proxy, ACME/LE, metrics)

Authentik (SSO) + Postgres + Redis

Homepage (portal) + landing page

Monitoring: Prometheus, Blackbox, Loki, Promtail, Grafana (OIDC via Authentik), cAdvisor, Node Exporter

PowerDNS + PDNS-Admin

Stalwart (mail submission / SMTP 587)

Tailscale (admin VPN)

CrowdSec (via Traefik plugin hooks, optional)

WebFinger (static response, via Traefik dynamic file)

Notes

Authentik secret key is 64 hex chars; do not rotate post-install.

SMTP submission limited to tailnet (Traefik TCP ipAllowList).

Dashboards provisioned read-only from monitoring/dashboards/.

Logs to stdout; Promtail ships to Loki.
