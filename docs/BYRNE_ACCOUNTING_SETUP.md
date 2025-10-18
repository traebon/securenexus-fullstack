# Byrne Accounting Setup Guide

Complete guide for deploying the Byrne Accounting website, ERPNext ERP system, and AwesomePOS point-of-sale system on the SecureNexus infrastructure.

> **Domain Migration Notice**: This system is configured for **byrne-accounts.org**. All references to byrneaccounting.net in this document should be replaced with byrne-accounts.org.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Steps](#deployment-steps)
4. [Authentik SSO Integration](#authentik-sso-integration)
5. [AwesomePOS Configuration](#awesomepos-configuration)
6. [DNS Configuration](#dns-configuration)
7. [Security Features](#security-features)
8. [Troubleshooting](#troubleshooting)
9. [Backup and Maintenance](#backup-and-maintenance)

---

## Architecture Overview

### Services Deployed

The Byrne Accounting stack consists of **8 services** across **3 main components**:

#### 1. Marketing Website (`byrneaccounting.net`)
- **Service**: `byrne-website` (Nginx serving static HTML/CSS/JS)
- **Features**:
  - Professional accounting firm landing page
  - Services overview and contact forms
  - Client portal access page
  - CrowdSec protection for public access
  - Automatic HTTPS via Let's Encrypt

#### 2. ERPNext ERP System (`erp.byrneaccounting.net`)
- **Services**:
  - `erpnext-backend` - Frappe/ERPNext application server (v15.40.5)
  - `erpnext-worker` - Background job processor
  - `erpnext-scheduler` - Scheduled task runner
  - `erpnext-db` - PostgreSQL 16 database
  - `erpnext-redis-cache` - Redis cache (512MB, LRU eviction)
  - `erpnext-redis-queue` - Redis queue for jobs
- **Features**:
  - Full accounting and bookkeeping
  - Inventory management
  - CRM and project management
  - HR and payroll
  - Financial reporting
  - Authentik SSO protected

#### 3. Point of Sale System (`pos.byrneaccounting.net`)
- **Service**: AwesomePOS plugin for ERPNext
- **Features**:
  - Modern, intuitive POS interface
  - Real-time inventory sync with ERPNext
  - Multi-payment method support
  - Receipt printing
  - Offline mode capability
  - Sales reporting and analytics
  - Authentik SSO protected

### Network Architecture

```
Internet
    |
    v
[Traefik Reverse Proxy] (SSL termination, routing)
    |
    +-- [CrowdSec Bouncer] (intrusion detection)
    |
    +-- byrneaccounting.net --> byrne-website (Public)
    |
    +-- erp.byrneaccounting.net --> [Authentik SSO] --> erpnext-backend (Protected)
    |
    +-- pos.byrneaccounting.net --> [Authentik SSO] --> erpnext-backend (Protected)
```

### Data Flow

1. **Public Access**: Website → Traefik → CrowdSec → byrne-website
2. **ERP Access**: User → Traefik → Authentik SSO → ERPNext Backend
3. **POS Access**: User → Traefik → Authentik SSO → AwesomePOS (via ERPNext)
4. **Data Sync**: AwesomePOS ↔ ERPNext Backend ↔ PostgreSQL Database

---

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 22.04+ recommended)
- **Memory**: Minimum 8GB RAM (16GB recommended for production)
- **Disk Space**: 50GB+ available
- **CPU**: 4+ cores recommended

### Required Services Running

Before deploying Byrne Accounting, ensure these services are running:

```bash
# Check required services
docker compose ps | grep -E "traefik|authentik_server|coredns"
```

Required services:
- ✅ Traefik (reverse proxy)
- ✅ Authentik (SSO identity provider)
- ✅ CoreDNS (DNS server)
- ✅ CrowdSec (intrusion detection)

Start required services if not running:
```bash
make up-core      # Traefik, CrowdSec, Tailscale
make up-identity  # Authentik, PostgreSQL, Redis
make up-dns       # CoreDNS, etcd
```

### Domain Configuration

**External DNS Requirements**:

You must configure your domain registrar to point to your server:

```
# At your domain registrar (e.g., Namecheap, GoDaddy, Cloudflare)
byrneaccounting.net       A    137.74.40.208
*.byrneaccounting.net     A    137.74.40.208
```

Or delegate NS records to your CoreDNS server:
```
byrneaccounting.net       NS   ns1.securenexus.net
byrneaccounting.net       NS   ns2.securenexus.net
```

---

## Deployment Steps

### Step 1: Generate Secrets

Generate all required passwords and keys:

```bash
make secrets
```

This creates:
- `secrets/erpnext_db_password.txt` - PostgreSQL database password
- `secrets/erpnext_admin_password.txt` - ERPNext Administrator password
- `secrets/erpnext_redis_cache_password.txt` - Redis cache password
- `secrets/erpnext_redis_queue_password.txt` - Redis queue password

**Important**: Save the admin password from `secrets/erpnext_admin_password.txt` - you'll need it to log in.

```bash
cat secrets/erpnext_admin_password.txt
```

### Step 2: Build and Deploy

Deploy the entire Byrne Accounting stack:

```bash
make up-byrne
```

This will:
1. Build the byrne-website Docker image
2. Start PostgreSQL and Redis services
3. Wait for databases to be ready
4. Start ERPNext backend, worker, and scheduler
5. Start the marketing website

**Expected output**:
```
Byrne Accounting stack started!
  - Website: https://byrneaccounting.net
  - Portal: https://byrneaccounting.net/portal
  - ERP: https://erp.byrneaccounting.net
  - POS: https://pos.byrneaccounting.net

Next steps:
  1. Wait for ERPNext to initialize (check logs: docker compose logs -f erpnext-backend)
  2. Run: make install-awesomepos
  3. Configure Authentik SSO integration
```

### Step 3: Wait for ERPNext Initialization

ERPNext takes **5-10 minutes** to initialize on first start. Monitor the logs:

```bash
docker compose logs -f erpnext-backend
```

Watch for:
```
✓ Database initialized
✓ Site erp.byrneaccounting.net created
✓ App erpnext installed
✓ Bench started
```

### Step 4: Verify Services

Check that all services are healthy:

```bash
docker compose ps | grep byrne
docker compose ps | grep erpnext
```

All services should show `healthy` or `running (healthy)`.

### Step 5: Test Access

**Marketing Website** (Public):
```bash
curl -I https://byrneaccounting.net
# Should return: HTTP/2 200
```

**ERP System** (SSO Protected - will redirect to Authentik):
```bash
curl -I https://erp.byrneaccounting.net
# Should return: HTTP/2 302 (redirect to Authentik)
```

### Step 6: Install AwesomePOS

Once ERPNext is fully initialized, install the AwesomePOS plugin:

```bash
make install-awesomepos
```

This will:
1. Clone AwesomePOS from GitHub
2. Install the app into ERPNext
3. Create default POS profile
4. Configure payment methods
5. Build frontend assets
6. Restart ERPNext services

**Installation time**: 3-5 minutes

---

## Authentik SSO Integration

### Overview

Both ERPNext and POS systems are protected by Authentik SSO using the `sso@file` middleware defined in Traefik. Users must authenticate through Authentik before accessing either system.

### Step 1: Create Application in Authentik

1. **Access Authentik Admin**:
   - URL: `https://authentik.securenexus.net` (or `https://sso.securenexus.net`)
   - Login with your Authentik admin credentials

2. **Create OAuth2 Provider** for ERPNext:
   - Navigate to: **Applications** → **Providers** → **Create**
   - **Name**: `ERPNext Provider`
   - **Type**: `OAuth2/OpenID Provider`
   - **Client Type**: `Confidential`
   - **Redirect URIs**:
     ```
     https://erp.byrneaccounting.net/api/method/frappe.integrations.oauth2_logins.custom/callback
     https://pos.byrneaccounting.net/api/method/frappe.integrations.oauth2_logins.custom/callback
     ```
   - **Scopes**: `openid profile email`
   - **Signing Key**: Select your default certificate
   - Click **Create**

3. **Save Client Credentials**:
   - Copy **Client ID** and **Client Secret** - you'll need these for ERPNext configuration

4. **Create Application**:
   - Navigate to: **Applications** → **Create**
   - **Name**: `Byrne Accounting - ERPNext`
   - **Slug**: `byrne-erp`
   - **Provider**: Select the provider you just created
   - **Launch URL**: `https://erp.byrneaccounting.net`
   - Click **Create**

5. **Assign Users/Groups**:
   - In the application settings, go to **Policy / Group / User Bindings**
   - Add users or groups who should have access to ERPNext
   - Recommended: Create a group called "Byrne Accounting Users"

### Step 2: Configure ERPNext OAuth

1. **Access ERPNext as Administrator**:
   ```bash
   # Get admin password
   cat secrets/erpnext_admin_password.txt
   ```
   - Navigate to: `https://erp.byrneaccounting.net`
   - **Temporarily bypass SSO** for initial setup:
     ```bash
     # Edit compose.yml and temporarily remove sso@file middleware
     # OR access via direct IP if firewall allows
     ```

2. **Configure Social Login**:
   - Go to: **Settings** → **Social Login Key** → **New**
   - **Provider**: `Custom`
   - **Client ID**: (from Authentik)
   - **Client Secret**: (from Authentik)
   - **Authorize URL**: `https://sso.securenexus.net/application/o/authorize/`
   - **Access Token URL**: `https://sso.securenexus.net/application/o/token/`
   - **Redirect URL**: `https://erp.byrneaccounting.net/api/method/frappe.integrations.oauth2_logins.custom/callback`
   - **API Endpoint**: `https://sso.securenexus.net/application/o/userinfo/`
   - **Icon**: Upload Authentik logo (optional)
   - Click **Save**

3. **Test SSO Login**:
   - Log out of ERPNext
   - Re-enable SSO middleware in Traefik
   - Access `https://erp.byrneaccounting.net`
   - You should be redirected to Authentik for authentication

### Step 3: Configure POS Access

POS access inherits the same SSO configuration as ERPNext since they share the same backend. No additional configuration needed.

Access POS at: `https://pos.byrneaccounting.net`

---

## AwesomePOS Configuration

### Initial Setup

1. **Access ERPNext**:
   - Navigate to: `https://erp.byrneaccounting.net`
   - Login via Authentik SSO

2. **Configure POS Profile**:
   - Go to: **Retail** → **POS Profile** → **Default POS Profile**
   - Configure:
     - **Company**: Select your company
     - **Warehouse**: Select default warehouse for POS transactions
     - **Price List**: `Standard Selling`
     - **Currency**: `USD` (or your currency)
     - **Payment Methods**: Add Cash, Credit Card, etc.
     - **Print Settings**: Configure receipt printing

3. **Set Up Items**:
   - Go to: **Stock** → **Item** → **New**
   - Create items to sell via POS
   - Set prices in the Price List

4. **Configure Users**:
   - Go to: **Users** → Select user
   - Assign role: **Sales User** or **POS User**
   - Link to **Employee** record if needed

### Accessing AwesomePOS

1. **Web Interface**:
   - Direct URL: `https://pos.byrneaccounting.net`
   - Or from ERPNext: Click **AwesomePOS** in the navigation menu

2. **Select POS Profile**:
   - Choose **Default POS Profile** (or create custom profiles)
   - Click **Open POS**

3. **Using POS**:
   - Search/scan items
   - Add to cart
   - Select payment method
   - Process payment
   - Print receipt (optional)

### Features

**Sales Processing**:
- Quick item search
- Barcode scanning support
- Quantity adjustments
- Discounts and pricing rules
- Multi-payment methods (cash, card, split payment)

**Inventory**:
- Real-time stock levels
- Low stock warnings
- Automatic inventory updates on sale

**Reporting**:
- Daily sales summary
- Payment method breakdown
- Top-selling items
- Cashier performance

**Offline Mode**:
- Continue sales when internet is down
- Automatic sync when connection restored
- Local data storage in browser

---

## DNS Configuration

### Internal DNS (CoreDNS)

DNS records are automatically configured in `dns/zones/byrneaccounting.net.zone`:

```dns
byrneaccounting.net.       IN  A      137.74.40.208
www.byrneaccounting.net.   IN  A      137.74.40.208
erp.byrneaccounting.net.   IN  A      137.74.40.208
pos.byrneaccounting.net.   IN  A      137.74.40.208
```

### Reload DNS Configuration

If you modify DNS records:

```bash
# Restart CoreDNS to reload zones
docker compose restart coredns

# Verify DNS resolution
dig @localhost byrneaccounting.net
dig @localhost erp.byrneaccounting.net
dig @localhost pos.byrneaccounting.net
```

### External DNS Delegation

**Option 1: A Records** (Simplest):
At your domain registrar, create A records pointing to your server IP.

**Option 2: NS Delegation** (Recommended for production):
Delegate `byrneaccounting.net` to your CoreDNS nameservers:
```
byrneaccounting.net.  NS  ns1.securenexus.net.
byrneaccounting.net.  NS  ns2.securenexus.net.
```

---

## Security Features

### Multi-Layer Security

**Layer 1: Firewall (UFW)**
- Only ports 80, 443 exposed for web traffic
- SSH rate limiting enabled
- Deny-by-default policy

**Layer 2: CrowdSec Intrusion Detection**
- Public website protected by `crowdsec-fa@file` middleware
- Automatic IP blocking for suspicious activity
- Community threat intelligence

**Layer 3: Traefik Security Headers**
- All services use `secure-headers@file` middleware
- HSTS, X-Frame-Options, CSP configured
- Prevents common web attacks

**Layer 4: Authentik SSO**
- ERP and POS require authentication via Authentik
- OAuth2/OpenID Connect
- Multi-factor authentication (MFA) support
- Session management and audit logging

**Layer 5: Let's Encrypt SSL**
- Automatic SSL certificate generation
- TLS 1.2+ only
- Perfect forward secrecy

### Security Best Practices

1. **Change Default Passwords**:
   ```bash
   # ERPNext admin password is in secrets/
   # Change it after first login via ERPNext UI
   ```

2. **Enable MFA in Authentik**:
   - Configure TOTP/WebAuthn for all users
   - Enforce MFA for ERP/POS access

3. **Regular Updates**:
   ```bash
   # Update ERPNext
   docker compose pull frappe/erpnext:latest
   docker compose up -d erpnext-backend erpnext-worker erpnext-scheduler
   ```

4. **Monitor Logs**:
   ```bash
   # Check for security events
   docker compose logs -f crowdsec
   docker compose logs -f traefik | grep -i error
   ```

5. **Backup Regularly**:
   ```bash
   # Automated backups via existing backup system
   ./scripts/backup-rotation.sh
   ```

---

## Troubleshooting

### ERPNext Won't Start

**Symptom**: `erpnext-backend` container keeps restarting

**Check logs**:
```bash
docker compose logs erpnext-backend
```

**Common issues**:

1. **Database not ready**:
   ```bash
   # Check PostgreSQL status
   docker compose ps erpnext-db
   # Wait 30 seconds and retry
   docker compose up -d erpnext-backend
   ```

2. **Redis connection failed**:
   ```bash
   # Verify Redis containers are running
   docker compose ps | grep erpnext-redis
   # Check password matches in compose.yml
   ```

3. **Permission issues**:
   ```bash
   # Fix volume permissions
   docker compose exec erpnext-backend chown -R frappe:frappe /home/frappe/frappe-bench/sites
   ```

### Cannot Access Website

**Symptom**: `https://byrneaccounting.net` returns 502/504 error

**Checks**:

1. **Verify container is running**:
   ```bash
   docker compose ps byrne-website
   # Should show "healthy"
   ```

2. **Check Traefik routing**:
   ```bash
   curl -H "Host: traefik.securenexus.net" http://localhost:8080/api/rawdata | jq '.routers'
   ```

3. **Verify DNS resolution**:
   ```bash
   dig byrneaccounting.net
   # Should return your server IP
   ```

4. **Check SSL certificate**:
   ```bash
   ls -la acme/acme.json
   # Should contain certificates
   ```

### SSO Not Working

**Symptom**: Redirected to Authentik but can't log in to ERPNext

**Checks**:

1. **Verify OAuth configuration**:
   - Check Client ID and Secret in ERPNext match Authentik
   - Verify Redirect URIs are correct
   - Ensure user has permission in Authentik application

2. **Check Authentik provider**:
   ```bash
   # View Authentik logs
   docker compose logs -f authentik_server
   ```

3. **Test OAuth flow manually**:
   ```bash
   curl -I https://erp.byrneaccounting.net
   # Should redirect to Authentik (302)
   ```

### AwesomePOS Installation Failed

**Symptom**: `make install-awesomepos` errors out

**Solutions**:

1. **Ensure ERPNext is fully initialized**:
   ```bash
   # Wait for ERPNext to finish starting
   docker compose logs -f erpnext-backend | grep -i "ready"
   ```

2. **Manual installation**:
   ```bash
   docker exec -it erpnext-backend bash
   cd /home/frappe/frappe-bench
   bench get-app https://github.com/ucraft-com/POS-Awesome
   bench --site erp.byrne-accounts.org install-app posawesome
   bench build --apps posawesome
   exit
   docker compose restart erpnext-backend
   ```

3. **Check for errors**:
   ```bash
   docker compose exec erpnext-backend bench --site erp.byrneaccounting.net console
   # Run: frappe.get_installed_apps()
   # Should include 'posawesome'
   ```

### Slow Performance

**Symptoms**: ERPNext or POS sluggish, timeouts

**Optimizations**:

1. **Increase Redis cache size**:
   ```yaml
   # In compose.yml, erpnext-redis-cache service
   command: [..., "--maxmemory 1g"]  # Increase from 512mb
   ```

2. **Add more resources to PostgreSQL**:
   ```yaml
   # Add under erpnext-db service
   deploy:
     resources:
       limits:
         memory: 2G
   ```

3. **Enable caching in ERPNext**:
   - Go to: **Settings** → **System Settings**
   - Enable **Enable Cache**
   - Set cache expiry appropriately

4. **Monitor resource usage**:
   ```bash
   docker stats | grep erpnext
   ```

---

## Backup and Maintenance

### Automated Backups

The Byrne Accounting data is included in the existing SecureNexus backup system:

```bash
# Manual backup
sudo ./scripts/backup-rotation.sh

# Automated daily backups via cron (already configured)
crontab -l | grep backup
```

**Backed up**:
- PostgreSQL database (ERPNext data)
- Redis data (cache and queues)
- ERPNext sites directory (files, attachments)
- Configuration files
- Secrets

**Backup location**: `/backup/securenexus/{daily,weekly,monthly}/`

### Manual Database Backup

**Backup ERPNext database**:
```bash
docker compose exec -T erpnext-db pg_dump -U erpnext erpnext > erpnext_backup_$(date +%Y%m%d).sql
```

**Restore ERPNext database**:
```bash
docker compose exec -T erpnext-db psql -U erpnext erpnext < erpnext_backup_YYYYMMDD.sql
```

### Maintenance Tasks

**Weekly**:
- Review Authentik audit logs for suspicious activity
- Check CrowdSec alerts
- Monitor disk space: `df -h`

**Monthly**:
- Update ERPNext to latest stable version
- Review and rotate old logs
- Test backup restoration
- Review user access permissions

**Quarterly**:
- Full security audit
- Update all Docker images
- Review and optimize database performance
- Update SSL certificates (automatic via Let's Encrypt)

### Updates

**Update ERPNext**:
```bash
# Pull latest version
docker compose pull frappe/erpnext

# Restart services
docker compose up -d erpnext-backend erpnext-worker erpnext-scheduler

# Run migrations
docker compose exec erpnext-backend bench --site erp.byrneaccounting.net migrate
```

**Update AwesomePOS**:
```bash
docker exec -it erpnext-backend bash -c "
cd /home/frappe/frappe-bench &&
bench update --app posawesome &&
bench build --apps posawesome
"
docker compose restart erpnext-backend
```

**Update Website**:
```bash
# Edit files in byrne-website/
# Rebuild and redeploy
make build-byrne-website
docker compose up -d byrne-website
```

---

## Quick Reference

### Service URLs

| Service | URL | Access |
|---------|-----|--------|
| Marketing Website | https://byrneaccounting.net | Public (CrowdSec protected) |
| Client Portal | https://byrneaccounting.net/portal | Public |
| ERPNext ERP | https://erp.byrneaccounting.net | SSO (Authentik) |
| Point of Sale | https://pos.byrneaccounting.net | SSO (Authentik) |

### Common Commands

```bash
# Deploy Byrne Accounting
make up-byrne

# Install AwesomePOS
make install-awesomepos

# View logs
docker compose logs -f erpnext-backend
docker compose logs -f byrne-website

# Restart services
docker compose restart erpnext-backend
docker compose restart byrne-website

# Stop all Byrne services
docker compose stop byrne-website erpnext-backend erpnext-worker erpnext-scheduler erpnext-db erpnext-redis-cache erpnext-redis-queue

# Access ERPNext shell
docker compose exec erpnext-backend bash

# ERPNext console
docker compose exec erpnext-backend bench --site erp.byrneaccounting.net console

# Database backup
docker compose exec -T erpnext-db pg_dump -U erpnext erpnext > backup.sql
```

### Key Files

| File | Purpose |
|------|---------|
| `compose.yml` | Service definitions (lines 714-912) |
| `byrne-website/` | Marketing website source code |
| `byrne-scripts/install-awesomepos.sh` | AwesomePOS installation script |
| `dns/zones/byrneaccounting.net.zone` | DNS zone file |
| `secrets/erpnext_admin_password.txt` | ERPNext admin password |
| `secrets/erpnext_db_password.txt` | PostgreSQL password |

### Support Resources

- **ERPNext Documentation**: https://docs.erpnext.com/
- **POS Awesome GitHub**: https://github.com/ucraft-com/POS-Awesome
- **Frappe Framework Docs**: https://frappeframework.com/docs
- **Authentik Docs**: https://goauthentik.io/docs/
- **Traefik Docs**: https://doc.traefik.io/traefik/

---

## Conclusion

Your Byrne Accounting system is now fully deployed with:

✅ Professional marketing website
✅ Complete ERP system with ERPNext
✅ Modern POS system with AwesomePOS
✅ Enterprise-grade security (SSO, HTTPS, intrusion detection)
✅ Automated backups
✅ Full integration with SecureNexus infrastructure

**Next Steps**:
1. Configure Authentik SSO integration
2. Set up users and permissions
3. Import your accounting data
4. Configure POS profiles and items
5. Train staff on ERPNext and POS usage

For additional support or questions, refer to the SecureNexus documentation in `docs/`.
