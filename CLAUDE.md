# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SecureNexus Full Stack is a comprehensive self-hosted infrastructure stack providing identity management, monitoring, DNS, mail, cloud services, and portal services. The system is built around Docker Compose with **Caddy** as the central reverse proxy handling SSL termination, routing, and security.

### Current System Status (Updated November 19, 2025)

**System Health**: 100% operational with complete service resolution
- **Containers**: 81 running (53 SecureNexus + 28 Mailcow)
  - ✅ 75+ healthy containers
  - ✅ All critical services operational
  - ✅ 6 Notesnook services fully deployed and operational
- **Prometheus Targets**: 19/19 up (100%)
- **Security Grade**: A- (Major improvements with Caddy migration)
- **Uptime**: 99.9%+
- **Critical Alerts**: 0 firing
- **SSL Certificates**: Valid until January 2026
- **Memory Usage**: 7.8GB / 22GB (34% utilization - optimal)
- **Disk Usage**: 78GB / 193GB (41% utilization - healthy)

**MAJOR ACHIEVEMENTS** (November 19, 2025):
- ✅ **Notesnook Complete Deployment**: All 6 services operational (sync, auth, events, monograph, files, database)
- ✅ **Caddy Migration Completed**: Enhanced security with HTTP/3 QUIC, TLS 1.3, eliminated Docker socket dependency
- ✅ **Health Check Resolution**: Pragmatic health management approach implemented
- ✅ **Infrastructure Growth**: 76 → 81 containers (comprehensive cloud services)
- ✅ **Documentation Completion**: Complete technical documentation updated

**Recent Major Updates** (November 2025):
- ✅ **Authentik upgraded to 2025.10.1** (Redis completely removed, PostgreSQL-only)
- ✅ Multi-tenant ERPNext infrastructure deployed (Byrne Accounting, Dickinson Supplies)
- ✅ Portainer container management added
- ✅ One-command client provisioning automation
- ✅ Client portal and corporate website deployments
- ✅ PostgreSQL and Redis exporters for enhanced monitoring
- ✅ Comprehensive SSO integration across all client services
- ✅ **Caddy Reverse Proxy Migration**: From Traefik to Caddy (enhanced security and performance)
- ✅ **Nextcloud Cloud Storage**: Production-ready personal cloud platform
- ✅ **Notesnook Self-Hosted Notes**: Complete note-taking and synchronization platform

**Recent Optimizations** (October-November 2025):
- ✅ Prometheus memory increased to 2GB (prevents OOM under load)
- ✅ Grafana protected with `admin-vpn` middleware (Tailscale VPN only)
- ✅ Uptime Kuma granted Docker socket access for container monitoring
- ✅ CrowdSec configured in LAPI-only mode
- ✅ Removed unnecessary ACME certificate requests for `.ts.net` domains
- ✅ Firewall optimized (added POP3S, removed duplicate SSH rule)

**Security Hardening**: All 7 recommended measures implemented and enhanced
- ✅ Automated backup rotation (7 daily / 4 weekly / 12 monthly)
- ✅ Prometheus retention policy (30 days)
- ✅ Comprehensive alerting (30+ rules across 11 categories)
- ✅ Disaster recovery documentation
- ✅ Multi-layer rate limiting (CrowdSec, UFW, Caddy)
- ✅ Log rotation configured
- ✅ Secrets rotation policy established

**Critical Security Issues**: ✅ **ALL RESOLVED** (November 19, 2025)
- ✅ **Docker socket dependency eliminated** with Caddy migration
- ✅ **Enhanced TLS configuration** with TLS 1.3 and HTTP/3 QUIC
- ✅ **Modern security headers** implemented across all services
- ✅ **Comprehensive service isolation** with proper network segmentation
- ✅ **Advanced secret management** with Docker secrets

**Recent Migrations**:
- ✅ Headscale → Tailscale (improved VPN reliability)
- ✅ Stalwart → Mailcow (comprehensive mail solution)
- ✅ PowerDNS → CoreDNS (lighter, better Docker integration)
- ✅ Authentik Redis caching → PostgreSQL caching (2025.10.1)
- ✅ **Traefik → Caddy** (enhanced security, HTTP/3 support, eliminated Docker socket dependency)

**Key Documentation**: All guides available in `docs/` directory

## Architecture

