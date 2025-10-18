# ERPNext Deployment Guide for SecureNexus

## Overview

This document provides a comprehensive guide for deploying, configuring, and managing ERPNext within the SecureNexus infrastructure. The deployment includes:

- **Frappe/ERPNext** (latest): Full ERP system with integrated POS
- **MariaDB 10.6**: Primary database backend
- **Redis**: Cache and queue management (2 separate instances)
- **Traefik Integration**: Automatic SSL, reverse proxy, load balancing
- **Authentik SSO**: Single sign-on via OAuth2/OpenID Connect
- **Custom Branding**: SecureNexus theme with logo and CSS customization
- **Automated Backups**: Integrated with existing backup rotation system
- **Monitoring**: Prometheus metrics and Uptime Kuma health checks

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Traefik (Reverse Proxy)              │
│   https://erp.byrne-accounts.org                            │
│   https://pos.byrne-accounts.org                            │
└──────────────┬──────────────────────────────────────────────┘
               │
               ├─────> ERPNext Backend (gunicorn on :8000)
               │       ├─> Sites Data (Docker volume)
               │       └─> Assets (Docker volume)
               │
               ├─────> ERPNext SocketIO (:9000)
               │       └─> Real-time updates, notifications
               │
               ├─────> ERPNext Worker
               │       └─> Background jobs (default, short, long queues)
               │
               └─────> ERPNext Scheduler
                       └─> Cron jobs, scheduled tasks

┌─────────────────────────────────────────────────────────────┐
│                     Backend Services                         │
├─────────────────────────────────────────────────────────────┤
│  MariaDB 10.6        - Primary database                     │
│  Redis (cache)       - L1 cache (512MB LRU)                 │
│  Redis (queue)       - Background job queue                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     Security & Auth                          │
├─────────────────────────────────────────────────────────────┤
│  Authentik SSO       - OAuth2/OpenID provider               │
│  Traefik             - SSL termination, rate limiting        │
│  CrowdSec            - Intrusion detection                   │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Domain Configuration**:
   - DNS records for `erp.byrne-accounts.org` pointing to server IP
   - DNS records for `pos.byrne-accounts.org` pointing to server IP
   - DNS records for `byrne-accounts.org` and `www.byrne-accounts.org`

2. **Existing Services**:
   - Core infrastructure (`make up-core`)
   - Identity services (`make up-identity`)
   - DNS services (`make up-dns`)

3. **Secrets**:
   - All secrets must be generated: `make secrets`

## Initial Deployment

### Step 1: Generate Secrets

```bash
make secrets
```

This generates:
- `erpnext_db_password.txt` - MariaDB root password
- `erpnext_admin_password.txt` - ERPNext Administrator password
- `erpnext_redis_cache_password.txt` - Redis cache password
- `erpnext_redis_queue_password.txt` - Redis queue password

### Step 2: Deploy Byrne Accounting Stack

```bash
make up-byrne
```

This command:
1. Builds the Byrne Accounting website Docker image
2. Starts MariaDB and Redis services
3. Waits 15 seconds for databases to be ready
4. Runs the `erpnext-configurator` container to initialize the site
5. Starts ERPNext backend, SocketIO, worker, and scheduler services
6. Deploys the Byrne Accounting marketing website

**Expected Duration**: 5-10 minutes (first run includes site creation)

### Step 3: Verify Deployment

```bash
# Check service health
docker compose ps | grep erpnext

# Follow backend logs
make erp-logs

# Check all Byrne services
make byrne-logs
```

Expected output:
```
erpnext-backend      Up (healthy)
erpnext-db           Up (healthy)
erpnext-redis-cache  Up (healthy)
erpnext-redis-queue  Up (healthy)
erpnext-worker       Up
erpnext-scheduler    Up
erpnext-socketio     Up
```

### Step 4: Initial Login

1. Navigate to: https://erp.byrne-accounts.org
2. Login credentials:
   - **Username**: `Administrator`
   - **Password**: `cat secrets/erpnext_admin_password.txt`
3. Complete the ERPNext Setup Wizard:
   - Company name, country, currency, fiscal year, etc.

## Custom Branding Installation

After the initial setup wizard is complete, apply SecureNexus branding:

```bash
make erp-branding
```

This script performs the following:
1. Uploads SecureNexus logo from `branding/logo.png`
2. Updates System Settings:
   - App name: "Byrne Accounting ERP"
   - Country: Ireland
   - Timezone: Europe/Dublin
3. Updates Website Settings:
   - Banner HTML with logo
   - Brand HTML with logo
   - Disables public signup
4. Applies custom CSS theme:
   - Primary color: #3b82f6 (SecureNexus blue)
   - Secondary color: #10b981 (SecureNexus green)
   - Custom gradients and styling

**Verification**:
- Clear browser cache
- Refresh ERPNext page
- Logo should appear in navbar and login page
- Colors should match SecureNexus theme

## Authentik SSO Integration

### Prerequisites

1. Access to Authentik admin panel: https://sso.securenexus.net
2. Authentik admin credentials

### Step 1: Create OAuth Provider in Authentik

1. Login to Authentik admin interface
2. Navigate to **Applications** > **Providers**
3. Click **Create** > Select **OAuth2/OpenID Provider**
4. Configuration:
   - **Name**: `ERPNext`
   - **Client Type**: `Confidential`
   - **Redirect URIs**: `https://erp.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik`
   - **Subject mode**: `Based on the User's username`
   - **Scopes**: `email`, `profile`, `openid`
5. Save and note:
   - **Client ID**
   - **Client Secret**

### Step 2: Create Application in Authentik

