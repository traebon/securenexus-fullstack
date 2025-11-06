# Multi-Tenant ERPNext Infrastructure

**Architecture:** Isolated instances with shared infrastructure
**Platform:** ERPNext (Frappe Framework)
**Current Clients:** 2 (Byrne Accounting, Dickinson Supplies)
**Capacity:** 10+ clients per host

---

## Overview

SecureNexus provides a multi-tenant ERPNext infrastructure where each client gets a completely isolated ERP instance with dedicated databases, custom branding, and SSO integration, while sharing the underlying infrastructure for efficiency.

---

## Architecture

### Isolation Model

Each client receives:
- ✅ **Dedicated MariaDB database** - Complete data isolation
- ✅ **Dedicated Redis instances** - Cache and queue separation (2 per client)
- ✅ **Dedicated site directory** - File and asset isolation
- ✅ **Custom domain** - Client-specific URL
- ✅ **Custom branding** - Logos, colors, themes
- ✅ **SSO integration** - Secure authentication via Authentik

### Shared Components

Clients share:
- Traefik reverse proxy - SSL and routing
- Authentik SSO platform - Identity management
- Monitoring stack - Prometheus, Grafana
- Backup system - Automated backups
- DNS infrastructure - CoreDNS
- Network layer - Docker proxy network

---

## Deployed Clients

### 1. Byrne Accounting

**Domain:** byrne-accounts.org
**Status:** ✅ Production

**Services:**
- **ERP:** https://erp.byrne-accounts.org
- **POS:** https://pos.byrne-accounts.org
- **Website:** https://byrne-accounts.org
- **Portal:** https://portal.byrne-accounts.org
- **SSO:** https://auth.byrne-accounts.org

**Infrastructure:**
```yaml
# Database
byrne_db (MariaDB 10.6)
- Volume: erpnext-db-data
- Size: ~50MB
- Secret: erpnext_db_password

# Redis Cache
erpnext_redis_cache (Redis 7)
- Volume: erpnext-redis-cache-data
- Memory: 512MB
- Policy: allkeys-lru

# Redis Queue
erpnext_redis_queue (Redis 7)
- Volume: erpnext-redis-queue-data
- Memory: 512MB
- Policy: allkeys-lru

# Application
erpnext_backend (Frappe/ERPNext)
- Image: frappe/erpnext:latest
- Sites: erp.byrne-accounts.org
- Workers: 4 (web, worker, scheduler, socketio)
```

**Branding:**
- Theme: Blue/Green professional
- Logo: Custom Byrne logo
- Colors: #3b82f6 (blue), #10b981 (green)
- Favicon: Custom
- Login page: Branded

**Features:**
- Full accounting suite
- POS Awesome integration
- Inventory management
- Invoicing and billing
- Client portal access
- Automated backups

---

### 2. Dickinson Supplies

**Domain:** dickson-supplies.com
**Status:** ✅ Production

**Services:**
- **ERP:** https://erp.dickson-supplies.com
- **SSO:** Auth via Authentik

**Infrastructure:**
```yaml
# Database
dickson_db (MariaDB 10.6)
- Volume: dickson-db-data
- Size: ~30MB
- Secret: dickson_db_password

# Redis Cache
dickson_redis_cache (Redis 7)
- Volume: dickson-redis-cache-data
- Memory: 512MB

# Redis Queue
dickson_redis_queue (Redis 7)
- Volume: dickson-redis-queue-data
- Memory: 512MB

# Application
dickson_backend (Frappe/ERPNext)
- Image: frappe/erpnext:latest
- Sites: erp.dickson-supplies.com
- Workers: 4
```

**Branding:**
- Theme: Corporate professional
- Custom logo and colors
- Professional layout

**Features:**
- Accounting modules
- Inventory tracking
- Supply chain management
- SSO integration

---

## Technical Details

### Database Architecture

**MariaDB Configuration:**
```yaml
character-set-server: utf8mb4
collation-server: utf8mb4_unicode_ci
skip-character-set-client-handshake: true
skip-innodb-read-only-compressed: true
```

**Per-Client Schema:**
- Each client has a completely separate database
- No shared tables or data
- Independent backups and restores
- Separate user credentials

### Redis Architecture

**Cache Instance (per client):**
- Stores session data
- Caches database queries
- 512MB memory limit
- LRU eviction policy
- Persistent via AOF

**Queue Instance (per client):**
- Background job queue
- Asynchronous task processing
- Email queue
- Report generation
- 512MB memory limit

### Application Structure

**Frappe Bench Multi-Site:**
```
/workspace/frappe-bench/
├── sites/
│   ├── erp.byrne-accounts.org/
│   │   ├── site_config.json
│   │   ├── private/files/
│   │   └── public/files/
│   └── erp.dickson-supplies.com/
│       ├── site_config.json
│       ├── private/files/
│       └── public/files/
├── apps/
│   ├── frappe/
│   ├── erpnext/
│   └── posawesome/
└── config/
```