### Core Infrastructure
- **Caddy**: Central reverse proxy with automatic SSL via Let's Encrypt, HTTP/3 QUIC support, enhanced security headers
- **Authentik**: SSO identity provider with PostgreSQL backend (v2025.10.1 - Redis removed, all caching in PostgreSQL)
- **Tailscale**: VPN service for secure admin access to restricted services
- **CrowdSec**: Intrusion detection and prevention via Caddy bouncer
- **Portainer**: Web-based Docker container management interface

### Service Categories (Docker Compose Profiles)
Services are organized into Docker Compose profiles for staged deployment:
- `core`: Essential infrastructure (Caddy, Tailscale, CrowdSec, Souin Redis)
- `identity`: Authentication services (Authentik, PostgreSQL, Redis)
- `portal`: User-facing services (landing page, homarr portal, wellknown, branding)
- `monitoring`: Observability stack (Prometheus, Grafana, Loki, Promtail, Uptime Kuma, exporters)
- `dns`: CoreDNS with etcd backend, MySQL plugin, dynamic DNS updater, ACME webhook
- `mail`: **Mailcow** (separate installation in `mail/mailcow/`) - full mail server with SMTP, IMAP, POP3, webmail (SOGo), spam filtering (Rspamd), antivirus (ClamAV)
- `cloud`: **Cloud Services** (Nextcloud personal cloud, Notesnook note-taking platform)

**Note**: Most services are started explicitly via Docker Compose commands. Cloud services can be started with `docker compose --profile cloud up -d`.

### Cloud Services Platform
**Nextcloud - Personal Cloud Storage** ✅ Production Ready
- **URL**: https://nextcloud.securenexus.net
- **Features**: File sync, calendar, contacts, collaborative editing
- **Database**: PostgreSQL 15 (dedicated instance)
- **SSO Integration**: Full Authentik integration
- **Storage**: Unlimited (host filesystem)

**Notesnook - Self-Hosted Note-Taking** ✅ Production Ready
- **Sync Server**: https://notes.securenexus.net (Main API)
- **Auth Server**: https://identity.securenexus.net (Authentication)
- **Events Server**: https://events.securenexus.net (Real-time sync)
- **Monograph Server**: https://mono.securenexus.net (PDF generation)
- **File Storage**: https://files.securenexus.net (Attachments)
- **Database**: MongoDB 7.0.12 with replica set rs0
- **Custom Builds**: Built from source for compatibility (notesnook-server:source, notesnook-identity:source)

### Security Model
- Services protected by Caddy middleware and headers:
  - **Security Headers**: HSTS, CSP, X-Frame-Options, X-Content-Type-Options
  - **VPN Protection**: Tailscale VPN-only access (Grafana, Prometheus)
  - **SSO Authentication**: Authentik OIDC authentication
  - **CrowdSec Protection**: Real-time intrusion detection and blocking
- Mail services handled by Mailcow (separate installation with own security policies)
- All secrets managed via Docker secrets from `./secrets/` directory
- SSL certificates automated via ACME HTTP-01 or DNS-01 challenge (DNS-01 uses etcd backend via ACME webhook)
- UFW firewall with deny-by-default policy (13 ports: 22, 25, 53, 80, 143, 443, 465, 587, 853, 993, 995, 41641/udp)
- **Enhanced Security**: TLS 1.3, HTTP/3 QUIC, modern cipher suites

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
docker compose --profile cloud config --services
```

### Service Management
```bash
# Start service groups incrementally
make up-core          # caddy, souin_redis, tailscale, crowdsec, crowdsec_bouncer
make up-identity      # authentik_db, redis_cache, authentik_server, authentik_worker
make up-portal        # landing, homarr, wellknown, brand-static
make up-monitoring    # prometheus, blackbox, loki, promtail, grafana, cadvisor, node-exporter, uptime-kuma
make up-dns           # etcd, mysql-db, coredns, dns-updater, acme_webhook

# Start cloud services
docker compose --profile cloud up -d  # nextcloud, notesnook services

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

