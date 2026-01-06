# SecureNexus Full Stack

**Enterprise-Grade Self-Hosted Infrastructure Platform**

A comprehensive, production-ready infrastructure stack providing identity management, monitoring, DNS, mail, cloud services, and dashboard platform with enterprise-grade security including CrowdSec threat protection.

---

## System Status

**Health**: ✅ 100% Operational with Enterprise Threat Protection
**Security Grade**: A+ (CrowdSec Fully Operational + Caddy Hardening)
**Containers**: 81/81 running (53 SecureNexus + 28 Mailcow)
**Prometheus Targets**: 19/19 up (100%)
**Uptime**: 99.9%+
**SSL Certificates**: Valid until January 2026
**Memory Usage**: 7.8GB / 22GB (34% utilization - optimal)
**Disk Usage**: 78GB / 193GB (41% utilization - healthy)

**🚨 CRITICAL UPDATE** (November 29, 2025): CrowdSec threat protection fully restored
- ✅ **100+ malicious IPs actively blocked**
- ✅ **Real-time threat intelligence operational**
- ✅ **Forward authentication protecting all public endpoints**
- ✅ **Caddy bouncer connected** (IP: 172.18.0.38, Type: caddy-cs-bouncer v0.9.2)

---

## Architecture Overview

### Core Infrastructure
- **Caddy** - Modern reverse proxy with HTTP/3 QUIC, automatic SSL, enhanced security headers
- **Authentik** - SSO identity provider with PostgreSQL backend (2025.10.1 - Redis removed)
- **Tailscale** - VPN service for secure admin access to restricted services
- **CrowdSec** - Enterprise threat protection with forward authentication bouncer (FULLY OPERATIONAL)
- **Dashy** - Modern dashboard platform with comprehensive service catalog

### Service Categories

Services are organized into Docker Compose profiles:

#### Core Profile (`core`)
Essential infrastructure services:
- `caddy` - Reverse proxy with HTTP/3 QUIC and automatic SSL
- `souin_redis` - Cache backend for HTTP caching
- `tailscale` - VPN service for secure admin access
- `crowdsec` - Threat analysis engine (LAPI mode)
- `crowdsec_bouncer` - Forward authentication bouncer for Caddy

#### Identity Profile (`identity`)
Authentication services:
- `authentik_db` - PostgreSQL database (primary backend)
- `authentik_server` - Main authentication server (2025.10.1)
- `authentik_worker` - Background task processor

#### Portal Profile (`portal`)
User-facing services:
- `dashy` - Modern service catalog and dashboard platform
- `landing` - System landing page
- `wellknown` - Standard internet services discovery (.well-known endpoints)
- `brand-static` - Brand assets and logos

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

#### Cloud Services Profile (`cloud`)
Self-hosted cloud platform:
- `nextcloud` + `nextcloud-db` - Personal cloud storage with PostgreSQL
- `notesnook-server` - Note synchronization API (custom build)
- `notesnook-identity` - Authentication server (custom build)
- `notesnook-sse` - Real-time event notifications
- `notesnook-monograph` - PDF generation service
- `notesnook-db` - MongoDB replica set (rs0)
- `notesnook-s3` - MinIO file storage for attachments

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
git clone https://git.yourdomain.com/yourusername/securenexus-fullstack.git
cd securenexus-fullstack

# Configure environment
cp .env.example .env
# Edit .env with your domain and email

# Generate secrets
make secrets

# Run preflight checks
make preflight

# Start services incrementally
make up-core          # Core infrastructure (Caddy, Tailscale, CrowdSec)
make up-identity      # Authentication (Authentik)
make up-portal        # User-facing services (Dashy dashboard)
make up-monitoring    # Observability (Prometheus, Grafana, Uptime Kuma)
make up-dns           # DNS services (CoreDNS, etcd)

# Start cloud services
docker compose --profile cloud up -d  # Nextcloud + Notesnook platform

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

# Access dashboard
https://dashboard.yourdomain.com  # Main dashboard (Dashy)