1. Navigate to **Applications** > **Applications**
2. Click **Create**
3. Configuration:
   - **Name**: `ERPNext - Byrne Accounting`
   - **Slug**: `erpnext`
   - **Provider**: Select the provider created in Step 1
   - **Launch URL**: `https://erp.byrne-accounts.org`
4. Save

### Step 3: Configure ERPNext SSO

```bash
export CLIENT_ID='your-client-id-from-authentik'
export CLIENT_SECRET='your-client-secret-from-authentik'
make erp-sso
```

This script:
1. Creates a Social Login Key in ERPNext for Authentik
2. Configures OAuth endpoints
3. Enables social login in System Settings

**Verification**:
1. Logout of ERPNext
2. You should see "Login with Authentik SSO" button
3. Click button to test SSO login
4. Should redirect to Authentik, then back to ERPNext after auth

## AwesomePOS Installation & Configuration

### Overview

**AwesomePOS** is a modern, feature-rich Point of Sale application for ERPNext that provides:
- Intuitive touch-friendly interface
- Real-time inventory synchronization
- Offline mode capability
- Multiple payment methods
- Receipt printing
- Sales analytics
- Customer loyalty programs
- Barcode scanning support

### Installation

**Prerequisites**:
- ERPNext backend must be fully initialized and healthy
- Site `erp.byrne-accounts.org` must be created and functional

**Install AwesomePOS**:
```bash
# Automated installation via Makefile
make install-awesomepos

# Manual installation (if needed)
docker exec -it erpnext-backend bash -c "
  cd /home/frappe/frappe-bench &&
  bench get-app https://github.com/ucraft-com/POS-Awesome &&
  bench --site erp.byrne-accounts.org install-app posawesome &&
  bench build --apps posawesome
"

# Restart services
docker compose restart erpnext-backend erpnext-worker
```

**Expected duration**: 3-5 minutes

**Verify installation**:
```bash
make erp-shell
bench --site erp.byrne-accounts.org list-apps
# Should show: frappe, erpnext, posawesome
```

### Initial Configuration

#### 1. Create POS Profile

Via ERPNext UI:
1. Navigate to: **Retail** → **POS Profile** → **New**
2. Configure basic settings:
   - **Profile Name**: `Store Counter 1` (or your preference)
   - **Company**: Select your company
   - **Warehouse**: Select default warehouse for sales
   - **Currency**: `EUR` (or your currency)
   - **Price List**: `Standard Selling`

3. Configure payment methods:
   - Add **Cash** (set as default)
   - Add **Credit Card**
   - Add **Debit Card**
   - Add other methods as needed

4. Set accounting defaults:
   - **Income Account**: `Sales - BA`
   - **Cost Center**: `Main - BA`
   - **Write Off Account**: `Write Off - BA`
   - **Write Off Cost Center**: `Main - BA`

5. **Save**

#### 2. Configure via Console (Alternative)

```bash
make erp-shell
bench --site erp.byrne-accounts.org console
```

```python
import frappe

# Create POS Profile
pos_profile = frappe.get_doc({
    'doctype': 'POS Profile',
    'name': 'Store Counter 1',
    'company': 'Byrne Accounting Ltd',
    'warehouse': 'Stores - BA',  # Replace with your warehouse
    'currency': 'EUR',
    'selling_price_list': 'Standard Selling',
    'write_off_account': 'Write Off - BA',
    'write_off_cost_center': 'Main - BA',
    'payments': [
        {'mode_of_payment': 'Cash', 'default': 1},
        {'mode_of_payment': 'Credit Card'},
        {'mode_of_payment': 'Debit Card'}
    ]
})
pos_profile.insert()
frappe.db.commit()
print("POS Profile created successfully!")
```

#### 3. Set Up Items for POS

Create items that will be sold via POS:

1. Navigate to: **Stock** → **Item** → **New**
2. Fill in item details:
   - **Item Code**: `PROD-001`
   - **Item Name**: `Product Name`
   - **Item Group**: `Products`
   - **Stock UOM**: `Nos` (or appropriate unit)
   - **Default Warehouse**: Your warehouse
   - **Valuation Rate**: Cost price
   - **Standard Rate**: Selling price

3. Enable for sales:
   - Check **Is Sales Item**
   - Check **Is Stock Item** (if applicable)
   - Add barcode if using barcode scanner

4. **Save**

#### 4. Configure Barcode Scanner (Optional)

For physical barcode scanners:

1. Navigate to: **POS Settings**
2. Enable **Barcode Scanning**
3. Configure scanner settings:
   - **Barcode Field**: `barcode`
   - **Search by**: `Barcode`

For items:
1. Edit item
2. Add barcode in **Barcode** section
3. Use standard formats: EAN-13, UPC, Code 128

### Using AwesomePOS

#### Access POS Interface

**Via Direct URL**:
```
https://pos.byrne-accounts.org
```

**Via ERPNext**:
1. Login to ERPNext
2. Navigate to: **Retail** → **AwesomePOS**
3. Select POS Profile: `Store Counter 1`
4. Click **Open POS**

#### POS Interface Overview

**Main Sections**:
- **Left Panel**: Item catalog with search and filters
- **Center Panel**: Selected items (cart)
- **Right Panel**: Customer info and payment
- **Top Bar**: Profile, date, cashier info

#### Making a Sale

1. **Select Customer** (optional):
   - Click customer field
   - Search or select existing customer
   - Or use default "Walk-in Customer"

2. **Add Items**:
   - Click item from catalog, OR
   - Scan barcode, OR
   - Search by name/code
   - Adjust quantity using +/- buttons

3. **Apply Discount** (optional):
   - Click discount icon
   - Enter discount % or amount
   - Apply to line item or total

4. **Process Payment**:
   - Click **Pay**
   - Select payment method(s)
   - Enter amount received
   - System calculates change
   - Click **Complete Order**