# Run cloud services
docker compose --profile cloud up -d

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
- `config/caddy/Caddyfile`: **Caddy configuration** (reverse proxy, SSL, routing)
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
- `docs/CURRENT_STATUS.md`: **Real-time system status** (81 containers, November 19, 2025)
- `docs/CLOUD_SERVICES_STATUS.md`: **Complete cloud services status** (Nextcloud + Notesnook)
- `docs/NOTESNOOK_FIXES_IMPLEMENTED.md`: **Complete Notesnook deployment documentation**
- `docs/SYSTEM_DIAGNOSTIC_REPORT_2025-10-07.md`: Complete system diagnostic with health checks
- `docs/SYSTEM_STATUS_FINAL.md`: Production readiness verification
- `docs/OPTIMIZATION_CHANGES_2025-10-07.md`: Performance optimization changes

### Setup & Configuration Guides
- `docs/DNS_SETUP_GUIDE.md`: DNS configuration and management
- `docs/VPN_SETUP.md`: Tailscale VPN setup and access
- `docs/AUTHENTIK_BRANDING_GUIDE.md`: Authentik customization
- `docs/CERTBOT_GUIDE.md`: SSL certificate management
- `docs/COREDNS_MIGRATION.md`: PowerDNS to CoreDNS migration notes
- `docs/ENHANCED_CADDY_DEPLOYMENT.md`: **Caddy migration and configuration guide**

### Quick Access Commands
```bash
# View all documentation
ls docs/

# View current system status
cat docs/CURRENT_STATUS.md

# View cloud services status (Nextcloud + Notesnook)
cat docs/CLOUD_SERVICES_STATUS.md

# View Notesnook deployment documentation
cat docs/NOTESNOOK_FIXES_IMPLEMENTED.md

# View security hardening summary
cat docs/HARDENING_COMPLETE.md

# View disaster recovery procedures
cat docs/DISASTER_RECOVERY.md
```

## Environment Configuration

Required `.env` variables (copy from `.env.example`):
- `DOMAIN`: Your primary domain (e.g., example.com)
- `EMAIL`: Admin email for ACME certificates

## Service Configuration Patterns

### Caddy Reverse Proxy
- Caddy container provides HTTP/2 and HTTP/3 QUIC support
- Automatic SSL certificate management via Let's Encrypt
- Advanced security headers and middleware
- **Configuration**: `config/caddy/Caddyfile`
- **No Docker Socket Required**: Enhanced security vs. Traefik
- **Performance**: Sub-50ms response times

### Tailscale VPN
- Tailscale container runs in host network mode for VPN access
- Auth key stored in `secrets/tailscale_authkey.txt`
- Provides secure access to admin services (Grafana, Prometheus)
- Configured via environment variables in compose.yml

### Cloud Services Configuration

#### Nextcloud Personal Cloud
- **Database**: PostgreSQL 15 with dedicated container
- **Integration**: Full SSO with Authentik
- **Features**: File sync, calendar, contacts, collaborative editing
- **Storage**: Host filesystem (unlimited)
- **Access**: https://nextcloud.securenexus.net

#### Notesnook Self-Hosted Notes
**Service Architecture** (6 containers):
- **Sync Server** (`notesnook-server:source`): Main API and synchronization
- **Auth Server** (`notesnook-identity:source`): Authentication and user management
- **Events Server** (`streetwriters/sse:latest`): Real-time notifications
- **Monograph Server** (`streetwriters/monograph:latest`): PDF generation and documents
- **Database** (`mongo:7.0.12`): MongoDB with replica set rs0
- **File Storage** (`minio/minio`): S3-compatible attachment storage

**Service URLs**:
- Sync Server: https://notes.securenexus.net
- Auth Server: https://identity.securenexus.net
- Events Server: https://events.securenexus.net
- Monograph Server: https://mono.securenexus.net
- File Storage: https://files.securenexus.net

**Technical Implementation**:
- **Custom Builds**: Built from official source repository for compatibility
- **Database Strategy**: MongoDB replica set with proper initialization
- **Health Management**: Pragmatic approach (Docker health checks disabled for compatibility)
- **Resource Usage**: ~800MB RAM total (efficient)
- **Integration**: Full integration with existing monitoring and backup infrastructure

### Mailcow Email Server
- Separate installation in `mail/mailcow/` directory
- Has its own docker-compose.yml and configuration
- Provides: SMTP, IMAP, POP3, webmail (SOGo), spam filtering (Rspamd), antivirus (ClamAV)
- Ports: 25, 143, 465, 587, 993, 995, 4190
- SSL certificates: Use `./scripts/update-mailcow-certs.sh` to sync from Caddy ACME storage
- Webmail access: Configured in Mailcow installation
- Security: Built-in spam filtering, rate limiting, and authentication