---

## Client Onboarding Process

### Automated Provisioning

**One Command:**
```bash
./scripts/provision-client-complete.sh client-name client-domain.com
```

**Steps Performed:**
1. Create database and Redis instances
2. Generate secure secrets
3. Create ERPNext site
4. Configure DNS records
5. Generate SSL certificates
6. Apply custom branding
7. Configure SSO integration
8. Create admin user
9. Run setup wizard
10. Verify deployment

**Time:** ~15-20 minutes fully automated

### Manual Steps (if needed)

1. **Prepare Environment:**
```bash
# Generate secrets
./scripts/generate-secrets.sh

# Update .env with domain
echo "CLIENT_DOMAIN=client-name.com" >> .env
```

2. **Create Infrastructure:**
```bash
# Add service definitions to compose.yml
# Add DNS zone file
# Add SSL certificate configuration
```

3. **Deploy Services:**
```bash
docker compose up -d client_db client_redis_cache client_redis_queue client_backend
```

4. **Create ERP Site:**
```bash
docker compose exec client_backend bench new-site erp.client-name.com \
  --admin-password "$(cat secrets/client_admin_password.txt)" \
  --db-name client_erp \
  --mariadb-root-password "$(cat secrets/client_db_password.txt)"
```

5. **Install Apps:**
```bash
docker compose exec client_backend bench --site erp.client-name.com install-app erpnext
docker compose exec client_backend bench --site erp.client-name.com install-app posawesome
```

6. **Configure SSO:**
```bash
./scripts/setup-client-sso.sh client-name
```

7. **Apply Branding:**
```bash
./scripts/apply-client-theme.sh client-name
```

---

## SSO Integration

### Authentik Configuration

**For Each Client:**

1. **Create OAuth Provider:**
   - Client Type: Confidential
   - Client ID: `erpnext-{client}`
   - Redirect URI: `https://erp.{domain}/api/method/frappe.integrations.oauth2_logins.custom/authentik`
   - Scopes: `openid profile email`

2. **Create Application:**
   - Name: `{Client} ERP`
   - Slug: `{client}-erp`
   - Provider: Link to OAuth provider
   - Launch URL: `https://erp.{domain}`

3. **Configure Attribute Mapping:**
   - Email: `email`
   - Username: `preferred_username`
   - Full Name: `name`

### ERPNext Configuration

**Site Config (`site_config.json`):**
```json
{
  "host_name": "https://erp.client-domain.com",
  "oauth_providers": [{
    "name": "authentik",
    "provider_name": "Authentik",
    "client_id": "erpnext-client",
    "client_secret": "secret_value",
    "authorize_url": "https://sso.securenexus.net/application/o/authorize/",
    "access_token_url": "https://sso.securenexus.net/application/o/token/",
    "api_endpoint": "https://sso.securenexus.net/application/o/userinfo/",
    "redirect_uri": "https://erp.client-domain.com/api/method/frappe.integrations.oauth2_logins.custom/authentik"
  }]
}
```

---

## Branding & Customization

### Theme Application

**Automated:**
```bash
./scripts/apply-client-theme.sh client-name
```

**Manual Steps:**

1. **Upload Logo:**
```bash
docker compose cp /path/to/logo.png client_backend:/workspace/frappe-bench/sites/erp.client.com/public/files/
```

2. **Apply Custom CSS:**
```css
/* Custom theme colors */
:root {
  --primary-color: #3b82f6;
  --secondary-color: #10b981;
  --text-color: #1f2937;
}

.navbar-brand img {
  max-height: 40px;
}
```

3. **Configure Website Settings:**
   - Company name
   - Company logo
   - Favicon
   - Brand colors
   - Footer text

4. **Customize Print Formats:**
   - Letterhead
   - Invoice template
   - Receipt format
   - Company address

---

## Backup & Recovery

### Automated Backups

**Schedule:** Daily at 2:00 AM

**What's Backed Up:**
- MariaDB databases (per client)
- Redis data (cache + queue)
- Site directories (files, assets)
- Configuration files
- SSL certificates

**Backup Script:**
```bash
./scripts/backup-all.sh
```

**Restoration:**
```bash
# Restore database
docker compose exec -T client_db mysql -u root -p$(cat secrets/client_db_password.txt) \
  client_erp < /backup/path/client_db.sql

# Restore site files
docker compose cp /backup/path/client-sites.tar.gz client_backend:/tmp/
docker compose exec client_backend tar -xzf /tmp/client-sites.tar.gz -C /workspace/frappe-bench/sites/
```

### Manual Backup

