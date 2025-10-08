# SecureNexus Full Stack

**Enterprise-Grade Self-Hosted Infrastructure Platform**

A comprehensive, production-ready infrastructure stack providing identity management, monitoring, DNS, mail, and portal services with enterprise-grade security.

---

## System Status

**Health**: ✅ 100% Operational
**Grade**: A+ (Enterprise Security)
**Containers**: 29/29 running
**Prometheus Targets**: 19/19 up
**Uptime**: 99.9%+
**SSL Certificates**: Valid until January 2026

---

## Architecture Overview

### Core Infrastructure
- **Traefik** - Central reverse proxy with automatic SSL (Let's Encrypt), middleware security
- **Authentik** - SSO identity provider with PostgreSQL backend and Redis cache
- **Docker Socket Proxy** - Secure Docker API access for Traefik
- **Tailscale** - VPN service for secure admin access to restricted services
- **CrowdSec** - Intrusion detection and prevention via Traefik bouncer
- **Souin** - HTTP caching layer for Traefik

### Service Categories

Services are organized into Docker Compose profiles:

#### Core Profile (`core`)
Essential infrastructure services:
- `docker-proxy` - Secure Docker socket access
- `traefik` - Reverse proxy and SSL termination
- `souin_redis` - Cache backend for Souin
- `tailscale` - VPN service
- `crowdsec` - Intrusion detection
- `crowdsec_bouncer` - Traefik bouncer integration

#### Identity Profile (`identity`)
Authentication services:
- `authentik_db` - PostgreSQL database
- `redis_cache` - Redis cache for Authentik
- `authentik_server` - Main authentication server
- `authentik_worker` - Background task processor

#### Portal Profile (`portal`)
User-facing services:
- `landing` - Landing page
- `homepage` - Portal dashboard
- `wellknown` - .well-known endpoints
- `brand-static` - Branding assets

#### Monitoring Profile (`monitoring`)
Observability stack:
- `prometheus` - Metrics collection (2GB memory)
- `blackbox` - Uptime monitoring
- `loki` - Log aggregation
- `promtail` - Log shipping
- `grafana` - Metrics visualization (with SSO)
- `cadvisor` - Container metrics
- `node-exporter` - Host metrics
- `uptime-kuma` - Status page

#### DNS Profile (`dns`)
DNS infrastructure:
- `etcd` - Key-value store for dynamic DNS
- `mysql-db` - MySQL backend for CoreDNS
- `coredns` - Authoritative DNS server
- `dns-updater` - Automatic DNS record creation
- `acme_webhook` - DNS-01 ACME challenge handler

#### Mail Services
**Mailcow** - Separate installation in `mail/mailcow/`:
- Full-featured mail server (SMTP, IMAP, POP3)
- Webmail interface (SOGo)
- Spam filtering (Rspamd)
- Antivirus (ClamAV)
- Separate docker-compose stack

---

## Quick Start

### Prerequisites
- Docker and Docker Compose v2+
- Valid domain name with DNS access
- Linux server with 4GB+ RAM
- Ports 80, 443, 25, 53 available

### Initial Setup

```bash
# Clone repository
git clone https://github.com/yourusername/securenexus-fullstack.git
cd securenexus-fullstack

# Configure environment
cp .env.example .env
# Edit .env with your domain and email

# Generate secrets
make secrets

# Run preflight checks
make preflight

# Start services incrementally
make up-core          # Core infrastructure
make up-identity      # Authentication
make up-portal        # User-facing services
make up-monitoring    # Observability
make up-dns           # DNS services

# Or start everything
make up-all
```

### Post-Deployment

```bash
# Verify all services
docker compose ps

# Check logs
make logs

# Run smoke tests
./scripts/smoke-postdeploy.sh

# View status page
https://status.yourdomain.com
```

---

## Security Features

### Multi-Layer Security

**Network Security**:
- UFW firewall (deny-by-default)
- Tailscale VPN for admin services
- CrowdSec intrusion detection
- Rate limiting at multiple layers

**Application Security**:
- Traefik middleware chains (VPN, SSO, CrowdSec)
- Authentik SSO with OIDC
- Secure headers (HSTS, CSP, X-Frame-Options)
- SSL/TLS for all services

**Data Security**:
- Automated backups (7 daily / 4 weekly / 12 monthly)
- Encrypted secrets management
- PostgreSQL and MySQL backups
- etcd snapshots

### Security Grade: A+

**Implemented Hardening**:
- ✅ Automated backup rotation with 3-tier retention
- ✅ Prometheus retention policy (30 days)
- ✅ Comprehensive alerting (30+ rules, 11 categories)
- ✅ Disaster recovery documentation
- ✅ Multi-layer rate limiting
- ✅ Log rotation configured
- ✅ Secrets rotation policy

---

## Service Access

### Public Services
- Landing Page: `https://yourdomain.com`
- Portal: `https://portal.yourdomain.com`
- Status Page: `https://status.yourdomain.com`
- Authentik: `https://auth.yourdomain.com`

### VPN-Only Services (Tailscale)
- Grafana: `https://grafana.yourdomain.com`
- Prometheus: `https://prometheus.yourdomain.com`
- Traefik Dashboard: `https://traefik.yourdomain.com`

### Mail Services (Mailcow)
- Webmail: Configured in Mailcow installation
- Ports: 25, 143, 465, 587, 993, 995

---

## Management Commands

### Service Management
```bash
# Start service groups
make up-core          # Essential infrastructure
make up-identity      # Authentication
make up-portal        # User-facing services
make up-monitoring    # Observability stack
make up-dns           # DNS services
make up-all           # Everything

# Stop all services
make down

# View status
make ps

# Follow logs
make logs

# Restart specific service
make restart S=service_name
```

### Docker Compose Operations
```bash
# Direct service control
docker compose up -d [service]
docker compose down
docker compose logs -f [service]
docker compose restart [service]

# Validate configuration
docker compose config --quiet

# View service dependencies
docker compose config --services
```

### Maintenance Scripts

Located in `scripts/` directory:

**Backup & Recovery**:
- `backup-rotation.sh` - Automated backup with rotation
- `backup-all.sh` - Manual backup of all data
- `setup-automated-backups.sh` - Configure cron automation

**System Setup**:
- `generate-secrets.sh` - Generate all required secrets
- `preflight.sh` - Pre-deployment validation
- `setup-ufw-firewall.sh` - Configure firewall
- `enable-ssh-rate-limiting.sh` - SSH protection

**DNS Management**:
- `dns-sync.sh` - Sync DNS records manually
- `dns-updater.sh` - Automatic DNS updates (runs in container)
- `setup-authoritative-dns.sh` - Configure authoritative DNS

**SSL Certificates**:
- `update-mailcow-certs.sh` - Update Mailcow certificates
- `certbot-auth-hook.sh` - ACME DNS-01 auth hook
- `certbot-cleanup-hook.sh` - ACME cleanup hook

**Authentik Management**:
- `create-authentik-admin.sh` - Create admin user
- `reset-authentik-password.sh` - Reset user password
- `list-authentik-users.sh` - List all users

**Utilities**:
- `smoke-postdeploy.sh` - Post-deployment tests
- `cleanup-docker.sh` - Clean unused Docker resources
- `test-vpn-connection.sh` - Test Tailscale connectivity

---

## Monitoring & Alerting

### Prometheus Metrics
- 19 targets monitored
- 30-day retention policy
- 2GB memory allocation
- Custom exporters for all services

### Alert Categories (30+ Rules)
1. Container health and restarts
2. Service availability
3. SSL certificate expiration
4. High CPU/memory usage
5. Disk space warnings
6. Authentik failures
7. DNS errors
8. Prometheus health
9. Security events (CrowdSec, SSH)
10. Mail service health
11. Backup status

### Grafana Dashboards
Pre-configured dashboards:
- `traefik-overview.json` - Proxy metrics and routing
- `uptime-blackbox.json` - Service availability

---

## Backup & Recovery

### Automated Backups

**Status**: ✅ Fully Operational

**Schedule**:
- Daily: 2:00 AM (7-day retention)
- Weekly: Sunday (4-week retention)
- Monthly: 1st of month (12-month retention)

**Location**: `/backup/securenexus/{daily,weekly,monthly}/`

**What's Backed Up**:
- PostgreSQL database (Authentik)
- MySQL database (CoreDNS)
- etcd snapshots (dynamic DNS)
- Grafana dashboards
- Prometheus metrics data
- Loki logs
- Uptime Kuma data
- Configuration files
- Secrets (encrypted)
- SSL certificates

**Backup Size**: ~352MB per full backup

### Backup Commands

```bash
# View backups
ls -lh /backup/securenexus/{daily,weekly,monthly}/

# Manual backup
sudo ./scripts/backup-rotation.sh

# View backup log
tail -f /var/log/securenexus-backup.log

# Check cron schedule
crontab -l | grep backup
```

### Recovery

See `docs/DISASTER_RECOVERY.md` for detailed procedures.

Quick recovery:
```bash
# Restore PostgreSQL
docker compose exec -T authentik_db psql -U authentik authentik < backup.sql

# Restore etcd
docker compose exec etcd etcdctl snapshot restore backup.db

# Restore MySQL
docker compose exec -T mysql-db mysql -u coredns -pPASSWORD coredns < backup.sql

# Restore volumes
docker run --rm -v volume:/data -v /backup:/backup alpine tar -xzf /backup/data.tar.gz -C /data
```

---

## DNS Architecture

### CoreDNS with Dual Backend

**File Backend**: Static zone records
- NS records
- SOA records
- Static A records
- Location: `dns/zones/securenexus.net.zone`

**etcd Backend**: Dynamic records
- Auto-created from Docker containers
- ACME challenge records
- Dynamic A records
- Path: `/coredns`

### DNS Services
- Port 53 (TCP/UDP) - Standard DNS
- Port 853 (TCP) - DNS-over-TLS
- Port 9153 - Metrics endpoint

### DNS Updater
Automatic DNS record creation:
- Watches Docker events
- Creates A records for Traefik-managed containers
- Updates etcd in real-time
- Runs every 30 seconds

### ACME Integration
Two methods for SSL certificates:

**HTTP-01** (default):
- Automatic via Traefik
- Requires public DNS

**DNS-01** (optional):
- Python Flask webhook
- Updates etcd TXT records
- Allows wildcard certificates

---

## Configuration Files

### Core Configuration
- `compose.yml` - Service definitions with profiles
- `.env` - Domain and environment variables
- `Makefile` - Deployment commands

### Traefik Configuration
- `config/traefik.yml` - Static config (requires restart)
- `config/dynamic/traefik_dynamic.yml` - Dynamic config (auto-reload)
- `config/dynamic/souin.yml` - HTTP cache configuration

### DNS Configuration
- `dns/Corefile` - CoreDNS configuration
- `dns/zones/securenexus.net.zone` - Zone file
- `dns/mysql-init/` - MySQL schema for CoreDNS

### Monitoring Configuration
- `monitoring/prometheus.yml` - Metrics collection
- `monitoring/promtail.yml` - Log shipping
- `monitoring/alert_rules.yml` - Alert definitions
- `monitoring/dashboards/` - Grafana dashboards

### CrowdSec Configuration
- `crowdsec/config/config.yaml` - Main config
- `crowdsec/config/acquis.yaml` - LAPI-only mode
- `crowdsec/data/` - Security patterns and databases

### Secrets
- `secrets/` - All service credentials (generated by `make secrets`)
- Never commit to version control
- Use `openssl rand -base64 32` for passwords

---

## Documentation

All documentation is in the `docs/` directory:

### Security & Hardening
- `HARDENING_COMPLETE.md` - Security measures summary
- `SECURITY_HARDENING_GUIDE.md` - Implementation guide
- `DISASTER_RECOVERY.md` - Recovery procedures (400+ lines)
- `FIREWALL.md` - Firewall configuration
- `FIREWALL_ANALYSIS.md` - Security analysis

### System Status
- `SYSTEM_DIAGNOSTIC_REPORT_2025-10-07.md` - Full diagnostic
- `SYSTEM_STATUS_FINAL.md` - Production readiness
- `CURRENT_STATUS.md` - Ongoing status tracking
- `OPTIMIZATION_CHANGES_2025-10-07.md` - Performance changes

### Setup Guides
- `DNS_SETUP_GUIDE.md` - DNS configuration
- `VPN_SETUP.md` - Tailscale VPN setup
- `AUTHENTIK_BRANDING_GUIDE.md` - Authentik customization
- `CERTBOT_GUIDE.md` - SSL certificate management
- `UPTIME_KUMA_SETUP.md` - Status page setup

---

## Network Architecture

### Docker Networks
- `proxy` - Main network for all services
- Traefik handles external routing
- Internal service-to-service communication via service names

### Firewall Configuration
UFW with deny-by-default policy:

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

---

## Troubleshooting

### Health Checks

```bash
# Check container status
docker compose ps

# View service logs
docker compose logs -f [service]

# Check Traefik routing
curl -H "Host: traefik.yourdomain.com" http://localhost/api/rawdata

# Test DNS resolution
dig @localhost yourdomain.com

# Verify SSL certificates
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com

# Check Tailscale VPN
tailscale status

# Monitor resource usage
docker stats
```

### Common Issues

**Service won't start**:
1. Check logs: `docker compose logs [service]`
2. Verify secrets exist: `ls -la secrets/`
3. Validate config: `docker compose config --quiet`

**SSL certificate issues**:
1. Check Traefik logs: `docker compose logs traefik`
2. Verify DNS is propagated: `dig yourdomain.com`
3. Check ACME storage: `ls -la config/acme.json`

**VPN access not working**:
1. Verify Tailscale status: `docker compose exec tailscale tailscale status`
2. Check client connection: `./scripts/test-vpn-connection.sh`
3. Review middleware: `config/dynamic/traefik_dynamic.yml`

**DNS not resolving**:
1. Check CoreDNS logs: `docker compose logs coredns`
2. Verify etcd records: `docker compose exec etcd etcdctl get --prefix /coredns`
3. Test zone file: `docker compose exec coredns cat /etc/coredns/zones/securenexus.net.zone`

---

## Performance Tuning

### Resource Allocation
- **Prometheus**: 2GB memory (1GB minimum)
- **PostgreSQL**: Shared buffers optimized
- **Redis**: Memory limit set per service
- **Traefik**: HTTP caching via Souin

### Caching Strategy
Souin HTTP cache:
- 60s TTL with 30s stale serving
- Excludes: ACME, OIDC, metrics, APIs
- Regex-based exclusion patterns

### Monitoring Resources
```bash
# Container resource usage
docker stats

# Disk usage
df -h
docker system df

# Memory usage
free -h
```

---

## Development Workflow

### Adding a New Service

1. Define service in `compose.yml`:
```yaml
my-service:
  image: my-image:latest
  profiles: ["portal"]
  networks: [proxy]
  labels:
    - traefik.enable=true
    - traefik.http.routers.myservice.rule=Host(`service.${DOMAIN}`)
    - traefik.http.routers.myservice.entrypoints=websecure
    - traefik.http.routers.myservice.tls.certresolver=le
    - traefik.http.routers.myservice.middlewares=sso@file
```

2. Add secrets if needed:
```bash
echo "secret_value" > secrets/my_secret.txt
```

3. Test deployment:
```bash
docker compose up -d my-service
docker compose logs -f my-service
```

### Modifying Traefik Routes

1. Edit `config/dynamic/traefik_dynamic.yml`
2. Traefik auto-reloads (no restart needed)
3. Verify: `curl http://localhost:8080/api/rawdata`

### Testing Changes

```bash
# Validate compose file
docker compose config --quiet

# Test single service
docker compose up -d --no-deps [service]

# Run smoke tests
./scripts/smoke-postdeploy.sh

# Check metrics
curl http://localhost:9090/metrics
```

---

## Migration Notes

### Recent Migrations

**Headscale → Tailscale** (October 2025):
- Self-hosted VPN replaced with Tailscale cloud
- Improved reliability and mobile support
- Same security model (admin-vpn middleware)

**Stalwart → Mailcow** (October 2025):
- Comprehensive mail server solution
- Webmail, spam filtering, antivirus
- Separate docker-compose installation

**PowerDNS → CoreDNS** (October 2025):
- Lighter DNS server
- Dual backend (etcd + file)
- Better Docker integration

---

## Support & Resources

### Documentation
- **docs/**: Complete documentation library
- **CLAUDE.md**: AI assistant instructions
- **README.md**: This file

### Scripts
- **scripts/**: 30+ utility scripts
- All scripts documented with inline comments
- Run with `./scripts/script-name.sh`

### Logs
- **Service logs**: `docker compose logs [service]`
- **Backup logs**: `/var/log/securenexus-backup.log`
- **System logs**: `journalctl -u docker`

### Monitoring
- **Prometheus**: Metrics and alerting
- **Grafana**: Visualization
- **Uptime Kuma**: Status page
- **Loki**: Log aggregation

---

## License

MIT License - See LICENSE file for details

---

## Credits

Built with:
- [Traefik](https://traefik.io/)
- [Authentik](https://goauthentik.io/)
- [CoreDNS](https://coredns.io/)
- [Mailcow](https://mailcow.email/)
- [Tailscale](https://tailscale.com/)
- [CrowdSec](https://www.crowdsec.net/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)

---

**SecureNexus** - Enterprise-Grade Self-Hosted Infrastructure Platform
