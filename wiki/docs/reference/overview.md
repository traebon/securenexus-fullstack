# Reference Overview

Quick reference materials, commands, diagrams, and API documentation for system administrators.

## System Administrator Quick Reference

### Daily Operations

**Morning health check**:
```bash
# Quick status check
docker compose ps | grep -v "Up"  # Shows any non-running containers
df -h | grep -E "(/|docker)"      # Check disk space
free -h                            # Check memory

# View overnight alerts
docker compose logs uptime-kuma | grep -i "down"

# Check backup completion
tail -5 /var/log/securenexus-backup.log

# Review security events
docker compose exec crowdsec cscli decisions list | head -10
```

**Expected output** (healthy system):
- All containers: "Up" or "Up (healthy)"
- Disk usage: < 85%
- Memory usage: < 90%
- No critical alerts
- Backup: "SUCCESS"
- CrowdSec: No new bans (or expected bans only)

### Emergency Commands

**Critical service restart**:
```bash
# Restart all services (minimal downtime)
docker compose restart

# Nuclear option - full restart (2-3 min downtime)
docker compose down && docker compose up -d

# Restart specific service
docker compose restart <service-name>
```

**Quick backup** (before risky operations):
```bash
# Full backup (takes ~5 minutes)
sudo ./scripts/backup-rotation.sh

# Quick config backup (takes seconds)
tar -czf /tmp/config-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  config/ secrets/ compose.yml .env
```

**Emergency restore**:
```bash
# Restore latest backup
sudo ./scripts/restore-from-backup.sh \
  /backup/securenexus/daily/$(ls -t /backup/securenexus/daily/ | head -1)
```

**Security lockdown** (if under attack):
```bash
# Block IP immediately
docker compose exec crowdsec cscli decisions add \
  --ip <attacker-ip> --duration 24h --reason "Manual ban"

# Enable stricter firewall
sudo ufw default deny incoming
sudo ufw reload

# Disable public services temporarily
docker compose stop homarr landing
```

### Resource Monitoring

**CPU usage by container**:
```bash
docker stats --no-stream --format \
  "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | \
  sort -k 2 -h -r | head -10
```

**Disk usage by volume**:
```bash
docker system df -v | grep -A 20 "Local Volumes"
```

**Memory usage**:
```bash
# Overall system
free -h

# By container (top 10)
docker stats --no-stream --format \
  "table {{.Name}}\t{{.MemUsage}}" | \
  sort -k 2 -h -r | head -10
```

**Network traffic**:
```bash
# Current traffic
ifstat -i eth0 1 5

# Total transferred today
docker stats --no-stream --format \
  "table {{.Name}}\t{{.NetIO}}"
```

### Log Analysis

**Find errors in last hour**:
```bash
docker compose logs --since 1h | grep -i error | less
```

**Top error messages**:
```bash
docker compose logs --since 24h | \
  grep -i error | \
  cut -d'|' -f3- | \
  sort | uniq -c | sort -rn | head -10
```

**Failed login attempts**:
```bash
docker compose logs authentik_server | \
  grep -i "failed.*login" | \
  tail -20
```

**SSL certificate errors**:
```bash
docker compose logs traefik | \
  grep -i "acme" | \
  grep -i "error" | \
  tail -10
```

### Network Diagnostics

**Test external connectivity**:
```bash
# DNS resolution
dig google.com
dig @8.8.8.8 google.com

# HTTP connectivity
curl -I https://google.com

# SMTP connectivity
telnet mail.securenexus.net 25
```

**Internal service connectivity**:
```bash
# Test from Traefik to ERPNext
docker compose exec traefik ping erpnext-backend

# Test from ERPNext to MariaDB
docker compose exec erpnext-backend ping mariadb

# Test from Authentik to PostgreSQL
docker compose exec authentik_server ping authentik_db
```

**Port status**:
```bash
# Check listening ports
sudo ss -tulpn | grep -E ":(80|443|25|53|587|993|995)" | sort

# Check from external
nmap -p 80,443,25,587 <server-ip>
```

### Security Checks

**Banned IPs** (CrowdSec):
```bash
# List all bans
docker compose exec crowdsec cscli decisions list

# Ban count
docker compose exec crowdsec cscli decisions list | wc -l

# Unban if needed
docker compose exec crowdsec cscli decisions delete --ip <ip-address>
```

**Failed SSH attempts**:
```bash
sudo journalctl -u sshd | grep "Failed password" | tail -20
```

**SSL certificate expiry**:
```bash
# Check expiry date
echo | openssl s_client -connect securenexus.net:443 2>/dev/null | \
  openssl x509 -noout -enddate

# Days until expiry
echo | openssl s_client -connect securenexus.net:443 2>/dev/null | \
  openssl x509 -noout -checkend 604800 && \
  echo "Certificate valid for > 7 days" || \
  echo "WARNING: Certificate expires soon!"
```

