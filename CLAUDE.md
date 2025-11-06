# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SecureNexus Full Stack is a comprehensive self-hosted infrastructure stack providing identity management, monitoring, DNS, mail, and portal services. The system is built around Docker Compose with Traefik as the central reverse proxy handling SSL termination, routing, and security.

### Current System Status (Updated November 6, 2025)

**System Health**: 100% operational
- **Containers**: 35+ running (includes multi-tenant ERP instances)
- **Prometheus Targets**: 19/19 up
- **Security Grade**: A+ (Enterprise)
- **Uptime**: 99.9%+
- **Critical Alerts**: 0 firing
- **SSL Certificates**: Valid until January 2026

**Recent Major Updates** (November 2025):
- ✅ **Authentik upgraded to 2025.10.1** (Redis completely removed, PostgreSQL-only)
- ✅ Multi-tenant ERPNext infrastructure deployed (Byrne Accounting, Dickinson Supplies)
- ✅ Portainer container management added
- ✅ One-command client provisioning automation
- ✅ Client portal and corporate website deployments
- ✅ PostgreSQL and Redis exporters for enhanced monitoring
- ✅ Comprehensive SSO integration across all client services

**Recent Optimizations** (October 2025):
- ✅ Prometheus memory increased to 2GB (prevents OOM under load)
- ✅ Grafana protected with `admin-vpn` middleware (Tailscale VPN only)
- ✅ Uptime Kuma granted Docker socket access for container monitoring
- ✅ CrowdSec configured in LAPI-only mode
- ✅ Removed unnecessary ACME certificate requests for `.ts.net` domains
- ✅ Firewall optimized (added POP3S, removed duplicate SSH rule)

**Security Hardening**: All 7 recommended measures implemented
- ✅ Automated backup rotation (7 daily / 4 weekly / 12 monthly)
- ✅ Prometheus retention policy (30 days)
- ✅ Comprehensive alerting (30+ rules across 11 categories)
- ✅ Disaster recovery documentation
- ✅ Multi-layer rate limiting (CrowdSec, UFW, Traefik)
- ✅ Log rotation configured
- ✅ Secrets rotation policy established

**Recent Migrations**:
- ✅ Headscale → Tailscale (improved VPN reliability)
- ✅ Stalwart → Mailcow (comprehensive mail solution)
- ✅ PowerDNS → CoreDNS (lighter, better Docker integration)
- ✅ Authentik Redis caching → PostgreSQL caching (2025.10.1)

**Key Documentation**: All guides available in `docs/` directory

## Architecture

### Core Infrastructure
- **Traefik**: Central reverse proxy with automatic SSL via Let's Encrypt, middleware-based security
- **Authentik**: SSO identity provider with PostgreSQL backend (v2025.10.1 - Redis removed, all caching in PostgreSQL)
- **Docker Socket Proxy**: Secure Docker API access for Traefik
- **Tailscale**: VPN service for secure admin access to restricted services
- **CrowdSec**: Intrusion detection and prevention via Traefik bouncer
- **Portainer**: Web-based Docker container management interface

### Service Categories (Docker Compose Profiles)
Services are organized into Docker Compose profiles for staged deployment:
- `core`: Essential infrastructure (Traefik, Docker proxy, Tailscale, CrowdSec, Souin)
- `identity`: Authentication services (Authentik, PostgreSQL, Redis)
- `portal`: User-facing services (landing page, homarr portal, wellknown, branding)
- `monitoring`: Observability stack (Prometheus, Grafana, Loki, Promtail, Uptime Kuma, exporters)
- `dns`: CoreDNS with etcd backend, MySQL plugin, dynamic DNS updater, ACME webhook
- `mail`: **Mailcow** (separate installation in `mail/mailcow/`) - full mail server with SMTP, IMAP, POP3, webmail (SOGo), spam filtering (Rspamd), antivirus (ClamAV)

**Note**: Most services are started explicitly via Makefile commands (not via `--profile` flags). See Makefile for exact service dependencies per deployment stage.