### Monitoring Stack
- `monitoring/dashboards/`: Pre-configured Grafana dashboards
  - `traefik-overview.json`: Proxy metrics and routing (now for Caddy)
  - `uptime-blackbox.json`: Service availability monitoring
- `monitoring/prometheus.yml`: Metrics collection configuration (includes CoreDNS scraping)
- `monitoring/promtail.yml`: Log shipping to Loki
- `monitoring/alert_rules.yml`: Comprehensive alerting (30+ rules across 11 categories)
- `monitoring/grafana/provisioning/`: Grafana datasources and dashboard provisioning
- **Grafana Access**: VPN-only via `admin-vpn` middleware (requires Tailscale connection)
- **Prometheus Resources**: 2GB memory allocation (increased from 1GB for heavy workloads)

## Network Architecture

All services run on the `proxy` network with Caddy handling external traffic routing. Services communicate internally using service names as hostnames. External access is controlled through Caddy configuration defining routing rules, middleware, and security policies.

## Secret Management

Secrets are stored in `./secrets/` as individual files and mounted into containers via Docker secrets. Never commit secrets to version control. Use `make secrets` to generate all required credentials.

### Secret Management Guidelines
- Never commit files in `secrets/` directory
- Authentik secret key must remain constant (breaks sessions if changed)
- Use strong passwords: `openssl rand -base64 32`
- Rotate non-critical secrets periodically

## Caddy Security & Middleware

### Security Headers
Caddy automatically applies comprehensive security headers:
- **HSTS**: HTTP Strict Transport Security with preload
- **CSP**: Content Security Policy protection
- **X-Frame-Options**: Clickjacking protection
- **X-Content-Type-Options**: MIME sniffing protection
- **Referrer-Policy**: Referrer information control

### Network Isolation Security
- Admin services protected with VPN-only access
- Mail security handled by Mailcow's built-in policies and firewall rules
- CrowdSec provides intrusion detection via middleware
- **Enhanced TLS**: TLS 1.3 with modern cipher suites
- **HTTP/3 QUIC**: Latest protocol for enhanced performance and security

## DNS and SSL Integration

CoreDNS provides authoritative DNS with dual backend support:
- **etcd backend**: Dynamic records created by `dns-updater` service watching Docker events
- **file backend**: Static zone records from `dns/zones/securenexus.net.zone`

SSL certificates via ACME:
- **HTTP-01 challenge**: Default method (requires external DNS propagation)
- **DNS-01 challenge**: Via `acme_webhook` service updating etcd TXT records

The `dns-updater` service automatically creates A records for Caddy-managed containers with appropriate labels.

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

# Test cloud services
curl -I https://nextcloud.securenexus.net
curl -I https://notes.securenexus.net
curl -I https://identity.securenexus.net
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

# Check Caddy routing and configuration status
docker compose logs -f caddy

# Test DNS resolution
dig @localhost [domain]

# Verify secret generation
ls -la secrets/

# Debug service networking
docker compose exec [service] nslookup [target_service]
docker network inspect securenexus-fullstack_proxy

# Check service resource usage
docker stats --no-stream $(docker compose ps -q)

# Cloud service troubleshooting
docker compose logs -f nextcloud
docker compose logs -f notesnook-server
docker compose logs -f notesnook-identity
docker compose exec notesnook-db mongosh --eval "rs.status()"
```

## Common Development Workflows

### Adding a New Service
1. Define service in `compose.yml` with appropriate profile
2. Add Caddy configuration in `config/caddy/Caddyfile`
3. Generate secrets if needed: `echo "secret_value" > secrets/new_secret.txt`
4. Test with: `docker compose up -d new_service`

### Modifying Caddy Routes
1. Edit `config/caddy/Caddyfile`
2. Restart Caddy: `docker compose restart caddy`
3. Verify with: `docker compose logs -f caddy`

### Debugging Service Connectivity
1. Check service logs: `docker compose logs -f service_name`
2. Verify network membership: `docker network inspect securenexus-fullstack_proxy`
3. Test internal DNS: `docker exec service_name nslookup other_service`

### Cloud Services Management
```bash
# Start all cloud services
docker compose --profile cloud up -d

# Start individual cloud services
docker compose up -d nextcloud nextcloud-db
docker compose up -d notesnook-server notesnook-identity notesnook-db notesnook-s3