**ERPNext Built-in:**
```bash
# Create backup
docker compose exec client_backend bench --site erp.client.com backup

# Download backup
docker compose cp client_backend:/workspace/frappe-bench/sites/erp.client.com/private/backups/ ./backups/
```

---

## Monitoring

### Health Checks

**Database:**
```bash
docker compose exec client_db mysql -u root -p$(cat secrets/client_db_password.txt) -e "STATUS;"
```

**Redis:**
```bash
docker compose exec client_redis_cache redis-cli -a "$(cat secrets/client_redis_cache_password.txt)" ping
```

**Application:**
```bash
docker compose exec client_backend bench --site erp.client.com doctor
```

### Metrics

**Exposed Metrics:**
- Database connections (via PostgreSQL exporter)
- Redis performance (via Redis exporter)
- Container resources (via cAdvisor)
- Response times (via Prometheus)

**Dashboards:**
- Grafana: `https://grafana.securenexus.net`
- Custom ERP dashboard available

---

## Scaling

### Vertical Scaling

**Increase Resources:**
```yaml
client_backend:
  deploy:
    resources:
      limits:
        cpus: '2.0'
        memory: 4G
      reservations:
        cpus: '1.0'
        memory: 2G
```

### Horizontal Scaling

**Add Workers:**
```yaml
client_backend_worker_2:
  image: frappe/erpnext:latest
  command: worker
  # Same configuration as main worker
```

**Load Balancing:**
```yaml
traefik.http.services.client-erp.loadbalancer.servers:
  - url: http://client_backend:8000
  - url: http://client_backend_worker_2:8000
```

### Database Replication

**Master-Slave Setup:**
```yaml
client_db_replica:
  image: mariadb:10.6
  environment:
    MARIADB_REPLICATION_MODE: slave
    MARIADB_MASTER_HOST: client_db
```

---

## Capacity Planning

### Current Usage (per client)

| Resource | Usage | Limit | Headroom |
|----------|-------|-------|----------|
| CPU | 5-10% | 100% | 90% |
| Memory | 500MB | 2GB | 75% |
| Disk | 100MB | 100GB | 99.9% |
| Connections | 10 | 100 | 90% |

### Maximum Capacity

**Per Host:**
- CPU cores: 8
- Memory: 32GB
- Storage: 1TB

**Estimated Capacity:**
- Light users (< 10 users): 20+ clients
- Medium users (10-50 users): 10-15 clients
- Heavy users (50+ users): 5-10 clients

---

## Troubleshooting

### Common Issues

**1. Site Not Loading**
```bash
# Check if site exists
docker compose exec client_backend bench --site erp.client.com show-config

# Rebuild
docker compose exec client_backend bench --site erp.client.com migrate
docker compose exec client_backend bench --site erp.client.com build
```

**2. Database Connection Failed**
```bash
# Test connection
docker compose exec client_backend bench --site erp.client.com mariadb

# Check credentials in site_config.json
docker compose exec client_backend cat sites/erp.client.com/site_config.json
```

**3. Redis Connection Issues**
```bash
# Test Redis cache
docker compose exec client_redis_cache redis-cli -a "password" ping

# Check configuration
docker compose exec client_backend bench --site erp.client.com console
>>> frappe.cache().ping()
```

**4. SSO Not Working**
- Verify OAuth provider configuration in Authentik
- Check redirect URI matches exactly
- Review ERPNext site_config.json OAuth settings
- Check Authentik logs for errors

---

## Security

### Best Practices

- ✅ Each client has unique database passwords
- ✅ Redis instances password-protected
- ✅ Admin accounts use strong passwords
- ✅ SSO enforced for all users
- ✅ Regular security updates
- ✅ Firewall rules restrictive
- ✅ SSL/TLS enforced
- ✅ Backups encrypted

### Access Control

**Admin Access:**
- Via SSO only (Authentik)
- VPN required for backend access
- SSH keys only (no password auth)

**User Access:**
- SSO via Authentik
- Role-based permissions in ERPNext
- Session timeout enforced
- Failed login monitoring

---

## Documentation

**Internal Guides:**
- `docs/MULTI_TENANT_ERP_SETUP.md` - Setup guide
- `docs/CLIENT_ONBOARDING_GUIDE.md` - Onboarding process
- `docs/COMPLETE_CLIENT_PROVISIONING_GUIDE.md` - Automation guide
- `docs/BYRNE_DEPLOYMENT_SUMMARY.md` - Byrne specifics
- `docs/DICKINSON_SUPPLIES_BRANDING.md` - Dickinson specifics

**ERPNext Resources:**
- [ERPNext Docs](https://docs.erpnext.com)
- [Frappe Framework](https://frappeframework.com)
- [ERPNext Forum](https://discuss.erpnext.com)

---

**Last Updated:** November 6, 2025
**Clients:** 2 active
**Status:** ✅ Production Ready