### Security Model
- Services protected by middleware chains:
  - `admin-vpn@file`: Tailscale VPN-only access (Grafana, Prometheus, Traefik dashboard)
  - `sso@file`: Authentik OIDC authentication
  - `crowdsec-fa@file`: CrowdSec bouncer protection
  - `secure-headers@file`: Security headers (HSTS, CSP, X-Frame-Options)
- Mail services handled by Mailcow (separate installation with own security policies)
- All secrets managed via Docker secrets from `./secrets/` directory
- SSL certificates automated via ACME HTTP-01 or DNS-01 challenge (DNS-01 uses etcd backend via ACME webhook)
- UFW firewall with deny-by-default policy (13 ports: 22, 25, 53, 80, 143, 443, 465, 587, 853, 993, 995, 41641/udp)

## Development Commands

### Environment Setup
```bash
# Generate all required secrets
make secrets

# Validate configuration and environment
make preflight

# Validate Docker Compose configuration
docker compose config --quiet

# Check which services are defined for each profile
docker compose --profile core config --services
docker compose --profile identity config --services
docker compose --profile portal config --services
docker compose --profile monitoring config --services
docker compose --profile dns config --services
docker compose --profile mail config --services
```

### Service Management
```bash
# Start service groups incrementally
make up-core          # docker-proxy, traefik, souin_redis, tailscale, crowdsec, crowdsec_bouncer
make up-identity      # authentik_db, redis_cache, authentik_server, authentik_worker
make up-portal        # landing, homarr, wellknown, brand-static
make up-monitoring    # prometheus, blackbox, loki, promtail, grafana, cadvisor, node-exporter, uptime-kuma
make up-dns           # etcd, mysql-db, coredns, dns-updater, acme_webhook
# Note: Mail is handled by Mailcow (separate installation in mail/mailcow/)

# Start everything
make up-all

# Stop all services
make down

# View service status
make ps

# Follow logs for all services
make logs

# Restart specific service
make restart S=service_name
```

### Docker Compose Operations
```bash
# Direct Docker Compose usage
docker compose up -d [service...]
docker compose down
docker compose logs -f [service]
docker compose restart [service]

# Run a single service with dependencies
docker compose up -d --no-deps [service]

# Check service dependencies
docker compose config --services | sort

# Validate compose file syntax
docker compose config --quiet && echo "Configuration valid" || echo "Configuration error"

# View effective configuration for a service
docker compose config --services | xargs -I {} docker compose config --format json | jq '.services.{}'
```

### Verification
```bash
# Post-deployment smoke tests
./scripts/smoke-postdeploy.sh

# DNS record synchronization (manual trigger)
./scripts/dns-sync.sh
```

## Key Configuration Files

- `compose.yml`: Complete service definitions with profiles, networks, and secrets
- `config/traefik.yml`: Traefik static configuration
- `config/dynamic/traefik_dynamic.yml`: Middlewares, routes, and TLS configuration
- `config/dynamic/souin.yml`: HTTP cache configuration for Traefik
- `dns/Corefile`: CoreDNS configuration (etcd + file backends)
- `dns/zones/securenexus.net.zone`: DNS zone file for authoritative records
- `dns/mysql-init/`: MySQL schema initialization for CoreDNS mysql plugin
- `monitoring/`: Prometheus, Grafana, and alerting configurations
- `monitoring/alert_rules.yml`: Comprehensive alert rules (30+ rules across 11 categories)
- `scripts/`: Utility scripts for setup, validation, and maintenance
- `docs/`: All documentation files (system guides, security hardening, disaster recovery)
- `secrets/`: All service credentials (generated by `make secrets`)
- `.env`: Domain and environment variables (copy from `.env.example`)

## Documentation Structure

All documentation is organized in the `docs/` directory for easy reference:

