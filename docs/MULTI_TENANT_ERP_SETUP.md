# Multi-Tenant ERP Architecture
## Byrne Accounting + Dickson Supplies

**Last Updated**: November 5, 2025
**Status**: Ready for Deployment
**Architecture**: Multi-Tenant ERPNext with Separate Databases

---

## Overview

This infrastructure supports **two completely separate ERP instances**:

### 1. Byrne Accounting (Your Systems)
- **Purpose**: Internal accounting and POS system
- **Domains**:
  - `erp.byrne-accounts.org` - Main ERP system
  - `pos.byrne-accounts.org` - Point of Sale interface
- **Theme**: SecureNexus Global (Blue #3b82f6 / Green #10b981)
- **Docker Profile**: `byrne`
- **Containers**: 7 containers (db, redis-cache, redis-queue, configurator, backend, socketio, worker, scheduler)

### 2. Dickson Supplies (Client System)
- **Purpose**: Client pharmaceutical retail ERP
- **Domains**:
  - `erp.dickson-supplies.com` - Main ERP system
  - `pos.dickson-supplies.com` - Point of Sale interface
- **Theme**: Dickson Pharmaceutical (Medical Blue #0066cc / Healthcare Teal #00A99D)
- **Docker Profile**: `dickson`
- **Containers**: 7 containers (separate database, caches, workers)

---

## Architecture Benefits

✅ **Complete Isolation**: Separate databases, Redis instances, and worker queues
✅ **Independent Scaling**: Scale each tenant independently
✅ **Custom Branding**: Different themes per client
✅ **SSO Integration**: Both instances integrate with Authentik
✅ **Data Security**: No shared data between tenants
✅ **Independent Backups**: Separate backup strategies per tenant

---

## Directory Structure

```
securenexus-fullstack/
├── compose.yml                          # Main compose file with both profiles
├── erp/
│   ├── byrne-branding/                  # Byrne theme files
│   │   └── byrne-securenexus-theme.css
│   └── dickson-branding/                # Dickson theme files
│       ├── dickson-theme.css
│       └── dickson-pos-theme.css
├── secrets/
│   ├── erpnext_*.txt                    # Byrne secrets
│   └── dickson_*.txt                    # Dickson secrets
└── docs/
    ├── MULTI_TENANT_ERP_SETUP.md        # This file
    └── DICKSON_SUPPLIES_BRANDING.md     # Dickson branding guide
```

---

## Docker Volumes

### Byrne Accounting
- `erpnext-db-data` - MariaDB database
- `erpnext-redis-cache-data` - Redis cache
- `erpnext-redis-queue-data` - Redis job queue
- `erpnext-sites-data` - ERPNext site files
- `erpnext-assets-data` - Static assets

### Dickson Supplies
- `dickson-db-data` - MariaDB database
- `dickson-redis-cache-data` - Redis cache
- `dickson-redis-queue-data` - Redis job queue
- `dickson-sites-data` - ERPNext site files
- `dickson-assets-data` - Static assets

---

## Secrets Configuration

### Byrne Secrets
```bash
secrets/erpnext_db_password.txt
secrets/erpnext_admin_password.txt
secrets/erpnext_redis_cache_password.txt
secrets/erpnext_redis_queue_password.txt
```

### Dickson Secrets
```bash
secrets/dickson_db_password.txt
secrets/dickson_admin_password.txt
secrets/dickson_redis_cache_password.txt
secrets/dickson_redis_queue_password.txt
```

All secrets are automatically generated and stored securely.

---

## DNS Configuration

### Required DNS Records

Point these A records to your server IP:

**Byrne Accounting**:
```
erp.byrne-accounts.org    A    YOUR_SERVER_IP
pos.byrne-accounts.org    A    YOUR_SERVER_IP
```

**Dickson Supplies**:
```
erp.dickson-supplies.com  A    YOUR_SERVER_IP
pos.dickson-supplies.com  A    YOUR_SERVER_IP
```

**SSL Certificates**: Traefik will automatically provision Let's Encrypt certificates for all domains.

---

## Deployment Instructions

### Prerequisites

1. ✅ Core infrastructure running (`docker compose --profile core up -d`)
2. ✅ DNS records configured and propagated
3. ✅ All secrets generated
4. ✅ Theme files ready in `/tmp/`

### Step 1: Start Byrne Accounting (Already Running)

```bash
# Byrne instance should already be running
docker compose ps | grep erpnext

# If not running:
docker compose --profile byrne up -d
```

### Step 2: Apply Byrne Theme

```bash
# Copy theme script to project
cp /tmp/apply-byrne-theme.sh scripts/
chmod +x scripts/apply-byrne-theme.sh

# Apply SecureNexus Global theme
./scripts/apply-byrne-theme.sh
```

### Step 3: Start Dickson Supplies

```bash
# First, ensure theme files are in place
# If erp/dickson-branding doesn't exist (owned by root):
sudo cp -r /tmp/dickson-branding /home/tristian/securenexus-fullstack/erp/dickson-branding

# Start Dickson instance
docker compose --profile dickson up -d

# Monitor startup
docker compose logs -f dickson-backend
```

### Step 4: Apply Dickson Theme

```bash
# Copy theme script
cp /tmp/apply-dickson-theme.sh scripts/
chmod +x scripts/apply-dickson-theme.sh

# Wait for Dickson instance to be fully started (2-3 minutes)
docker compose ps | grep dickson

# Apply Dickson Pharmaceutical theme
./scripts/apply-dickson-theme.sh
```

### Step 5: Configure SSO (Both Instances)

See `docs/ERPNEXT_SSO_SETUP.md` for detailed SSO configuration.

**Quick Setup**:
1. Create Authentik applications for each instance
2. Configure OAuth2/OIDC providers
3. Set redirect URLs correctly
4. Test login flow

---

## Theme Details

### Byrne - SecureNexus Global Theme

**Colors**:
- Primary Blue: `#3b82f6`
- Success Green: `#10b981`
- Indigo Accent: `#6366f1`
- Teal Accent: `#14b8a6`

**Features**:
- Modern gradient navigation (Blue → Green)
- Professional dark sidebar
- Clean, minimalist design
- SecureNexus branding elements
- Optimized for accounting workflows

**CSS Location**: `erp/byrne-branding/byrne-securenexus-theme.css`

### Dickson - Pharmaceutical Theme

**Colors**:
- Medical Blue: `#0066cc`
- Healthcare Teal: `#00A99D`
- Pharmacy Green: `#2D9F84`
- Prescription Red: `#DC3545`

**Features**:
- Professional pharmaceutical color scheme
- Prescription indicators (℞ symbol)
- Low stock warnings
- Medical-grade UI elements
- Pharmacy-specific styling

**CSS Locations**:
- Main theme: `erp/dickson-branding/dickson-theme.css`
- POS theme: `erp/dickson-branding/dickson-pos-theme.css`

---

## Management Commands

### Start/Stop Services

```bash
# Start Byrne only
docker compose --profile byrne up -d

# Start Dickson only
docker compose --profile dickson up -d

# Start both
docker compose --profile byrne --profile dickson up -d

# Stop specific instance
docker compose stop erpnext-backend erpnext-worker erpnext-scheduler  # Byrne
docker compose stop dickson-backend dickson-worker dickson-scheduler  # Dickson

# Stop all
docker compose down
```

### View Logs

```bash
# Byrne logs
docker compose logs -f erpnext-backend

# Dickson logs
docker compose logs -f dickson-backend

# All ERPNext services
docker compose logs -f | grep -E "(erpnext|dickson)"
```

### Access Database

```bash
# Byrne database
docker compose exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt)

# Dickson database
docker compose exec dickson-db mysql -u root -p$(cat secrets/dickson_db_password.txt)
```

### Clear Cache

```bash
# Byrne
docker exec erpnext-backend bench --site erp.byrne-accounts.org clear-cache

# Dickson
docker exec dickson-backend bench --site erp.dickson-supplies.com clear-cache
```

---

## Backup Strategy

### Byrne Backup

```bash
# Database
docker compose exec -T erpnext-db mysqldump \
  -u root -p$(cat secrets/erpnext_db_password.txt) \
  --all-databases > /backup/byrne-erp-$(date +%Y%m%d).sql

# Sites data
docker run --rm -v erpnext-sites-data:/data -v /backup:/backup \
  alpine tar -czf /backup/byrne-sites-$(date +%Y%m%d).tar.gz -C /data .

# Assets
docker run --rm -v erpnext-assets-data:/data -v /backup:/backup \
  alpine tar -czf /backup/byrne-assets-$(date +%Y%m%d).tar.gz -C /data .
```

### Dickson Backup

```bash
# Database
docker compose exec -T dickson-db mysqldump \
  -u root -p$(cat secrets/dickson_db_password.txt) \
  --all-databases > /backup/dickson-erp-$(date +%Y%m%d).sql

# Sites data
docker run --rm -v dickson-sites-data:/data -v /backup:/backup \
  alpine tar -czf /backup/dickson-sites-$(date +%Y%m%d).tar.gz -C /data .

# Assets
docker run --rm -v dickson-assets-data:/data -v /backup:/backup \
  alpine tar -czf /backup/dickson-assets-$(date +%Y%m%d).tar.gz -C /data .
```

---

## Monitoring

Both instances are monitored via:
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Uptime Kuma**: Availability monitoring
- **Loki**: Log aggregation

### Health Checks

```bash
# Check all containers
docker compose ps

# Byrne health
curl -H "Host: erp.byrne-accounts.org" http://localhost:8000/api/method/ping

# Dickson health
curl -H "Host: erp.dickson-supplies.com" http://localhost:8000/api/method/ping
```

---

## Troubleshooting

### Issue: Dickson instance won't start

**Solution**:
```bash
# Check logs
docker compose logs dickson-configurator

# Ensure database is healthy
docker compose ps dickson-db

# Recreate configurator
docker compose rm -f dickson-configurator
docker compose --profile dickson up -d dickson-configurator
```

### Issue: Theme not loading

**Solution**:
```bash
# For Byrne
./scripts/apply-byrne-theme.sh

# For Dickson
./scripts/apply-dickson-theme.sh

# Clear browser cache (Ctrl+Shift+Delete)
# Hard refresh (Ctrl+F5)
```

### Issue: SSL certificate not provisioning

**Solution**:
```bash
# Check DNS propagation
dig erp.dickson-supplies.com

# Check Traefik logs
docker compose logs traefik | grep -i "dickson\|acme"

# Force certificate renewal
docker compose restart traefik
```

---

## Security Considerations

1. **Separate Databases**: Each tenant has completely isolated data
2. **Secret Management**: Unique passwords for each instance
3. **Network Isolation**: Services communicate only within their profile
4. **SSL/TLS**: Automatic HTTPS for all domains
5. **SSO Integration**: Centralized authentication via Authentik
6. **Regular Backups**: Automated backup rotation
7. **Monitoring**: Real-time alerts for issues

---

## Access Information

### Byrne Accounting

**URLs**:
- ERP: https://erp.byrne-accounts.org
- POS: https://pos.byrne-accounts.org

**Admin Credentials**:
```bash
Username: Administrator
Password: $(cat secrets/erpnext_admin_password.txt)
```

### Dickson Supplies

**URLs**:
- ERP: https://erp.dickson-supplies.com
- POS: https://pos.dickson-supplies.com

**Admin Credentials**:
```bash
Username: Administrator
Password: $(cat secrets/dickson_admin_password.txt)
```

---

## Next Steps

1. ✅ Deploy Dickson instance
2. ✅ Apply themes to both systems
3. ⏳ Configure SSO for both instances
4. ⏳ Create user accounts
5. ⏳ Set up automated backups
6. ⏳ Configure monitoring alerts
7. ⏳ Train users on new systems

---

## Support & Maintenance

**Byrne Accounting**: Maintained by Tristian (SecureNexus Admin)
**Dickson Supplies**: Client-managed with SecureNexus infrastructure support

For issues, check:
1. Container logs: `docker compose logs -f [service]`
2. System documentation: `docs/`
3. ERPNext docs: https://docs.erpnext.com
4. Frappe forum: https://discuss.frappe.io

---

**Document Version**: 1.0
**Created**: November 5, 2025
**Author**: Claude Code (SecureNexus Infrastructure)