# View status page
https://status.yourdomain.com     # System status monitoring
```

---

## Security Features

### Enterprise-Grade Security (A+ Rating)

**Network Security**:
- UFW firewall (deny-by-default, 13 ports)
- Tailscale VPN for admin services (Grafana, Prometheus)
- **CrowdSec Threat Protection** with forward authentication bouncer
- Rate limiting at multiple layers (CrowdSec, UFW, Caddy)

**Application Security**:
- **Caddy Security**: HTTP/3 QUIC, TLS 1.3, modern security headers
- **CrowdSec Forward Auth**: Real-time IP filtering, CVE protection
- **Authentik SSO** with OIDC (PostgreSQL-only, no Redis)
- **Enhanced Headers**: HSTS, CSP, X-Frame-Options, X-Content-Type-Options
- **No Docker Socket Dependency**: Eliminated security attack vector

**Threat Protection**:
- **Real-time IP Blocking**: Malicious traffic blocked before reaching services
- **CVE Protection**: Defense against Log4j, web exploits, path traversal
- **Community Intelligence**: Global threat intelligence from CrowdSec network
- **Attack Detection**: SQL injection, XSS, brute force, bot detection

**Data Security**:
- **Automated backups** (7 daily / 4 weekly / 12 monthly)
- **Encrypted secrets management** with Docker secrets
- **Multi-database backups** (PostgreSQL, MySQL, MongoDB, etcd)
- **Cloud data backup** (Nextcloud files, Notesnook attachments)

### Security Hardening: 8/8 Measures

**Implemented Hardening**:
- ✅ **CrowdSec Threat Protection**: Enterprise-grade forward authentication
- ✅ Automated backup rotation with 3-tier retention
- ✅ Prometheus retention policy (30 days)
- ✅ Comprehensive alerting (30+ rules, 11 categories)
- ✅ Disaster recovery documentation
- ✅ Multi-layer rate limiting (CrowdSec + UFW + Caddy)
- ✅ Log rotation configured
- ✅ Secrets rotation policy established

---

## Service Access

### Public Services (CrowdSec Protected)
- **Dashboard**: `https://dashboard.yourdomain.com` or `https://dash.yourdomain.com`
- **Landing Page**: `https://yourdomain.com`
- **Status Page**: `https://status.yourdomain.com` (Uptime monitoring)
- **Authentik SSO**: `https://auth.yourdomain.com` or `https://sso.yourdomain.com`

### Cloud Services (OIDC Protected)
- **Nextcloud**: `https://nextcloud.yourdomain.com` (Personal cloud storage)
- **Notesnook Sync**: `https://notes.yourdomain.com` (Note synchronization)
- **Notesnook Auth**: `https://identity.yourdomain.com` (Note authentication)
- **Notesnook Events**: `https://events.yourdomain.com` (Real-time sync)
- **Notesnook Files**: `https://files.yourdomain.com` (Attachment storage)

### VPN-Only Services (Tailscale)
- **Grafana**: `https://grafana.yourdomain.com` (Metrics visualization)
- **Prometheus**: `https://prometheus.yourdomain.com` (Metrics collection)
- **Portainer**: `https://portainer.yourdomain.com` (Container management with SSO)

### Mail Services (Mailcow)
- Webmail: Configured in Mailcow installation
- Ports: 25, 143, 465, 587, 993, 995

---

## Management Commands

### Service Management
```bash
# Start service groups
make up-core          # Essential infrastructure (Caddy, CrowdSec, Tailscale)
make up-identity      # Authentication (Authentik)
make up-portal        # User-facing services (Dashy dashboard)
make up-monitoring    # Observability stack (Prometheus, Grafana)
make up-dns           # DNS services (CoreDNS, etcd)

# Start cloud platform
docker compose --profile cloud up -d  # Nextcloud + Notesnook

# Start everything
make up-all

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
- `caddy-overview.json` - Proxy metrics and routing
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
- Creates A records for Caddy-managed containers
- Updates etcd in real-time
- Runs every 30 seconds

### ACME Integration
Two methods for SSL certificates:

**HTTP-01** (default):
- Automatic via Caddy
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

### Caddy Configuration
- `config/caddy/Caddyfile` - Main configuration (auto-reloads)
- `config/caddy/snippets/` - Reusable configuration snippets
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
- Caddy handles external routing with HTTP/3 QUIC support
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

# Check Caddy configuration
caddy validate --config /etc/caddy/Caddyfile

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
1. Check Caddy logs: `docker compose logs caddy`
2. Verify DNS is propagated: `dig yourdomain.com`
3. Check ACME storage: `docker compose exec caddy ls -la /data/caddy/certificates/`

**VPN access not working**:
1. Verify Tailscale status: `docker compose exec tailscale tailscale status`
2. Check client connection: `./scripts/test-vpn-connection.sh`
3. Review middleware: `config/caddy/snippets/sso_auth.caddy`

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
- **Caddy**: HTTP caching via Souin with HTTP/3 QUIC

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
  # No labels needed - Caddy handles routing via Caddyfile
```

2. Add Caddy route in `config/caddy/Caddyfile`:
```caddyfile
service.{$DOMAIN} {
  import crowdsec_protection
  import sso_auth
  reverse_proxy my-service:8080
}
```

3. Add secrets if needed:
```bash
echo "secret_value" > secrets/my_secret.txt
```

4. Test deployment:
```bash
docker compose up -d my-service
docker compose logs -f my-service
```

### Modifying Caddy Routes

1. Edit `config/caddy/Caddyfile`
2. Restart Caddy: `docker compose restart caddy`
3. Verify: `docker compose logs -f caddy`

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
- [Caddy](https://caddyserver.com/)
- [Authentik](https://goauthentik.io/)
- [CoreDNS](https://coredns.io/)
- [Mailcow](https://mailcow.email/)
- [Tailscale](https://tailscale.com/)
- [CrowdSec](https://www.crowdsec.net/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)

---

**SecureNexus** - Enterprise-Grade Self-Hosted Infrastructure Platform