**Open files** (check for leaks):
```bash
# Per container
for container in $(docker ps --format '{{.Names}}'); do
  echo "=== $container ==="
  docker exec $container sh -c 'ls -l /proc/self/fd | wc -l' 2>/dev/null || echo "N/A"
done
```

### Performance Tuning

**Database optimization**:
```bash
# MariaDB (ERPNext)
docker compose exec mariadb mysql -e "
  SELECT table_schema AS 'Database',
         ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
  FROM information_schema.tables
  GROUP BY table_schema
  ORDER BY SUM(data_length + index_length) DESC;"

# Optimize large tables
docker compose exec mariadb mysql -e "
  USE <database>;
  OPTIMIZE TABLE \`tabSales Invoice\`;
  ANALYZE TABLE \`tabSales Invoice\`;"

# PostgreSQL (Authentik)
docker compose exec authentik_db psql -U authentik -d authentik -c "
  SELECT pg_size_pretty(pg_database_size('authentik')) AS size;"

# Vacuum
docker compose exec authentik_db psql -U authentik -d authentik -c "
  VACUUM ANALYZE;"
```

**Clear caches**:
```bash
# ERPNext
docker compose exec erpnext-backend bench --site all clear-cache

# Redis
docker compose exec redis_cache redis-cli FLUSHALL

# Souin HTTP cache
docker compose restart souin_redis
```

**Rebuild assets** (ERPNext):
```bash
docker compose exec erpnext-backend bench build
```

### Backup Management

**List backups**:
```bash
# All backups with sizes
du -sh /backup/securenexus/*/* | sort -h

# Latest backup
ls -lht /backup/securenexus/daily/ | head -2
```

**Verify backup integrity**:
```bash
# Check for backup files
latest_backup=$(ls -t /backup/securenexus/daily/ | head -1)
ls -lh /backup/securenexus/daily/$latest_backup/

# Verify database backups exist
ls -lh /backup/securenexus/daily/$latest_backup/databases/

# Check backup manifest
cat /backup/securenexus/daily/$latest_backup/MANIFEST.txt
```

**Test restore** (dry run):
```bash
# Extract to temp location
mkdir -p /tmp/restore-test
tar -xzf /backup/securenexus/daily/*/volumes/grafana.tar.gz \
  -C /tmp/restore-test

# Verify contents
ls -la /tmp/restore-test

# Clean up
rm -rf /tmp/restore-test
```

### User Management

**Authentik users**:
```bash
# List all users
docker compose exec authentik_server ak user list

# Create admin user
docker compose exec authentik_server ak bootstrap-authentik-admin \
  --username admin2 \
  --password <password>

# Reset password
docker compose exec authentik_server ak user reset-password \
  --user <username>
```

**ERPNext users** (per site):
```bash
# List users
docker compose exec erpnext-backend \
  bench --site <site> console <<< "frappe.get_all('User', fields=['name', 'email', 'enabled'])"

# Add system manager
docker compose exec erpnext-backend \
  bench --site <site> add-system-manager admin@example.com

# Disable user
docker compose exec erpnext-backend \
  bench --site <site> disable-user user@example.com
```

### SSL Certificate Management

**View all certificates**:
```bash
docker compose exec traefik cat /acme.json | \
  jq '.le.Certificates[] | {domain: .domain.main, sans: .domain.sans}'
```

**Force certificate renewal** (rarely needed):
```bash
# Delete certificate from acme.json
docker compose exec traefik cat /acme.json | \
  jq 'del(.le.Certificates[] | select(.domain.main == "<domain>"))' > /tmp/acme.json

# Replace acme.json
docker compose cp /tmp/acme.json traefik:/acme.json

# Restart Traefik to request new certificate
docker compose restart traefik
```

**Check certificate from external**:
```bash
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | \
  openssl x509 -noout -text | grep -E "(Subject:|Issuer:|Not Before|Not After)"
```

### Email Diagnostics

**Check mail queue**:
```bash
# Postfix queue
docker exec mailcow-postfix-mailcow postqueue -p

# Queue count
docker exec mailcow-postfix-mailcow postqueue -p | tail -1

# Flush queue
docker exec mailcow-postfix-mailcow postqueue -f
```

**Test SMTP**:
```bash
# Via telnet
telnet mail.securenexus.net 587

# Send test email
echo "Test message" | mail -s "Test" admin@example.com
```

**Check spam filtering**:
```bash
# Rspamd stats
curl -s http://localhost:11334/stat | jq

# Recent spam
docker logs mailcow-rspamd-mailcow | grep "SPAM" | tail -20
```

### DNS Management

**Query DNS**:
```bash
# Local CoreDNS
dig @localhost securenexus.net

# Specific record type
dig @localhost MX securenexus.net
dig @localhost TXT securenexus.net

# External resolver
dig @8.8.8.8 securenexus.net
```