### Security & Hardening
- `docs/HARDENING_COMPLETE.md`: Summary of all implemented security measures (A+ grade)
- `docs/SECURITY_HARDENING_GUIDE.md`: Complete implementation guide for security hardening
- `docs/DISASTER_RECOVERY.md`: Comprehensive disaster recovery procedures (400+ lines)
- `docs/FIREWALL.md`: Firewall configuration and analysis
- `docs/FIREWALL_ANALYSIS.md`: Security analysis and recommendations

### System Status & Diagnostics
- `docs/SYSTEM_DIAGNOSTIC_REPORT_2025-10-07.md`: Complete system diagnostic with health checks
- `docs/SYSTEM_STATUS_FINAL.md`: Production readiness verification
- `docs/CURRENT_STATUS.md`: Ongoing status tracking
- `docs/OPTIMIZATION_CHANGES_2025-10-07.md`: Performance optimization changes

### Setup & Configuration Guides
- `docs/DNS_SETUP_GUIDE.md`: DNS configuration and management
- `docs/VPN_SETUP.md`: Tailscale VPN setup and access
- `docs/AUTHENTIK_BRANDING_GUIDE.md`: Authentik customization
- `docs/CERTBOT_GUIDE.md`: SSL certificate management
- `docs/COREDNS_MIGRATION.md`: PowerDNS to CoreDNS migration notes

### Quick Access Commands
```bash
# View all documentation
ls docs/

# View security hardening summary
cat docs/HARDENING_COMPLETE.md

# View disaster recovery procedures
cat docs/DISASTER_RECOVERY.md

# View latest system diagnostic
cat docs/SYSTEM_DIAGNOSTIC_REPORT_2025-10-07.md
```

## Environment Configuration

Required `.env` variables (copy from `.env.example`):
- `DOMAIN`: Your primary domain (e.g., example.com)
- `EMAIL`: Admin email for ACME certificates
- `GRAFANA_OAUTH_SECRET`: Generate if using Grafana SSO

## Service Configuration Patterns

### Tailscale VPN
- Tailscale container runs in host network mode for VPN access
- Auth key stored in `secrets/tailscale_authkey.txt`
- Provides secure access to admin services (Grafana, Prometheus, Traefik dashboard)
- Configured via environment variables in compose.yml

### Mailcow Email Server
- Separate installation in `mail/mailcow/` directory
- Has its own docker-compose.yml and configuration
- Provides: SMTP, IMAP, POP3, webmail (SOGo), spam filtering (Rspamd), antivirus (ClamAV)
- Ports: 25, 143, 465, 587, 993, 995, 4190
- SSL certificates: Use `./scripts/update-mailcow-certs.sh` to sync from Traefik ACME storage
- Webmail access: Configured in Mailcow installation
- Security: Built-in spam filtering, rate limiting, and authentication

### Monitoring Stack
- `monitoring/dashboards/`: Pre-configured Grafana dashboards
  - `traefik-overview.json`: Proxy metrics and routing
  - `uptime-blackbox.json`: Service availability monitoring
- `monitoring/prometheus.yml`: Metrics collection configuration (includes CoreDNS scraping)
- `monitoring/promtail.yml`: Log shipping to Loki
- `monitoring/alert_rules.yml`: Comprehensive alerting (30+ rules across 11 categories)
- `monitoring/grafana/provisioning/`: Grafana datasources and dashboard provisioning
- **Grafana Access**: VPN-only via `admin-vpn` middleware (requires Tailscale connection)
- **Prometheus Resources**: 2GB memory allocation (increased from 1GB for heavy workloads)

## Network Architecture

All services run on the `proxy` network with Traefik handling external traffic routing. Services communicate internally using service names as hostnames. External access is controlled through Traefik labels defining routing rules, middlewares, and security policies.

## Secret Management

Secrets are stored in `./secrets/` as individual files and mounted into containers via Docker secrets. Never commit secrets to version control. Use `make secrets` to generate all required credentials.

### Secret Management Guidelines
- Never commit files in `secrets/` directory
- Authentik secret key must remain constant (breaks sessions if changed)
- Use strong passwords: `openssl rand -base64 32`
- Rotate non-critical secrets periodically