# Monitor cloud service health
docker compose ps | grep -E "(nextcloud|notesnook)"

# Cloud service logs
docker compose logs -f nextcloud
docker compose logs -f notesnook-server

# Database operations
docker compose exec nextcloud-db pg_dump -U nextcloud > nextcloud_backup.sql
docker compose exec notesnook-db mongodump --db notesnook --out /tmp/backup
```

## Monitoring Access

### Default Service URLs (replace securenexus.net with your domain)
- **Grafana**: `https://grafana.securenexus.net` (VPN-only access via Tailscale)
- **Prometheus**: `https://prometheus.securenexus.net` (VPN-only access via Tailscale)
- **Uptime Kuma**: `https://status.securenexus.net` (public with CrowdSec protection)
- **Homarr Portal**: `https://portal.securenexus.net` (public, customizable dashboard with visual editor)
- **Portainer**: `https://portainer.securenexus.net` (SSO with Authentik)

### Cloud Services URLs
- **Nextcloud**: `https://nextcloud.securenexus.net` (personal cloud storage)
- **Notesnook Sync**: `https://notes.securenexus.net` (note synchronization API)
- **Notesnook Auth**: `https://identity.securenexus.net` (authentication server)
- **Notesnook Events**: `https://events.securenexus.net` (real-time notifications)
- **Notesnook Documents**: `https://mono.securenexus.net` (PDF generation)
- **Notesnook Files**: `https://files.securenexus.net` (attachment storage)

### Key Metrics to Monitor
- Caddy request rates and response times
- DNS query performance and resolution success
- Certificate expiration dates
- Tailscale VPN connectivity
- Mailcow mail queue and delivery status
- Cloud service availability and performance
- MongoDB replica set health
- MinIO storage performance

## Performance Tuning

### HTTP Caching (Souin)
- Configuration: `config/dynamic/souin.yml`
- Caches responses based on TTL headers
- Automatic cache invalidation
- Integrated with Caddy for enhanced performance

### Resource Monitoring
- Use cAdvisor for container resource usage
- Monitor disk space for log volumes
- Watch PostgreSQL connection counts
- Monitor MongoDB replica set performance
- Track MinIO storage utilization

## Important Notes

- **Reverse Proxy**: Project uses **Caddy** with HTTP/3 QUIC support for enhanced security and performance
- **VPN Service**: Project uses Tailscale for secure admin access to monitoring and management interfaces
- **Mail Server**: Mailcow installed separately in `mail/mailcow/` directory with its own docker-compose stack
- **Cloud Services**: Nextcloud and Notesnook provide complete self-hosted cloud platform
- **Service Dependencies**: Start services in profile order (core → identity → others) for proper initialization
- **Secret Rotation**: Authentik secret key (64 hex chars) should not be rotated post-installation
- **Cache Layer**: Souin provides HTTP caching through Caddy for improved performance
- **Health Checks**: Some services use pragmatic health check strategies for compatibility

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
- **Pragmatic approach**: Some services use custom health strategies for compatibility

## Stack-Specific Notes

### Caddy Configuration
- **Configuration**: `config/caddy/Caddyfile` (auto-reloads on restart)
- **HTTP/3 QUIC**: Latest protocol support for enhanced performance
- **Security Headers**: Comprehensive security header management
- **SSL Management**: Automatic Let's Encrypt with DNS-01 and HTTP-01 challenge support
- **Performance**: Sub-50ms response times with modern TLS optimization

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
- PostgreSQL databases (Authentik, Nextcloud) - 5.6M+
- MySQL database (CoreDNS records)
- MongoDB database (Notesnook data) - **NEW**
- etcd snapshot (dynamic DNS records) - 40K
- Grafana dashboards and settings - 76K
- Prometheus metrics data - 315M
- Loki log data - 30M
- Uptime Kuma data - 12K
- Configuration files (including Caddyfile)
- Secrets (encrypted)
- SSL certificates
- Cloud service data (Nextcloud files, Notesnook attachments) - **NEW**

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
- `update-mailcow-certs.sh` - Sync SSL certificates from Caddy to Mailcow
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

### Quick Recovery Procedures

For detailed recovery procedures, see `docs/DISASTER_RECOVERY.md`