5. **Print Receipt** (optional):
   - Click **Print**
   - Receipt opens in new window
   - Print or save as PDF

#### Offline Mode

AwesomePOS supports offline operation:

**Enable Offline Mode**:
1. Navigate to: **POS Profile**
2. Check **Use POS in Offline Mode**
3. **Save**

**How it works**:
- Data cached in browser localStorage
- Continue sales without internet
- Auto-sync when connection restored
- Conflict resolution for inventory

**Limitations**:
- Limited to cached items
- No real-time inventory updates
- Sync required before new items appear

### Advanced Features

#### Customer Loyalty Program

1. Navigate to: **Selling** → **Loyalty Program** → **New**
2. Configure:
   - **Program Name**: `Bronze Member`
   - **Collection Rules**: Points per currency
   - **Redemption Rules**: Points to currency conversion
3. Assign to customer groups

**Using in POS**:
- Select customer with loyalty program
- Points auto-calculated on sale
- Redeem points as payment method

#### Multiple Payment Methods

Split payments across methods:

1. In payment screen, click **Add Payment**
2. Select first method (e.g., Cash): €50
3. Click **Add Payment** again
4. Select second method (e.g., Card): €30
5. **Complete Order**

#### Returns and Exchanges

**Process Return**:
1. Navigate to: **POS Invoice** → Find original sale
2. Click **Return / Credit Note**
3. Select items to return
4. Adjust quantities if partial return
5. Select return payment method
6. **Submit**

#### Cashier Shift Management

**Open Shift**:
1. Access POS
2. Click **Open Shift**
3. Enter opening cash amount
4. Record denominations
5. **Submit**

**Close Shift**:
1. Click **Close Shift**
2. Enter closing cash count
3. Review sales summary
4. Reconcile differences
5. **Submit**

### POS Reports

#### Sales Summary

Navigate to: **Retail** → **POS Reports** → **Sales Summary**

View:
- Total sales by period
- Payment method breakdown
- Top-selling items
- Cashier performance
- Hourly sales patterns

#### Inventory Status

Check stock levels in real-time:
- View in POS: Click item → Shows available qty
- Report: **Stock Balance** report
- Alert: Low stock warnings in POS

#### Cashier Reports

Track individual cashier performance:
- Sales by cashier
- Payment collections
- Returns processed
- Shift summaries

### Customization

#### Custom Print Format

Create custom receipt template:

1. Navigate to: **Print Format** → **New**
2. Select **POS Invoice**
3. Design receipt layout:
   - Company logo
   - Tax details
   - Custom footer
   - Barcode/QR code
4. Set as default for POS

#### Custom Fields

Add custom fields to POS:

1. Navigate to: **Customize Form** → **POS Invoice**
2. Add fields:
   - Customer phone
   - Delivery notes
   - Special instructions
3. **Update**

Fields appear in POS interface.

### Troubleshooting AwesomePOS

#### POS Not Loading

```bash
# Check if app is installed
make erp-shell
bench --site erp.byrne-accounts.org list-apps
# Should include posawesome

# Rebuild assets
bench build --apps posawesome

# Clear cache
bench --site erp.byrne-accounts.org clear-cache

# Restart backend
exit
make restart S=erpnext-backend
```

#### Items Not Appearing in POS

**Checklist**:
- [ ] Item is marked as **Is Sales Item**
- [ ] Item has **Standard Rate** set
- [ ] Item group is not restricted
- [ ] POS Profile has correct warehouse
- [ ] Item has stock available

**Fix**:
```python
# Via console
import frappe

# Check item settings
item = frappe.get_doc("Item", "ITEM-CODE")
print(f"Is Sales Item: {item.is_sales_item}")
print(f"Standard Rate: {item.standard_rate}")
print(f"Item Group: {item.item_group}")

# Fix if needed
item.is_sales_item = 1
item.standard_rate = 10.00  # Set price
item.save()
frappe.db.commit()
```

#### Payment Method Errors

```bash
# Verify payment methods exist
make erp-shell
bench --site erp.byrne-accounts.org console
```

```python
import frappe

# List payment methods
methods = frappe.get_all("Mode of Payment", fields=["name", "enabled"])
for m in methods:
    print(f"{m.name}: {'Enabled' if m.enabled else 'Disabled'}")

# Create missing payment method
if not frappe.db.exists("Mode of Payment", "Cash"):
    doc = frappe.get_doc({
        "doctype": "Mode of Payment",
        "mode_of_payment": "Cash",
        "enabled": 1,
        "type": "Cash"
    })
    doc.insert()
    frappe.db.commit()
```

#### Offline Sync Issues

**Clear offline cache**:
1. Open browser developer tools (F12)
2. Go to **Application** → **Storage** → **Local Storage**
3. Clear site data
4. Refresh POS

**Force sync**:
1. In POS, click **Sync Now**
2. Wait for sync to complete
3. Verify inventory updated

#### Barcode Scanner Not Working

**Troubleshooting**:
1. Check scanner is in USB HID mode (not serial)
2. Test scanner in text editor - should type barcode
3. Verify barcode format matches item barcodes
4. Check POS Settings → Barcode configuration

**Test barcode manually**:
```python
# Via console
import frappe

item = frappe.get_doc("Item", {"barcode": "123456789012"})
print(f"Found: {item.name}")
```

### Performance Optimization

#### Cache Item Images

Pre-load images for faster POS:

1. Edit items
2. Attach small product images (max 100KB)
3. Use web-optimized formats (WebP, optimized JPEG)

#### Limit Item Catalog

For faster loading:

1. In POS Profile, set **Item Groups** filter
2. Only include groups sold at this counter
3. Use search for items outside filter