## Middleware Security Layers

- `admin-vpn@file`: Restricts access to Tailscale VPN network IPs
- `sso@file`: Requires Authentik OIDC authentication
- `crowdsec-fa@file`: CrowdSec fail2ban protection
- `secure-headers@file`: Security headers (HSTS, CSP, etc.)

### Network Isolation Security
- Admin services use `admin-vpn` middleware (Tailscale VPN only)
- Mail security handled by Mailcow's built-in policies and firewall rules
- CrowdSec provides intrusion detection via `crowdsec-fa` middleware

## DNS and SSL Integration

CoreDNS provides authoritative DNS with dual backend support:
- **etcd backend**: Dynamic records created by `dns-updater` service watching Docker events
- **file backend**: Static zone records from `dns/zones/securenexus.net.zone`

SSL certificates via ACME:
- **HTTP-01 challenge**: Default method (requires external DNS propagation)
- **DNS-01 challenge**: Via `acme_webhook` service updating etcd TXT records

The `dns-updater` service automatically creates A records for Traefik-managed containers with appropriate labels.

## Testing & Validation

### Pre-deployment Validation
```bash
# Run comprehensive preflight checks
make preflight

# Validate Docker Compose syntax
docker compose config --quiet

# Check required secrets exist
for secret in $(docker compose config | grep -oP 'secrets/\K[^:]+' | sort -u); do
  [ -f "secrets/$secret" ] && echo "✓ $secret" || echo "✗ $secret missing"
done
```

### Service Testing
```bash
# Test individual service deployment
docker compose up -d [service] && docker compose logs [service] | tail -20

# Health check status for all services
docker compose ps --format json | jq -r '.[] | "\(.Service): \(.Health)"'

# Test service connectivity
docker compose exec [service] ping -c 1 [target_service]
```

## Troubleshooting Commands

```bash
# Check service health and dependencies
docker compose ps
docker compose logs [service_name]

# Validate configuration before deployment
make preflight

# Monitor specific service logs in real-time
docker compose logs -f [service_name]

# Check Traefik routing and middleware status
curl -H "Host: traefik.${DOMAIN}" http://localhost/api/rawdata

# Test DNS resolution
dig @localhost [domain]

# Verify secret generation
ls -la secrets/

# Debug service networking
docker compose exec [service] nslookup [target_service]
docker network inspect securenexus-fullstack_proxy

# Check service resource usage
docker stats --no-stream $(docker compose ps -q)
```

## Common Development Workflows

### Adding a New Service
1. Define service in `compose.yml` with appropriate profile
2. Add Traefik labels for routing and middleware
3. Generate secrets if needed: `echo "secret_value" > secrets/new_secret.txt`
4. Test with: `docker compose up -d new_service`

### Modifying Traefik Routes
1. Edit `config/dynamic/traefik_dynamic.yml`
2. Traefik auto-reloads dynamic config (no restart needed)
3. Verify with: `curl -H "Host: traefik.${DOMAIN}" http://localhost/api/rawdata`

### Debugging Service Connectivity
1. Check service logs: `docker compose logs -f service_name`
2. Verify network membership: `docker network inspect securenexus-fullstack_proxy`
3. Test internal DNS: `docker exec service_name nslookup other_service`

## Monitoring Access

### Default Service URLs (replace example.com with your domain)
- Grafana: `https://grafana.example.com` (VPN-only access via Tailscale)
- Prometheus: `https://prometheus.example.com` (VPN-only access via Tailscale)
- Traefik Dashboard: `https://traefik.example.com` (VPN-only access via Tailscale)
- Uptime Kuma: `https://status.example.com` (public with CrowdSec protection)
- Homarr Portal: `https://portal.example.com` (public, customizable dashboard with visual editor)
- Mailcow Webmail: Configured separately in Mailcow installation

### Key Metrics to Monitor
- Traefik request rates and response times
- DNS query performance and resolution success
- Certificate expiration dates
- Tailscale VPN connectivity
- Mailcow mail queue and delivery status