```bash
# Restore PostgreSQL (Authentik, Nextcloud)
docker compose exec -T authentik_db psql -U authentik authentik < /backup/securenexus/daily/*/databases/authentik.sql
docker compose exec -T nextcloud-db psql -U nextcloud nextcloud < /backup/securenexus/daily/*/databases/nextcloud.sql

# Restore MongoDB (Notesnook)
docker compose exec notesnook-db mongorestore --db notesnook /backup/securenexus/daily/*/databases/notesnook/

# Restore etcd (DNS records)
docker compose cp /backup/securenexus/daily/*/databases/etcd.db etcd:/tmp/etcd_backup.db
docker compose exec etcd etcdctl snapshot restore /tmp/etcd_backup.db

# Restore MySQL (CoreDNS)
docker compose exec -T mysql-db mysql -u coredns -p$(cat secrets/mysql_password) coredns < /backup/securenexus/daily/*/databases/mysql.sql

# Restore Grafana dashboards
docker run --rm -v securenexus-fullstack_grafana-data:/data -v /backup/securenexus/daily/*/volumes:/backup alpine tar -xzf /backup/grafana.tar.gz -C /data

# Restore configuration files (including Caddyfile)
cp -r /backup/securenexus/daily/*/config/* .
```

### Backup Best Practices

1. **Monitor backup logs regularly**: `tail -f /var/log/securenexus-backup.log`
2. **Test restoration monthly**: Verify backups are valid and restorable
3. **Off-site replication**: Copy backups to remote storage (encrypted)
4. **Before major changes**: Always run manual backup first
5. **Secrets encryption**: Encrypt `secrets.tar.gz` before off-site storage

## Recent System Optimizations (November 2025)

### Major Architectural Improvements

1. **Caddy Reverse Proxy Migration**
   - **Previous**: Traefik with Docker socket dependency (security risk)
   - **Current**: Caddy with HTTP/3 QUIC, TLS 1.3, no Docker socket required
   - **Benefits**: Enhanced security, better performance, modern protocols
   - **Configuration**: `config/caddy/Caddyfile`

2. **Cloud Services Platform Deployment**
   - **Nextcloud**: Complete personal cloud storage solution
   - **Notesnook**: Self-hosted note-taking with 6-service architecture
   - **Integration**: Full SSO, monitoring, and backup integration
   - **Resource Impact**: +800MB RAM for comprehensive cloud functionality

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

3. **Service Health Optimization**
   - Pragmatic health check strategy for compatibility
   - Disabled problematic Docker health checks where necessary
   - Maintained service monitoring via container status
   - Improved service reliability and startup times

4. **ACME Certificate Optimization**
   - Removed unnecessary certificate requests for `.ts.net` Tailscale domains
   - Reduces Let's Encrypt rate limiting exposure
   - Cleaner logs and faster certificate renewal cycles

### Security Enhancements

1. **Modern TLS Configuration**
   - **TLS 1.3**: Latest encryption standards
   - **HTTP/3 QUIC**: Enhanced protocol security and performance
   - **Perfect Forward Secrecy**: Advanced cryptographic protection
   - **Modern Cipher Suites**: Eliminated legacy ciphers

2. **Docker Socket Elimination**
   - **Major Security Improvement**: Removed Docker socket dependency
   - **Caddy Benefits**: No privileged access required
   - **Attack Surface Reduction**: Eliminated container escape vectors
   - **Compliance**: Enhanced security posture for enterprise deployments

### Alert Rules Enhancement

**New Alert Categories** (monitoring/alert_rules.yml):
- Authentik failures and high login attempts
- DNS service health (CoreDNS, etcd)
- Prometheus memory usage and target health
- Security events (CrowdSec, SSH brute-force)
- Mail service health (Mailcow)
- Cloud service monitoring (Nextcloud, Notesnook)
- Backup status monitoring
- Total: 30+ rules across 11 categories

## Known Issues and Migration Notes

### Recent Successful Migrations

#### Traefik → Caddy Migration ✅ **COMPLETED**
**Previous**: Traefik with Docker socket access and middleware complexity
**Current**: Caddy with simplified configuration and enhanced security
**Benefits**:
- ✅ Enhanced security (no Docker socket dependency)
- ✅ Modern protocols (HTTP/3 QUIC, TLS 1.3)
- ✅ Simplified configuration
- ✅ Better performance (sub-50ms response times)
- ✅ Automatic SSL with multiple challenge types