#### Browser Performance

**Recommended browsers**:
- Chrome/Chromium (best performance)
- Firefox
- Safari

**Clear cache regularly**:
- Browser cache
- ERPNext cache: `bench clear-cache`

### Security Considerations

#### POS User Permissions

Restrict POS access:

1. Create role: **POS User**
2. Assign permissions:
   - Read: Item, Customer, Warehouse
   - Write: POS Invoice
   - No access: Pricing, Discounts (if restricted)

3. Assign role to cashiers

#### Payment Security

**Best practices**:
- Enable session timeout
- Require PIN for large discounts
- Audit trail enabled (automatic in ERPNext)
- Daily reconciliation required
- Restrict access to payment accounts

#### Data Protection

**POS data security**:
- Authentik SSO authentication
- HTTPS encryption (via Traefik)
- Session management
- Audit logging
- Regular backups (included in automated backups)

### Integration with SecureNexus

#### SSL/HTTPS

POS accessed via Traefik with automatic SSL:
- URL: `https://pos.byrne-accounts.org`
- Certificate: Let's Encrypt (auto-renewed)
- Routing: Traefik labels in compose.yml:878-885

#### SSO Authentication

POS protected by Authentik SSO:
- Middleware: `sso@file`
- Same authentication as ERP
- Single sign-on across services

#### Monitoring

Add POS monitoring:

**Uptime Kuma**:
```
Monitor: POS System
URL: https://pos.byrne-accounts.org
Type: HTTP
Interval: 60 seconds
```

**Prometheus** (already configured):
- Endpoint: erpnext-backend:8000
- Metrics include POS transactions

### Backup & Recovery

POS data backed up automatically:

**What's backed up**:
- POS Invoices (in database)
- POS Profiles
- Item data
- Customer data
- Payment records

**Restore procedure**: Same as ERPNext database restore (see "Backup & Recovery" section)

## Service Endpoints

### Public Access
- **Website**: https://byrne-accounts.org
- **Website (www)**: https://www.byrne-accounts.org
- **ERP**: https://erp.byrne-accounts.org
- **POS**: https://pos.byrne-accounts.org (AwesomePOS)

### Internal (Docker Network)
- **Backend**: `http://erpnext-backend:8000`
- **SocketIO**: `http://erpnext-socketio:9000`
- **Database**: `erpnext-db:3306`
- **Redis Cache**: `erpnext-redis-cache:6379`
- **Redis Queue**: `erpnext-redis-queue:6379`

## Docker Volumes

All data is persisted in Docker named volumes:

| Volume | Purpose | Size (typical) |
|--------|---------|----------------|
| `erpnext-db-data` | MariaDB database | 500MB - 10GB+ |
| `erpnext-redis-cache-data` | Redis cache | 512MB (max) |
| `erpnext-redis-queue-data` | Redis queue | 100MB |
| `erpnext-sites-data` | Site files, uploads | 1GB - 50GB+ |
| `erpnext-assets-data` | Compiled JS/CSS | 500MB |

**Inspection**:
```bash
docker volume ls | grep erpnext
docker volume inspect securenexus-fullstack_erpnext-sites-data
```

## Backup & Recovery

### Automated Backups

ERPNext data is automatically included in the daily backup rotation:

```bash
# Manual backup
sudo /home/tristian/securenexus-fullstack/scripts/backup-rotation.sh

# View backup contents
ls -lh /backup/securenexus/daily/
cat /backup/securenexus/daily/*/MANIFEST.txt
```

**Backed up components**:
1. `databases/erpnext.sql` - Full MariaDB dump (all databases)
2. `volumes/erpnext-sites.tar.gz` - Site files, uploads, attachments
3. `volumes/erpnext-assets.tar.gz` - Compiled assets
4. `config/erp-branding/` - Branding scripts

### Manual Database Backup

```bash
# Backup to file
docker exec -it erpnext-db mysqldump -u root -p$(cat secrets/erpnext_db_password.txt) \
  --all-databases > erpnext-backup-$(date +%Y%m%d).sql

# Compress
gzip erpnext-backup-*.sql
```

### Restore from Backup

```bash
# Stop services
docker compose stop erpnext-backend erpnext-worker erpnext-scheduler

# Restore database
cat /backup/securenexus/daily/*/databases/erpnext.sql | \
  docker exec -i erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt)

# Restore volumes
docker run --rm -v securenexus-fullstack_erpnext-sites-data:/data \
  -v /backup/securenexus/daily/latest/volumes:/backup alpine \
  tar -xzf /backup/erpnext-sites.tar.gz -C /data

# Restart services
docker compose restart erpnext-backend erpnext-worker erpnext-scheduler
```

## Maintenance Tasks

### Clear Cache

```bash
make erp-shell
bench --site erp.byrne-accounts.org clear-cache
```

### Update ERPNext

```bash
# Pull latest image
docker compose pull erpnext-backend

# Backup first!
sudo /home/tristian/securenexus-fullstack/scripts/backup-rotation.sh

# Restart with new image
make restart S=erpnext-backend
make restart S=erpnext-worker
make restart S=erpnext-scheduler

# Run migrations (if needed)
make erp-shell
bench --site erp.byrne-accounts.org migrate
```

### View Logs

```bash
# All Byrne services
make byrne-logs

# Specific service
make erp-logs
docker compose logs -f erpnext-worker
docker compose logs -f erpnext-db
```

### Database Console

```bash
# MariaDB console
docker exec -it erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt)

# ERPNext database
docker exec -it erpnext-db mysql -u erpnext -p$(cat secrets/erpnext_db_password.txt) erpnext
```

### Bench Console

```bash
make erp-shell
bench --site erp.byrne-accounts.org console
```

## Monitoring