## Performance Tuning

### HTTP Caching (Souin)
- Configuration: `config/dynamic/souin.yml`
- Caches responses based on TTL headers
- Automatic cache invalidation

### Resource Monitoring
- Use cAdvisor for container resource usage
- Monitor disk space for log volumes
- Watch PostgreSQL connection counts

## Important Notes

- **VPN Service**: Project uses Tailscale for secure admin access to monitoring and management interfaces
- **Mail Server**: Mailcow installed separately in `mail/mailcow/` directory with its own docker-compose stack
- **Service Dependencies**: Start services in profile order (core → identity → others) for proper initialization
- **Secret Rotation**: Authentik secret key (64 hex chars) should not be rotated post-installation
- **Cache Layer**: Souin provides HTTP caching through Traefik for improved performance

## Secret Generation Patterns

The `./scripts/generate-secrets.sh` script supports multiple generation modes:
- `hex:N` - N bytes as hexadecimal (e.g., API keys)
- `b64:N` - N bytes as base64 (e.g., passwords)
- `plain:VALUE` - Write literal value (e.g., usernames)
- `empty` - Create empty file (e.g., for manual auth keys)

## Service Health Monitoring

All critical services include Docker health checks:
- **Automatic recovery**: Docker restarts unhealthy containers
- **Dependency awareness**: Use `docker compose ps` to check service status
- **Monitoring integration**: Health status exposed to Prometheus

## Stack-Specific Notes

### Traefik Configuration
- **Static config**: `config/traefik.yml` (requires restart)
- **Dynamic config**: `config/dynamic/traefik_dynamic.yml` (auto-reloads)
- **Plugin system**: Souin cache and rewritebody plugins enabled
- **ACME email**: Configured via `${EMAIL}` environment variable from `.env` file (compose.yml:70)

### DNS Architecture Notes
- **CoreDNS** runs on ports 53 (TCP/UDP), 853 (DNS-over-TLS), 8080 (health), 9153 (metrics)
- **etcd** stores dynamic DNS records at path `/coredns`
- **MySQL** backend available for mysql plugin (optional, not currently active)
- **Zone file + etcd**: Both active simultaneously (file provides NS/SOA, etcd provides dynamic A records)
- **ACME webhook**: Python Flask app updates etcd for DNS-01 ACME challenges

### Caching Strategy
- Souin excludes real-time endpoints (ACME, OIDC, metrics, APIs)
- 60s TTL with 30s stale serving for performance
- Regex-based exclusion patterns prevent auth/security bypasses

## Backup & Recovery

### Automated Backup System ✅

**Status**: Fully operational with automated daily backups and rotation

**Configuration**:
- **Schedule**: Daily at 2:00 AM (via cron)
- **Retention Policy**:
  - Daily backups: 7 days (Monday-Saturday)
  - Weekly backups: 4 weeks (Sunday backups)
  - Monthly backups: 12 months (1st of month)
- **Backup Size**: ~352MB per full backup
- **Location**: `/backup/securenexus/{daily,weekly,monthly}/`
- **Logging**: `/var/log/securenexus-backup.log`

**What's Backed Up**:
- PostgreSQL database (Authentik users & config) - 5.6M
- MySQL database (CoreDNS records)
- etcd snapshot (dynamic DNS records) - 40K
- Grafana dashboards and settings - 76K
- Prometheus metrics data - 315M
- Loki log data - 30M
- Uptime Kuma data - 12K
- Configuration files
- Secrets (encrypted)
- SSL certificates

**Backup Scripts**:
- `scripts/backup-rotation.sh` - Main backup script with 3-tier rotation logic
- `scripts/backup-all.sh` - Core backup functionality (called by rotation script)
- `scripts/setup-automated-backups.sh` - Configure automated backups via cron

### Backup Management Commands

