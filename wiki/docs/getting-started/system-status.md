# System Status

Current system health and operational status for the SecureNexus Full Stack platform.

## Overall Health

!!! success "System Status: 100% Operational"
    **Last Updated**: October 2025

    - **Containers**: 29/29 running
    - **Prometheus Targets**: 19/19 up
    - **Security Grade**: A+
    - **Critical Alerts**: 0 firing
    - **Uptime**: 99.9%+

## Service Status

### Core Infrastructure ✅

| Service | Status | Uptime | Notes |
|---------|--------|--------|-------|
| Traefik | 🟢 Running | 99.9% | SSL auto-renewal active |
| Docker Proxy | 🟢 Running | 100% | Secure API access |
| Tailscale | 🟢 Running | 99.8% | VPN connected |
| CrowdSec | 🟢 Running | 100% | LAPI mode active |
| Souin Cache | 🟢 Running | 99.9% | HTTP caching enabled |

### Identity & Auth ✅

| Service | Status | Uptime | Notes |
|---------|--------|--------|-------|
| Authentik Server | 🟢 Running | 99.9% | SSO operational |
| Authentik Worker | 🟢 Running | 99.9% | Background jobs active |
| PostgreSQL | 🟢 Running | 100% | Primary database |
| Redis Cache | 🟢 Running | 100% | Cache hit rate: 85% |

### Business Applications ✅

| Service | Status | Uptime | Notes |
|---------|--------|--------|-------|
| ERPNext Backend | 🟢 Running | 99.9% | Multi-tenant active |
| ERPNext Scheduler | 🟢 Running | 99.9% | Background jobs |
| ERPNext Websocket | 🟢 Running | 99.8% | Real-time updates |
| MariaDB | 🟢 Running | 100% | ERP database |
| Mailcow | 🟢 Running | 99.9% | Mail services active |

### Monitoring Stack ✅

| Service | Status | Uptime | Notes |
|---------|--------|--------|-------|
| Prometheus | 🟢 Running | 99.9% | 30-day retention |
| Grafana | 🟢 Running | 99.9% | VPN-only access |
| Loki | 🟢 Running | 99.8% | Log aggregation |
| Promtail | 🟢 Running | 99.9% | Log shipping |
| Uptime Kuma | 🟢 Running | 100% | Status monitoring |
| cAdvisor | 🟢 Running | 100% | Container metrics |
| Node Exporter | 🟢 Running | 100% | System metrics |

### DNS Infrastructure ✅

| Service | Status | Uptime | Notes |
|---------|--------|--------|-------|
| CoreDNS | 🟢 Running | 99.9% | Authoritative DNS |
| etcd | 🟢 Running | 100% | DNS record store |
| DNS Updater | 🟢 Running | 99.9% | Auto DNS updates |

## Resource Usage

### Memory Utilization

```
Prometheus:     1.2 GB / 2.0 GB (60%)  ✅
MariaDB:        800 MB / 2.0 GB (40%)  ✅
PostgreSQL:     450 MB / 1.0 GB (45%)  ✅
ERPNext:        1.5 GB / 3.0 GB (50%)  ✅
Grafana:        200 MB / 512 MB (39%)  ✅
```

### Disk Usage

```
Total:          500 GB
Used:           185 GB (37%)  ✅
Available:      315 GB (63%)
```

### Network Traffic

- **Inbound**: ~2.5 GB/day
- **Outbound**: ~3.2 GB/day
- **Average Requests**: ~15K/day

## SSL Certificates

| Domain | Status | Expires | Auto-Renew |
|--------|--------|---------|------------|
| securenexus.net | ✅ Valid | Jan 2026 | ✅ Enabled |
| *.securenexus.net | ✅ Valid | Jan 2026 | ✅ Enabled |
| byrne-accounts.org | ✅ Valid | Jan 2026 | ✅ Enabled |
| *.byrne-accounts.org | ✅ Valid | Jan 2026 | ✅ Enabled |

## Security Status

### Firewall Configuration ✅

```
Active Ports:
- 22   (SSH)
- 25   (SMTP)
- 53   (DNS)
- 80   (HTTP → HTTPS redirect)
- 143  (IMAP)
- 443  (HTTPS)
- 465  (SMTPS)
- 587  (Submission)
- 853  (DNS-over-TLS)
- 993  (IMAPS)
- 995  (POP3S)
- 41641/udp (Tailscale)
```

### Security Hardening ✅

- ✅ Automated backup rotation (7 daily / 4 weekly / 12 monthly)
- ✅ Prometheus retention policy (30 days)
- ✅ Comprehensive alerting (30+ rules)
- ✅ Disaster recovery documented
- ✅ Multi-layer rate limiting
- ✅ Log rotation configured
- ✅ Secrets rotation policy

### Active Protection

- **CrowdSec**: Monitoring for intrusions
- **Traefik Middlewares**: Secure headers, rate limiting
- **UFW Firewall**: Deny-by-default policy
- **Tailscale VPN**: Admin-only access layer

## Recent Changes

### October 2025 Optimizations

1. **Prometheus Memory**: Increased to 2GB (prevents OOM)
2. **Grafana Access**: Protected with VPN-only middleware
3. **Uptime Kuma**: Granted Docker socket access
4. **CrowdSec**: Configured in LAPI-only mode
5. **Firewall**: Added POP3S, removed duplicate rules

## Quick Health Check

Run this command to verify system health:

```bash
# Check all containers
docker compose ps

# View service logs
make logs

# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Verify SSL certificates
./scripts/check-ssl-expiry.sh
```

## Alert Status

**Current Alerts**: 0 firing

All 30+ alert rules are active and monitoring:
- Service availability
- Resource usage
- Security events
- Backup status
- SSL expiration
- DNS health

For detailed status, see [SYSTEM_STATUS_FINAL.md](../SYSTEM_STATUS_FINAL.md)