**etcd DNS records**:
```bash
# List all records
docker compose exec etcd etcdctl get --prefix /coredns/ | less

# Add manual record
docker compose exec etcd etcdctl put \
  /coredns/net/securenexus/test \
  '{"host":"1.2.3.4","ttl":300}'

# Delete record
docker compose exec etcd etcdctl del /coredns/net/securenexus/test
```

**Sync DNS** (manual trigger):
```bash
./scripts/dns-sync.sh
```

### Firewall Management

**Current rules**:
```bash
sudo ufw status numbered
```

**Add rule**:
```bash
# Allow port
sudo ufw allow <port>/<protocol>

# Allow from specific IP
sudo ufw allow from <ip> to any port <port>

# Rate limit
sudo ufw limit <port>/<protocol>
```

**Delete rule**:
```bash
sudo ufw delete <rule-number>
```

**Reload firewall**:
```bash
sudo ufw reload
```

## Commands Reference

### Docker Compose

| Command | Description |
|---------|-------------|
| `docker compose up -d` | Start all services in background |
| `docker compose down` | Stop and remove all containers |
| `docker compose ps` | List containers |
| `docker compose logs -f <service>` | Follow logs for service |
| `docker compose restart <service>` | Restart service |
| `docker compose pull` | Pull latest images |
| `docker compose config` | Validate and view config |
| `docker compose exec <service> <cmd>` | Execute command in container |

### Make Targets

| Target | Description |
|--------|-------------|
| `make secrets` | Generate all secrets |
| `make preflight` | Pre-deployment checks |
| `make up-core` | Start core services |
| `make up-identity` | Start identity services |
| `make up-portal` | Start portal services |
| `make up-monitoring` | Start monitoring services |
| `make up-all` | Start all services |
| `make down` | Stop all services |
| `make ps` | List containers |
| `make logs` | View all logs |
| `make restart S=<service>` | Restart specific service |

### System Maintenance

| Command | Description |
|---------|-------------|
| `sudo apt update && sudo apt upgrade` | Update OS packages |
| `docker system prune -a` | Clean unused Docker resources |
| `sudo journalctl --vacuum-time=7d` | Clean old system logs |
| `sudo ufw reload` | Reload firewall rules |
| `./scripts/backup-rotation.sh` | Run backup |

## Architecture Diagrams

### Complete System Architecture

See [System Architecture](../getting-started/architecture.md) for detailed diagrams including:

- High-level architecture
- Service profiles and dependencies
- Network architecture
- Security layers
- Data flow diagrams
- SSL certificate flow
- Storage architecture

### Infrastructure Diagrams

See [Infrastructure Overview](../infrastructure/overview.md) for:

- DNS infrastructure (CoreDNS + etcd)
- VPN access architecture
- SSL/TLS certificate flow

### Security Architecture

See [Security Overview](../security/overview.md) for:

- Security layers diagram
- Multi-layer security model
- Access control flow

## API Reference

### Traefik API

**Base URL**: `http://localhost:8080/api`

**Endpoints**:
```bash
# List routers
curl -s http://localhost:8080/api/http/routers | jq

# List services
curl -s http://localhost:8080/api/http/services | jq

# List middlewares
curl -s http://localhost:8080/api/http/middlewares | jq

# Raw configuration
curl -s http://localhost:8080/api/rawdata | jq
```

### Prometheus API

**Base URL**: `http://localhost:9090/api/v1`

**Endpoints**:
```bash
# Query instant value
curl -s "http://localhost:9090/api/v1/query?query=up" | jq

# Query range
curl -s "http://localhost:9090/api/v1/query_range?query=up&start=$(date -d '1 hour ago' +%s)&end=$(date +%s)&step=60" | jq

# List targets
curl -s http://localhost:9090/api/v1/targets | jq

# List alerts
curl -s http://localhost:9090/api/v1/alerts | jq
```

### Mailcow API

**Base URL**: `https://mail.securenexus.net/api/v1`

**Get API key**:
```bash
./scripts/mailcow-get-api-key.sh
```

**Endpoints**:
```bash
# List domains
curl -s "https://mail.securenexus.net/api/v1/get/domain/all" \
  -H "X-API-Key: <key>" | jq

# List mailboxes
curl -s "https://mail.securenexus.net/api/v1/get/mailbox/all" \
  -H "X-API-Key: <key>" | jq

# Add mailbox
curl -X POST "https://mail.securenexus.net/api/v1/add/mailbox" \
  -H "X-API-Key: <key>" \
  -H "Content-Type: application/json" \
  -d '{"local_part":"user","domain":"example.com","password":"pass"}'
```

**Documentation**: [Mailcow API Setup](../MAILCOW_API_SETUP.md)

### Authentik API

