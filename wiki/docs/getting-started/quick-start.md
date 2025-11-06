# Quick Start Guide

Get SecureNexus up and running in under 30 minutes.

## Prerequisites

Before you begin, ensure you have:

- **Server**: Ubuntu 22.04 LTS (minimum 8GB RAM, 4 CPU cores, 100GB disk)
- **Domain**: Registered domain with DNS access
- **Email**: Valid email for SSL certificates
- **SSH Access**: Root or sudo privileges

## Installation Steps

### 1. Server Preparation (5 minutes)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker $USER

# Reboot to apply changes
sudo reboot
```

### 2. Clone Repository (1 minute)

```bash
# Clone the repository
git clone https://github.com/your-org/securenexus-fullstack.git
cd securenexus-fullstack
```

### 3. Configure Environment (3 minutes)

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

Set these required values:
```bash
DOMAIN=your-domain.com
EMAIL=admin@your-domain.com
```

### 4. Generate Secrets (2 minutes)

```bash
# Generate all required secrets automatically
make secrets

# Verify secrets were created
ls -la secrets/
```

### 5. Configure DNS (5 minutes)

Point these DNS records to your server IP:

```
A     @                    <your-server-ip>
A     *                    <your-server-ip>
A     erp                  <your-server-ip>
A     mail                 <your-server-ip>
A     status               <your-server-ip>
A     portal               <your-server-ip>
A     sso                  <your-server-ip>

# For VPN-only services (optional)
A     grafana              <your-server-ip>
A     prometheus           <your-server-ip>
A     traefik              <your-server-ip>

# Mail records (for Mailcow)
MX    @        10          mail.your-domain.com
TXT   @                    "v=spf1 mx ~all"
TXT   _dmarc               "v=DMARC1; p=quarantine; rua=mailto:postmaster@your-domain.com"
```

### 6. Configure Firewall (2 minutes)

```bash
# Run firewall setup script
sudo ./scripts/setup-ufw-firewall.sh

# Verify firewall status
sudo ufw status numbered
```

### 7. Deploy Services (10 minutes)

```bash
# Run preflight checks
make preflight

# Deploy core infrastructure
make up-core
# Wait 30 seconds for Traefik to initialize

# Deploy identity services
make up-identity
# Wait 60 seconds for Authentik to initialize

# Deploy portal services
make up-portal

# Deploy monitoring services
make up-monitoring

# Verify all services are running
make ps
```

### 8. Initial Configuration (5 minutes)

#### Authentik (SSO)

1. Visit `https://sso.your-domain.com/if/flow/initial-setup/`
2. Create admin account
3. Set admin password (store in password manager)

#### ERPNext

1. Visit `https://erp.your-domain.com`
2. Complete setup wizard:
   - Company name
   - Country & currency
   - Fiscal year
   - Chart of accounts

#### Uptime Kuma

1. Visit `https://status.your-domain.com`
2. Create admin account
3. Add monitors for key services

## Verification

### Check Service Status

```bash
# View all running containers
docker compose ps

# Should show 29/29 running
```

### Test SSL Certificates

```bash
# Check certificate status
curl -vI https://sso.your-domain.com 2>&1 | grep -i "SSL certificate verify"

# Should show "SSL certificate verify ok"
```

### Access Services

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Authentik SSO | https://sso.your-domain.com | Created during setup |
| ERPNext | https://erp.your-domain.com | Administrator / (wizard) |
| Uptime Kuma | https://status.your-domain.com | Created during setup |
| Homarr Portal | https://portal.your-domain.com | No login required |
| Mailcow | https://mail.your-domain.com | admin / moohoo |

### VPN-Only Services (Optional)

If you've configured Tailscale:

| Service | URL | Access |
|---------|-----|--------|
| Grafana | https://grafana.your-domain.com | VPN required |
| Prometheus | https://prometheus.your-domain.com | VPN required |
| Traefik Dashboard | https://traefik.your-domain.com | VPN required |

## Post-Installation

### 1. Configure Backups

```bash
# Setup automated backups
sudo ./scripts/setup-automated-backups.sh

# Verify backup schedule
crontab -l | grep backup
```

### 2. Configure Monitoring

1. Access Grafana (VPN required): `https://grafana.your-domain.com`
2. Default login: `admin` / (see `secrets/grafana_admin_password`)
3. Explore pre-configured dashboards

### 3. Harden Security

```bash
# Run full security hardening
./scripts/security-hardening.sh

# Enable SSH rate limiting
./scripts/enable-ssh-rate-limiting.sh
```

## Common Issues

### SSL Certificates Not Issued

**Symptom**: Browser shows certificate error

**Solution**:
```bash
# Check Traefik logs
docker compose logs traefik | grep -i acme

# Verify DNS propagation
dig your-domain.com

# Restart Traefik
docker compose restart traefik
```

### Service Won't Start

**Symptom**: Container keeps restarting

**Solution**:
```bash
# Check service logs
docker compose logs <service-name>

# Verify dependencies
docker compose ps

# Restart specific service
make restart S=<service-name>
```

### Can't Access Service

**Symptom**: Connection timeout or 404

**Solution**:
```bash
# Check firewall
sudo ufw status

# Verify Traefik routing
docker compose logs traefik | grep <service-name>

# Test internal connectivity
docker compose exec traefik ping <service-name>
```

## Next Steps

1. **[Configure Email](../email/overview.md)**: Set up Mailcow for email services
2. **[Add Client Sites](../clients/overview.md)**: Provision multi-tenant ERPNext instances
3. **[Security Hardening](../security/overview.md)**: Complete security checklist
4. **[Monitoring Setup](../monitoring/overview.md)**: Configure alerts and dashboards

## Getting Help

- **Documentation**: Search the wiki using the search bar
- **Logs**: `make logs` to view all service logs
- **Status**: `make ps` to check service health
- **Troubleshooting**: See [Troubleshooting Guide](../troubleshooting/overview.md)