```bash
# View backup inventory
ls -lh /backup/securenexus/{daily,weekly,monthly}/

# View latest backup manifest
cat /backup/securenexus/daily/*/MANIFEST.txt

# Check backup log
tail -f /var/log/securenexus-backup.log

# Run manual backup (if needed)
sudo ./scripts/backup-rotation.sh

# View cron schedule
crontab -l | grep backup

# Test backup without scheduling
./scripts/backup-all.sh
```

## Utility Scripts

The `scripts/` directory contains 30+ utility scripts for system management, deployment, and maintenance. All scripts are executable and documented with inline comments.

### Backup & Recovery Scripts
- `backup-rotation.sh` - Automated backup with 3-tier rotation (daily/weekly/monthly)
- `backup-all.sh` - Manual backup of all data (databases, volumes, config, secrets)
- `setup-automated-backups.sh` - Configure cron automation for daily backups

### System Setup & Configuration
- `generate-secrets.sh` - Generate all required secrets (hex, base64, plain text modes)
- `preflight.sh` - Pre-deployment validation and sanity checks
- `setup-ufw-firewall.sh` - Configure UFW firewall with deny-by-default policy
- `setup-firewall.sh` - Alternative firewall setup script
- `enable-ssh-rate-limiting.sh` - Enable SSH brute-force protection
- `setup-swap.sh` - Configure swap space for systems with limited RAM

### DNS Management
- `dns-sync.sh` - Manually sync DNS records to etcd
- `dns-updater.sh` - Automatic DNS updates (runs in container, not directly)
- `setup-authoritative-dns.sh` - Configure CoreDNS as authoritative nameserver
- `setup-dns.sh` - General DNS setup script

### SSL Certificate Management
- `update-mailcow-certs.sh` - Sync SSL certificates from Traefik to Mailcow
- `certbot-auth-hook.sh` - ACME DNS-01 authentication hook for certbot
- `certbot-cleanup-hook.sh` - ACME DNS-01 cleanup hook for certbot
- `fix-certbot-renewal.sh` - Troubleshoot certbot renewal issues
- `setup-certbot-renewal.sh` - Configure certbot automatic renewal
- `update-certbot-renewal.sh` - Update certbot renewal configuration
- `recreate-certbot-config.sh` - Recreate certbot configuration from scratch
- `run-certbot.sh` - Run certbot manually for certificate generation
- `import-certbot.sh` - Import existing certbot certificates
- `import-lego-certs.sh` - Import certificates from lego ACME client
- `lego-dns-helper.sh` - Helper script for lego DNS challenges

### Authentik Management
- `create-authentik-admin.sh` - Create new Authentik admin user
- `reset-authentik-password.sh` - Reset user password in Authentik
- `list-authentik-users.sh` - List all Authentik users
- `setup-grafana-oauth.sh` - Configure Grafana OAuth with Authentik

### Testing & Validation
- `smoke-postdeploy.sh` - Post-deployment smoke tests
- `test-vpn-connection.sh` - Test Tailscale VPN connectivity

### Maintenance & Cleanup
- `cleanup-docker.sh` - Clean unused Docker resources (images, containers, volumes)
- `init-crowdsec.sh` - Initialize CrowdSec configuration

### DNS Record Management (Legacy)
- `fix-ns-records.sh` - Fix NS records (from PowerDNS migration)

### Quick Recovery Procedures

For detailed recovery procedures, see `docs/DISASTER_RECOVERY.md`

```bash
# Restore PostgreSQL (Authentik)
docker compose exec -T authentik_db psql -U authentik authentik < /backup/securenexus/daily/*/databases/authentik.sql

# Restore etcd (DNS records)
docker compose cp /backup/securenexus/daily/*/databases/etcd.db etcd:/tmp/etcd_backup.db
docker compose exec etcd etcdctl snapshot restore /tmp/etcd_backup.db

# Restore MySQL (CoreDNS)
docker compose exec -T mysql-db mysql -u coredns -p$(cat secrets/mysql_password) coredns < /backup/securenexus/daily/*/databases/mysql.sql

# Restore Grafana dashboards
docker run --rm -v securenexus-fullstack_grafana-data:/data -v /backup/securenexus/daily/*/volumes:/backup alpine tar -xzf /backup/grafana.tar.gz -C /data

# Restore configuration files
cp -r /backup/securenexus/daily/*/config/* .
```