### Prometheus Metrics

ERPNext endpoints are monitored via Prometheus blackbox exporter:

- `https://erp.byrne-accounts.org` - HTTP 200 check
- `https://pos.byrne-accounts.org` - HTTP 200 check
- `https://byrne-accounts.org` - Website uptime

**View metrics**:
- Prometheus: https://prometheus.securenexus.net
- Grafana: https://grafana.securenexus.net

### Uptime Kuma

Add monitors in Uptime Kuma for:
1. **ERPNext Login Page**: https://erp.byrne-accounts.org
2. **ERPNext API**: https://erp.byrne-accounts.org/api/method/ping
3. **Byrne Website**: https://byrne-accounts.org

## Troubleshooting

### Site not loading

```bash
# Check backend health
docker compose ps erpnext-backend

# View logs
make erp-logs

# Common issues:
# 1. Site config missing - rerun configurator
# 2. Database connection - check erpnext-db health
# 3. Redis connection - check redis health
```

### Database connection errors

```bash
# Verify database is running
docker compose ps erpnext-db

# Check database health
docker exec erpnext-db mysqladmin ping -u root -p$(cat secrets/erpnext_db_password.txt)

# Verify site config
make erp-shell
cat sites/erp.byrne-accounts.org/site_config.json
```

### Worker not processing jobs

```bash
# Check worker status
docker compose ps erpnext-worker

# View worker logs
docker compose logs -f erpnext-worker

# Restart worker
make restart S=erpnext-worker
```

### SSO login not working

```bash
# Verify redirect URI in Authentik matches exactly:
# https://erp.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik

# Check Social Login Key configuration
make erp-shell
bench --site erp.byrne-accounts.org console

# In console:
frappe.get_doc("Social Login Key", "authentik").as_dict()
```

### Reset site (DESTRUCTIVE)

```bash
# This will DELETE all site data!
docker compose stop erpnext-backend erpnext-worker erpnext-scheduler
docker compose run --rm erpnext-configurator bash -c \
  "bench drop-site erp.byrne-accounts.org --force"
docker volume rm securenexus-fullstack_erpnext-sites-data
docker compose up erpnext-configurator
```

## Performance Tuning

### Gunicorn Workers

Default: 4 workers. Adjust in compose.yml:636

```yaml
command: ["gunicorn", "-b", "0.0.0.0:8000", "--workers", "8", ...]
```

### Redis Cache Size

Default: 512MB LRU. Adjust in compose.yml:772:

```yaml
command: ["sh", "-c", "exec redis-server --requirepass ... --maxmemory 1024mb ..."]
```

### MariaDB Tuning

Add to compose.yml:749 under `command:`:

```yaml
command:
  - --innodb-buffer-pool-size=2G
  - --innodb-log-file-size=512M
  - --max-connections=200
```

## Security Considerations

1. **Admin Password**: Change default Administrator password immediately
2. **User Management**: Use Authentik SSO, disable local logins
3. **Permissions**: Configure ERPNext Role Permissions properly
4. **Rate Limiting**: Already configured via Traefik
5. **SSL**: Automatic via Let's Encrypt
6. **Backup Encryption**: Encrypt `secrets.tar.gz` before off-site storage

## Configuration Management

### ERPNext System Settings

After initial deployment, configure these important settings:

**Access System Settings**:
```bash
# Via web UI
Navigate to: Setup → System Settings

# Via console
make erp-shell
bench --site erp.byrne-accounts.org console
```

**Recommended Settings**:
```python
# In ERPNext console
import frappe

# Set company defaults
frappe.db.set_value("System Settings", None, "country", "Ireland")
frappe.db.set_value("System Settings", None, "time_zone", "Europe/Dublin")
frappe.db.set_value("System Settings", None, "currency", "EUR")
frappe.db.set_value("System Settings", None, "language", "en")

# Security settings
frappe.db.set_value("System Settings", None, "enable_password_policy", 1)
frappe.db.set_value("System Settings", None, "minimum_password_score", 2)
frappe.db.set_value("System Settings", None, "enable_two_factor_auth", 1)
frappe.db.set_value("System Settings", None, "session_expiry", "06:00:00")

# Email settings
frappe.db.set_value("System Settings", None, "email_footer_address", "Byrne Accounting")
frappe.db.set_value("System Settings", None, "disable_user_pass_login", 0)  # Keep enabled initially

frappe.db.commit()
```

### Site Configuration

Site-specific configuration is stored in `/home/frappe/frappe-bench/sites/erp.byrne-accounts.org/site_config.json`:

**View configuration**:
```bash
make erp-shell
cat sites/erp.byrne-accounts.org/site_config.json
```

**Example site_config.json**:
```json
{
 "db_host": "erpnext-db",
 "db_port": 3306,
 "db_name": "erpnext",
 "db_password": "***",
 "redis_cache": "redis://erpnext-redis-cache:6379",
 "redis_queue": "redis://erpnext-redis-queue:6379",
 "developer_mode": 0,
 "maintenance_mode": 0,
 "encryption_key": "***",
 "host_name": "https://erp.byrne-accounts.org"
}
```

### Email Integration

Configure outbound email via Mailcow SMTP:

**Setup Email Account**:
1. Navigate to: **Email Account** → **New**
2. Configure:
   - **Email ID**: `noreply@byrne-accounts.org`
   - **Email Server**: `mail.securenexus.net` (or Mailcow hostname)
   - **SMTP Server**: `mail.securenexus.net`
   - **Port**: `587` (STARTTLS)
   - **Use TLS**: Yes
   - **Login ID**: Email address
   - **Password**: Mailcow email password
   - **Default Outgoing**: Yes