**Base URL**: `https://sso.securenexus.net/api/v3`

**Get API key**:
1. Login to Authentik admin
2. Go to Directory > Tokens & App passwords
3. Create token

**Endpoints**:
```bash
# List users
curl -s "https://sso.securenexus.net/api/v3/core/users/" \
  -H "Authorization: Bearer <token>" | jq

# List applications
curl -s "https://sso.securenexus.net/api/v3/core/applications/" \
  -H "Authorization: Bearer <token>" | jq
```

## File Locations

### Configuration Files

```
/home/tristian/securenexus-fullstack/
├── .env                          # Environment variables
├── compose.yml                   # Docker Compose config
├── config/
│   ├── traefik.yml              # Traefik static config
│   └── dynamic/
│       ├── traefik_dynamic.yml  # Traefik dynamic config
│       └── souin.yml            # HTTP cache config
├── dns/
│   ├── Corefile                 # CoreDNS config
│   └── zones/
│       └── securenexus.net.zone # DNS zone file
├── monitoring/
│   ├── prometheus.yml           # Prometheus config
│   ├── alert_rules.yml          # Alert rules
│   └── dashboards/              # Grafana dashboards
└── secrets/                     # All secrets
```

### Data Volumes

```
/var/lib/docker/volumes/
├── securenexus-fullstack_authentik_db/    # PostgreSQL data
├── securenexus-fullstack_mariadb/         # ERPNext database
├── securenexus-fullstack_redis-cache/     # Session cache
├── securenexus-fullstack_etcd-data/       # DNS records
├── securenexus-fullstack_prometheus-data/ # Metrics
├── securenexus-fullstack_grafana-data/    # Dashboards
├── securenexus-fullstack_loki-data/       # Logs
└── securenexus-fullstack_uptime-kuma/     # Uptime data
```

### Log Files

```
/var/log/
├── securenexus-backup.log   # Backup logs
├── ufw.log                   # Firewall logs
└── syslog                    # System logs

# Container logs via Docker
docker compose logs <service>
```

### Backup Location

```
/backup/securenexus/
├── daily/                    # 7 daily backups
├── weekly/                   # 4 weekly backups
└── monthly/                  # 12 monthly backups
```

## Environment Variables

### Required Variables (.env)

| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAIN` | Primary domain | `securenexus.net` |
| `EMAIL` | Admin email for ACME | `admin@securenexus.net` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GRAFANA_OAUTH_SECRET` | OAuth secret (use secrets file instead) | - |
| `TZ` | Timezone | `America/New_York` |

## Port Reference

### External Ports

| Port | Service | Protocol |
|------|---------|----------|
| 22 | SSH | TCP |
| 25 | SMTP | TCP |
| 53 | DNS | TCP/UDP |
| 80 | HTTP | TCP |
| 143 | IMAP | TCP |
| 443 | HTTPS | TCP |
| 465 | SMTPS | TCP |
| 587 | Submission | TCP |
| 853 | DNS-over-TLS | TCP |
| 993 | IMAPS | TCP |
| 995 | POP3S | TCP |
| 41641 | Tailscale | UDP |

### Internal Ports (Docker network)

| Port | Service |
|------|---------|
| 3000 | Grafana |
| 3100 | Loki |
| 5432 | PostgreSQL |
| 3306 | MariaDB |
| 6379 | Redis |
| 8000 | ERPNext |
| 8080 | Traefik API, cAdvisor |
| 9000 | Authentik, ERPNext WebSocket |
| 9090 | Prometheus |
| 9100 | Node Exporter |
| 9115 | Blackbox Exporter |
| 9153 | CoreDNS metrics |

## Status Page

### System Status

- **Overall status**: [SYSTEM_STATUS_FINAL.md](../SYSTEM_STATUS_FINAL.md)
- **Current status**: [CURRENT_STATUS.md](../CURRENT_STATUS.md)

### Service URLs

| Service | URL | Access |
|---------|-----|--------|
| Uptime Kuma | https://status.securenexus.net | Public |
| Homarr Portal | https://portal.securenexus.net | Public/SSO |
| Authentik SSO | https://sso.securenexus.net | Public |
| ERPNext Main | https://erp.byrne-accounts.org | Public |
| Mailcow | https://mail.securenexus.net | Public |
| Grafana | https://grafana.securenexus.net | VPN Only |
| Prometheus | https://prometheus.securenexus.net | VPN Only |
| Traefik | https://traefik.securenexus.net | VPN Only |
| Portainer | https://portainer.securenexus.net | VPN Only |

## Next Steps

- **[Getting Started](../getting-started/overview.md)**: Initial setup guide
- **[Operations](../operations/overview.md)**: Deployment and maintenance
- **[Troubleshooting](../troubleshooting/overview.md)**: Fix common issues
- **[Monitoring](../monitoring/overview.md)**: Track system health