### Backup Best Practices

1. **Monitor backup logs regularly**: `tail -f /var/log/securenexus-backup.log`
2. **Test restoration monthly**: Verify backups are valid and restorable
3. **Off-site replication**: Copy backups to remote storage (encrypted)
4. **Before major changes**: Always run manual backup first
5. **Secrets encryption**: Encrypt `secrets.tar.gz` before off-site storage

## Recent System Optimizations (October 2025)

### Performance Improvements

1. **Prometheus Memory Allocation** (compose.yml:324-329)
   - Increased from 1GB → 2GB memory limit
   - Prevents OOM (Out of Memory) under heavy load
   - Current usage: ~12% (excellent headroom)
   - Reservation also increased to 1GB minimum

2. **Grafana VPN Protection** (compose.yml:426)
   - Added `admin-vpn@file` middleware
   - Requires Tailscale VPN connection
   - Prevents unauthorized access to metrics visualization
   - Aligns with security best practices

3. **Uptime Kuma Docker Access** (compose.yml:436)
   - Granted read-only Docker socket access
   - Enables container health monitoring
   - Allows status page to show Docker container status

4. **ACME Certificate Optimization**
   - Removed unnecessary certificate requests for `.ts.net` Tailscale domains
   - Reduces Let's Encrypt rate limiting exposure
   - Cleaner Traefik logs
   - Faster certificate renewal cycles

5. **CrowdSec LAPI-Only Mode** (crowdsec/config/acquis.yaml)
   - Configured for Local API (LAPI) mode
   - Uses journalctl dummy source (no-op datasource)
   - Reduces log processing overhead
   - Still provides full bouncer protection

### Firewall Optimization

**Changes Applied**:
- Added POP3S port (995) for secure email access
- Removed duplicate SSH rule
- Total ports: 13 (26 rules with IPv6)
- Status: Perfect alignment with listening services

### Alert Rules Enhancement

**New Alert Categories** (monitoring/alert_rules.yml):
- Authentik failures and high login attempts
- DNS service health (CoreDNS, etcd)
- Prometheus memory usage and target health
- Security events (CrowdSec, SSH brute-force)
- Mail service health (Mailcow)
- Backup status monitoring
- Total: 30+ rules across 11 categories

## Known Issues and Migration Notes

### PowerDNS → CoreDNS Migration
The system has been migrated from PowerDNS to CoreDNS with etcd backend:
- **Previous**: PowerDNS with MySQL backend and pdns-admin interface
- **Current**: CoreDNS with dual backend (etcd for dynamic records + zone files for static records)
- **Impact**: Some legacy PowerDNS configuration files remain in `dns/` directory but are no longer active

### CoreDNS Dual Backend Configuration
CoreDNS is configured with **both** etcd and file backends simultaneously:
- **File plugin**: Loads `dns/zones/securenexus.net.zone` for NS, SOA, and static A records
- **etcd plugin**: Provides dynamic A records created by `dns-updater` service
- **Important**: Overlapping records may cause conflicts - file plugin takes precedence

### Dynamic DNS Updates
The `dns-updater` service automatically watches Docker events and creates/deletes DNS records in etcd:
- Monitors container start/stop events
- Creates A records for containers with Traefik labels
- Updates etcd at path `/coredns`
- Runs every 30 seconds

### ACME Certificate Challenge Options
Two methods available for SSL certificate generation:
1. **HTTP-01 challenge** (default):
   - Requires domain to be publicly resolvable
   - Traefik handles challenge automatically
   - Check `config/traefik.yml` for ACME configuration

2. **DNS-01 challenge** (via acme_webhook):
   - Python Flask service updates etcd TXT records
   - Allows wildcard certificates
   - Does not require port 80/443 to be publicly accessible
   - Webhook URL: `http://acme_webhook:5000/update-txt-record`