**Test email sending**:
```bash
make erp-shell
bench --site erp.byrne-accounts.org console

# In console
frappe.sendmail(
    recipients=['your-email@example.com'],
    subject='ERPNext Test Email',
    message='This is a test email from ERPNext'
)
```

### User Management

**Create new users**:
```bash
# Via web UI
Navigate to: Users and Permissions → User → New

# Via console
make erp-shell
bench --site erp.byrne-accounts.org add-user user@example.com FirstName LastName
```

**Assign roles**:
```python
# In ERPNext console
import frappe

user = frappe.get_doc("User", "user@example.com")
user.add_roles("Sales User", "Stock User", "Accounts User")
user.save()
frappe.db.commit()
```

**Common ERPNext Roles**:
- `System Manager` - Full admin access
- `Accounts Manager` - Financial management
- `Accounts User` - Create accounting entries
- `Sales Manager` - Sales operations management
- `Sales User` - Create sales orders, invoices
- `Stock Manager` - Inventory management
- `Stock User` - Stock transactions
- `HR Manager` - Human resources management
- `Purchase Manager` - Purchasing operations

### Company Setup

**Create your company**:
1. Navigate to: **Setup** → **Company** → **New**
2. Fill in:
   - **Company Name**: `Byrne Accounting Ltd`
   - **Abbr**: `BA` (used for account codes)
   - **Country**: `Ireland`
   - **Default Currency**: `EUR`
   - **Chart of Accounts**: `Standard` or `Ireland`
   - **Fiscal Year**: Auto-created based on date
3. **Save**

**Configure company defaults**:
```python
# Via ERPNext console
import frappe

company = frappe.get_doc("Company", "Byrne Accounting Ltd")
company.default_currency = "EUR"
company.enable_perpetual_inventory = 1  # Use perpetual inventory
company.country = "Ireland"
company.tax_id = "IE1234567A"  # VAT number
company.domain = "Services"
company.save()
frappe.db.commit()
```

## Advanced Configuration

### Custom Apps and Plugins

**Install custom Frappe apps**:
```bash
make erp-shell
cd /home/frappe/frappe-bench

# Get app from Git
bench get-app https://github.com/organization/app-name --branch version-15

# Install on site
bench --site erp.byrne-accounts.org install-app app_name

# Build assets
bench build --apps app_name

# Restart services
exit
make restart S=erpnext-backend
```

**List installed apps**:
```bash
make erp-shell
bench --site erp.byrne-accounts.org list-apps
```

### Custom Scripts and Workflows

**Add custom server scripts** (via UI):
1. Navigate to: **Customization** → **Server Script** → **New**
2. Configure:
   - **Script Type**: `DocType Event`
   - **Document Type**: Select doctype
   - **Event**: `Before Save`, `After Insert`, etc.
   - **Script**: Python code

**Example server script** (auto-set field):
```python
# Auto-set customer group on customer creation
doc.customer_group = "Commercial"
```

### API Configuration

**Enable API access**:
```bash
# Create API key and secret via UI
# Navigate to: User → Select user → API Access → Generate Keys

# Test API access
curl -X GET https://erp.byrne-accounts.org/api/resource/Company \
  -H "Authorization: token api_key:api_secret"
```

**API endpoints**:
- List records: `GET /api/resource/{doctype}`
- Get record: `GET /api/resource/{doctype}/{name}`
- Create record: `POST /api/resource/{doctype}`
- Update record: `PUT /api/resource/{doctype}/{name}`
- Delete record: `DELETE /api/resource/{doctype}/{name}`

### Print Formats and Templates

**Customize print templates**:
1. Navigate to: **Print Format** → **New**
2. Select document type (e.g., Sales Invoice)
3. Choose format builder or HTML editor
4. Customize layout, add company logo
5. Set as default if desired

**Custom print formats location**:
```bash
# Via container
make erp-shell
cd sites/erp.byrne-accounts.org/public/files
# Add custom templates here
```

### Scheduled Jobs

**View scheduled jobs**:
```bash
make erp-shell
bench --site erp.byrne-accounts.org doctor
```

**Add custom scheduled job**:
```python
# In a custom app's hooks.py
scheduler_events = {
    "daily": [
        "myapp.tasks.daily_cleanup"
    ],
    "hourly": [
        "myapp.tasks.sync_inventory"
    ]
}
```

## Integration with SecureNexus Services

### Monitoring Integration

**Add ERPNext to Prometheus** (already configured):

The `monitoring/prometheus.yml` includes ERPNext endpoints:
```yaml
- job_name: 'erpnext'
  static_configs:
    - targets: ['erpnext-backend:8000']
  metrics_path: '/api/method/frappe.utils.health.ping'
```

**View metrics**:
- Prometheus: `https://prometheus.securenexus.net`
- Query: `up{job="erpnext"}`

### Uptime Kuma Monitoring

**Add ERPNext monitors**:
1. Access Uptime Kuma: `https://status.securenexus.net`
2. Add monitors:
   - **HTTP**: `https://erp.byrne-accounts.org`
   - **HTTP Keyword**: `https://erp.byrne-accounts.org` (look for "ERPNext")
   - **Ping**: Check response time < 1000ms

### Grafana Dashboard

**Create ERPNext dashboard**:
1. Access Grafana: `https://grafana.securenexus.net`
2. Create new dashboard
3. Add panels:
   - **Uptime**: `up{job="erpnext"}`
   - **Response Time**: Blackbox exporter metrics
   - **Database Connections**: MariaDB metrics
   - **Redis Memory**: Redis exporter metrics
   - **Container Stats**: cAdvisor metrics

### Backup Integration

ERPNext is automatically included in the backup rotation:

**Verify backups**:
```bash
# Check latest backup
ls -lh /backup/securenexus/daily/*/databases/erpnext.sql
ls -lh /backup/securenexus/daily/*/volumes/erpnext-*.tar.gz

# View backup manifest
cat /backup/securenexus/daily/*/MANIFEST.txt | grep erpnext
```

**Restore specific backup**:
```bash
# Stop services
docker compose stop erpnext-backend erpnext-worker erpnext-scheduler

# Restore database
cat /backup/securenexus/daily/2025-10-12/databases/erpnext.sql | \
  docker exec -i erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt)

# Restore sites volume
docker run --rm -v securenexus-fullstack_erpnext-sites-data:/data \
  -v /backup/securenexus/daily/2025-10-12/volumes:/backup alpine \
  tar -xzf /backup/erpnext-sites.tar.gz -C /data

# Restart services
docker compose start erpnext-backend erpnext-worker erpnext-scheduler
```

## Production Readiness Checklist

### Pre-Production Tasks

- [ ] **Secrets Rotated**: Change all default passwords
- [ ] **Authentik SSO Configured**: Enable SSO for all users
- [ ] **SSL Certificates Valid**: Verify Let's Encrypt certs
- [ ] **Firewall Rules**: Confirm UFW rules in place
- [ ] **CrowdSec Active**: Verify intrusion detection running
- [ ] **Backups Tested**: Perform test restore
- [ ] **Monitoring Configured**: Uptime Kuma + Prometheus alerts
- [ ] **Email Configuration**: Test outbound email
- [ ] **User Training**: Train staff on ERPNext and POS

### Security Hardening

- [ ] **Disable Administrator Login**: Use SSO exclusively
- [ ] **Enable MFA**: Configure Authentik MFA for all users
- [ ] **Session Timeout**: Set to 6 hours or less
- [ ] **Password Policy**: Minimum score 2, require special chars
- [ ] **API Access**: Restrict to specific IPs if needed
- [ ] **Database Encryption**: Enable at-rest encryption
- [ ] **Audit Logging**: Enable and review regularly

### Performance Optimization

- [ ] **Database Indexes**: Review slow queries, add indexes
- [ ] **Redis Memory**: Monitor cache hit rate, adjust size
- [ ] **Gunicorn Workers**: Tune worker count (2x CPU cores)
- [ ] **MariaDB Buffer Pool**: Increase innodb_buffer_pool_size
- [ ] **Static Asset CDN**: Consider CDN for assets (optional)
- [ ] **Caching**: Enable ERPNext caching in System Settings

### Compliance and Documentation

- [ ] **Data Retention Policy**: Configure per regulations
- [ ] **Privacy Policy**: Update for ERPNext data collection
- [ ] **User Agreements**: Terms of service for system access
- [ ] **Runbook**: Document incident response procedures
- [ ] **Change Log**: Maintain system change history

## Troubleshooting Guide

### Database Issues

**MariaDB connection errors**:
```bash
# Check database is running
docker compose ps erpnext-db

# Check logs
docker compose logs erpnext-db | tail -50

# Test connection
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "SHOW DATABASES;"

# Verify credentials match
docker exec erpnext-backend cat sites/erp.byrne-accounts.org/site_config.json | grep db_password
```

**Database corruption**:
```bash
# Run database repair
docker exec erpnext-db mysqlcheck -u root -p$(cat secrets/erpnext_db_password.txt) --auto-repair --all-databases

# If issues persist, restore from backup
```

### Redis Issues

**Redis connection errors**:
```bash
# Check Redis containers
docker compose ps | grep erpnext-redis

# Test cache connection
docker exec erpnext-redis-cache redis-cli -a "$(cat secrets/erpnext_redis_cache_password.txt)" PING

# Test queue connection
docker exec erpnext-redis-queue redis-cli -a "$(cat secrets/erpnext_redis_queue_password.txt)" PING

# Clear cache if needed
docker exec erpnext-redis-cache redis-cli -a "$(cat secrets/erpnext_redis_cache_password.txt)" FLUSHALL
```

**Memory issues**:
```bash
# Check Redis memory usage
docker stats --no-stream erpnext-redis-cache
docker stats --no-stream erpnext-redis-queue

# Increase maxmemory if needed (edit compose.yml)
```

### Application Errors

**500 Internal Server Error**:
```bash
# Check backend logs
docker compose logs erpnext-backend | tail -100

# Check for Python errors
docker compose logs erpnext-backend | grep -i "traceback\|error"

# Check site config
make erp-shell
cat sites/erp.byrne-accounts.org/site_config.json
```

**Workers not processing jobs**:
```bash
# Check worker status
docker compose ps erpnext-worker

# View worker logs
docker compose logs erpnext-worker | tail -50

# Check queue length
docker exec erpnext-redis-queue redis-cli -a "$(cat secrets/erpnext_redis_queue_password.txt)" LLEN rq:queue:default

# Restart worker
make restart S=erpnext-worker
```

**Scheduler not running**:
```bash
# Check scheduler status
docker compose ps erpnext-scheduler

# View scheduler logs
docker compose logs erpnext-scheduler | tail -50

# Verify scheduler is enabled
make erp-shell
bench --site erp.byrne-accounts.org console
# In console: frappe.db.get_value("System Settings", None, "enable_scheduler")

# Restart scheduler
make restart S=erpnext-scheduler
```

### SSL/Certificate Issues

**Certificate not generating**:
```bash
# Check Traefik logs
docker compose logs traefik | grep -i acme

# Verify DNS resolution
dig erp.byrne-accounts.org

# Check ACME storage
ls -la acme/acme.json
docker exec traefik cat /acme/acme.json | jq '.le.Certificates[] | select(.domain.main == "erp.byrne-accounts.org")'

# Force certificate renewal
docker exec traefik rm /acme/acme.json
docker compose restart traefik
```