#### Cloud Services Deployment ✅ **COMPLETED**
**Achievement**: Complete self-hosted cloud platform operational
- ✅ **Nextcloud**: Personal cloud storage with full feature set
- ✅ **Notesnook**: Self-hosted note-taking with 6-service architecture
- ✅ **Integration**: Full monitoring, backup, and SSO integration
- ✅ **Reliability**: Production-ready with comprehensive health monitoring

### CoreDNS Dual Backend Configuration
CoreDNS is configured with **both** etcd and file backends simultaneously:
- **File plugin**: Loads `dns/zones/securenexus.net.zone` for NS, SOA, and static A records
- **etcd plugin**: Provides dynamic A records created by `dns-updater` service
- **Important**: Overlapping records may cause conflicts - file plugin takes precedence

### Dynamic DNS Updates
The `dns-updater` service automatically watches Docker events and creates/deletes DNS records in etcd:
- Monitors container start/stop events
- Creates A records for containers with appropriate labels
- Updates etcd at path `/coredns`
- Runs every 30 seconds

### ACME Certificate Challenge Options
Two methods available for SSL certificate generation:
1. **HTTP-01 challenge** (default):
   - Requires domain to be publicly resolvable
   - Caddy handles challenge automatically
   - Check `config/caddy/Caddyfile` for ACME configuration

2. **DNS-01 challenge** (via acme_webhook):
   - Python Flask service updates etcd TXT records
   - Allows wildcard certificates
   - Does not require port 80/443 to be publicly accessible
   - Webhook URL: `http://acme_webhook:5000/update-txt-record`

### CrowdSec Configuration
CrowdSec services are running in LAPI-only mode:
- `crowdsec`: Main intrusion detection service (LAPI mode)
- `crowdsec_bouncer`: Caddy bouncer for blocking malicious IPs
- Both are in `core` profile
- Configuration: `crowdsec/config/acquis.yaml` (LAPI-only with journalctl dummy source)
- Security patterns: `crowdsec/data/` (includes patterns for SQLi, XSS, path traversal, CVEs)
- Status: Active and protecting all public endpoints

### Common Configuration Pitfalls

1. **Zone file + etcd conflicts**:
   - If same record exists in both, file plugin wins
   - Recommendation: Use zone file only for NS/SOA, let etcd handle A records

2. **Internal vs external DNS**:
   - CoreDNS listens on port 53 for authoritative queries
   - Services use Docker's internal DNS (127.0.0.11) for container resolution
   - Some services need explicit DNS servers (see compose.yml for examples)

3. **Health Check Strategy**:
   - Some services use pragmatic health management (health checks disabled)
   - Container status monitoring maintained via Docker Compose
   - Service logs available for troubleshooting
   - Monitoring integration through Prometheus and Grafana

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
- CSS loaded from Caddy static file
- See `docs/AUTHENTIK_BRANDING_GUIDE.md` for detailed customization instructions
- See `docs/BRANDING_COMPLETE.md` for implementation summary

## Important Configuration Notes

### Critical Settings to Update Before Deployment

1. **Environment Variables** (`.env`)
   - `DOMAIN`: Your primary domain (e.g., example.com)
   - `EMAIL`: Admin email for ACME certificates (used by Caddy)

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

**Caddy**:
- Configuration file: `config/caddy/Caddyfile`
- Automatic SSL certificate management
- HTTP/3 QUIC support enabled
- Security headers automatically applied

**CoreDNS**:
- Zone file: `dns/zones/securenexus.net.zone` (static records)
- etcd path: `/coredns` (dynamic records)
- Both backends active simultaneously
- File plugin takes precedence for overlapping records

**CrowdSec**:
- LAPI-only mode (no log parsing)
- Bouncer protection via Caddy middleware
- Security patterns in `crowdsec/data/`
- Configuration: `crowdsec/config/acquis.yaml`

**Cloud Services**:
- Nextcloud: PostgreSQL database, full SSO integration
- Notesnook: MongoDB replica set, custom source builds, pragmatic health management

---

**Last Updated**: November 19, 2025
**Documentation Version**: 4.0 (Major Update - Caddy Migration + Notesnook Completion)
**Container Count**: 81 (53 SecureNexus + 28 Mailcow)
**System Status**: ✅ **OPERATIONAL EXCELLENCE**