### CrowdSec Configuration
CrowdSec services ARE defined in `compose.yml` and running in LAPI-only mode:
- `crowdsec`: Main intrusion detection service (LAPI mode)
- `crowdsec_bouncer`: Traefik bouncer for blocking malicious IPs
- Both are in `core` profile
- Middleware `crowdsec-fa@file` references these services
- Configuration: `crowdsec/config/acquis.yaml` (LAPI-only with journalctl dummy source)
- Security patterns: `crowdsec/data/` (includes patterns for SQLi, XSS, path traversal, CVEs)
- To enable: `make up-core` (or `docker compose up -d crowdsec crowdsec_bouncer`)
- Status: Active and protecting all public endpoints

### Common Configuration Pitfalls

1. **Zone file + etcd conflicts**:
   - If same record exists in both, file plugin wins
   - Recommendation: Use zone file only for NS/SOA, let etcd handle A records

2. **Internal vs external DNS**:
   - CoreDNS listens on port 53 for authoritative queries
   - Services use Docker's internal DNS (127.0.0.11) for container resolution
   - Some services need explicit DNS servers (see compose.yml:72-74 for Traefik example)

3. **GRAFANA_OAUTH_SECRET in .env**:
   - OAuth secret should only be stored in `secrets/grafana_oauth_secret.txt`
   - The `.env` file should not contain this value (use `.env.example` as reference)
   - Compose service reads directly from Docker secrets, not environment variables

## Branding & Customization

### Authentik Branding
Custom branding has been implemented for Authentik SSO:

**Logo**:
- Original: `branding/logo-800x320-original.png` (800x320px)
- Resized: `branding/logo-200x100.png` (200x100px)
- Active: `branding/logo.png` (optimized for Authentik)

**Custom CSS**: `branding/sn.css`
- SecureNexus color scheme (blue #3b82f6, green #10b981)
- Custom login background gradient
- Logo sizing for login page (300px) and sidebar (140px)
- Gradient borders on cards (blue to green)
- Tagline: "SecureNexus — Secure Infrastructure Platform"

**Deployment**:
- Logo served via `brand-static` service
- CSS loaded from Traefik static file
- See `docs/AUTHENTIK_BRANDING_GUIDE.md` for detailed customization instructions
- See `docs/BRANDING_COMPLETE.md` for implementation summary

## Important Configuration Notes

### Critical Settings to Update Before Deployment

1. **Environment Variables** (`.env`)
   - `DOMAIN`: Your primary domain (e.g., example.com)
   - `EMAIL`: Admin email for ACME certificates (used by Traefik via compose.yml:70)
   - Note: `GRAFANA_OAUTH_SECRET` should NOT be in `.env` - use `secrets/grafana_oauth_secret.txt` instead

2. **Tailscale Auth Key** (`secrets/tailscale_authkey.txt`)
   - Generate from Tailscale admin console
   - Required for VPN access to admin services
   - Create as reusable key with appropriate ACLs

3. **Authentik Secret Key** (`secrets/authentik_secret_key`)
   - 64 hex characters
   - **DO NOT ROTATE** after initial deployment (breaks sessions)
   - Generated by `make secrets`

### Service-Specific Configuration

**Mailcow**:
- Separate installation in `mail/mailcow/` directory
- Has its own `.env` and `mailcow.conf`
- SSL certificates synced via `scripts/update-mailcow-certs.sh`
- Webmail URL configured in Mailcow admin panel

**CoreDNS**:
- Zone file: `dns/zones/securenexus.net.zone` (static records)
- etcd path: `/coredns` (dynamic records)
- Both backends active simultaneously
- File plugin takes precedence for overlapping records

**CrowdSec**:
- LAPI-only mode (no log parsing)
- Bouncer protection via Traefik middleware
- Security patterns in `crowdsec/data/`
- Configuration: `crowdsec/config/acquis.yaml`
- add this report to memory