### Performance Issues

**Slow page loads**:
```bash
# Check resource usage
docker stats --no-stream | grep erpnext

# Check database queries
docker exec -it erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "SHOW PROCESSLIST;"

# Enable query logging
make erp-shell
bench --site erp.byrne-accounts.org set-config developer_mode 1
# Check logs in sites/erp.byrne-accounts.org/logs/

# Optimize database
docker exec erpnext-db mysqlcheck -u root -p$(cat secrets/erpnext_db_password.txt) --optimize --all-databases
```

**High memory usage**:
```bash
# Check container stats
docker stats | grep erpnext

# Restart services to free memory
docker compose restart erpnext-backend erpnext-worker

# Adjust resource limits in compose.yml if needed
```

### Data Issues

**Missing data after restart**:
```bash
# Verify volumes are mounted
docker inspect erpnext-backend | jq '.[].Mounts'

# Check volume integrity
docker volume inspect securenexus-fullstack_erpnext-sites-data

# Restore from backup if needed
```

**Database locked errors**:
```bash
# Check active connections
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "SHOW FULL PROCESSLIST;"

# Kill long-running queries
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "KILL <process_id>;"
```

## Development and Testing

### Development Mode

**Enable developer mode** (for testing/customization):
```bash
make erp-shell
bench --site erp.byrne-accounts.org set-config developer_mode 1
bench --site erp.byrne-accounts.org clear-cache
exit
make restart S=erpnext-backend
```

**Developer mode features**:
- Live reload on file changes
- Detailed error messages
- Developer console access
- App builder tools
- Query logging

### Testing Environment

**Create test site** (parallel to production):
```bash
make erp-shell
bench new-site test.byrne-accounts.org \
  --mariadb-root-password $(cat /run/secrets/erpnext_db_password) \
  --admin-password testpass123 \
  --db-host erpnext-db \
  --install-app erpnext

# Access via: https://erp.byrne-accounts.org (set host header)
```

### Data Migration

**Import data from CSV**:
1. Navigate to: **Data Import** → **New**
2. Select **DocType** (e.g., Customer, Item)
3. Download template
4. Fill template with data
5. Upload and validate
6. Submit import

**Bulk data operations**:
```bash
make erp-shell
bench --site erp.byrne-accounts.org console

# Example: Bulk update items
import frappe

items = frappe.get_all("Item", filters={"item_group": "Products"})
for item in items:
    doc = frappe.get_doc("Item", item.name)
    doc.standard_rate = doc.standard_rate * 1.1  # 10% price increase
    doc.save()

frappe.db.commit()
```

## Additional Resources

### Official Documentation

- **ERPNext Documentation**: https://docs.erpnext.com
- **Frappe Framework**: https://frappeframework.com/docs
- **Frappe Developer Guide**: https://frappeframework.com/docs/user/en/tutorial
- **ERPNext API**: https://frappeframework.com/docs/user/en/api

### Community Resources

- **ERPNext Forum**: https://discuss.erpnext.com
- **Frappe Discord**: https://discord.gg/frappe
- **GitHub Issues**: https://github.com/frappe/erpnext/issues
- **Video Tutorials**: https://www.youtube.com/@erpnext

### Integration Guides

- **Authentik Integration**: https://integrations.goauthentik.io/development/frappe/
- **Mailcow SMTP**: https://docs.mailcow.email/
- **Traefik Routing**: https://doc.traefik.io/traefik/

### SecureNexus Documentation

- **Main Documentation**: `/home/tristian/securenexus-fullstack/CLAUDE.md`
- **Security Hardening**: `docs/SECURITY_HARDENING_GUIDE.md`
- **Disaster Recovery**: `docs/DISASTER_RECOVERY.md`
- **Byrne Accounting Setup**: `docs/BYRNE_ACCOUNTING_SETUP.md`
- **System Status**: `docs/SYSTEM_STATUS_FINAL.md`

## Support and Maintenance

### Regular Maintenance Schedule

**Daily**:
- Monitor container health: `docker compose ps`
- Check logs for errors: `make erp-logs`
- Verify backups completed: `ls -lh /backup/securenexus/daily/`

**Weekly**:
- Review disk space: `df -h`
- Check database size: `docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables GROUP BY table_schema;"`
- Update ERPNext: `docker compose pull frappe/erpnext:latest`
- Review Authentik audit logs

**Monthly**:
- Test backup restoration
- Review user permissions
- Optimize database: `docker exec erpnext-db mysqlcheck --optimize --all-databases`
- Update documentation
- Security patches

**Quarterly**:
- Full security audit
- Performance review and optimization
- Capacity planning
- User training refresh

### Getting Help

For issues specific to this deployment:

1. **Check logs**: `make byrne-logs` or `make erp-logs`
2. **Review documentation**: `docs/` directory
3. **Test connectivity**: Verify Traefik, Authentik, database connections
4. **Community support**: ERPNext forum for application issues
5. **System commands**: `make help` for available operations

### Incident Response

**If ERPNext is down**:
1. Check service status: `docker compose ps | grep erpnext`
2. Review logs: `make erp-logs`
3. Restart services: `make restart S=erpnext-backend`
4. If database issue: Check MariaDB health
5. If persistent: Restore from backup

**If data is lost**:
1. Stop all ERPNext services immediately
2. Check backup availability: `ls /backup/securenexus/daily/`
3. Follow restore procedures (see "Backup & Recovery" section)
4. Verify data integrity after restore
5. Document incident for future reference

---

**Document Version**: 2.0
**Last Updated**: October 2025
**Deployment Status**: Production Ready
**Tested On**: Ubuntu 22.04 LTS with Docker Compose v2
