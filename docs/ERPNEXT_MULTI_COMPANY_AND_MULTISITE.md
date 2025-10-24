# ERPNext Multi-Company & Multi-Site Guide

## Overview

This guide covers two ERPNext deployment strategies for Byrne Accounts:

1. **Multi-Company** (for your own businesses) - Multiple companies in ONE site
2. **Multi-Site** (for client subscriptions) - Separate sites for each client

---

## Current Setup

**Existing Site**: `erp.byrne-accounts.org`
- **Company**: House of Trae (HOT)
- **Currency**: GBP
- **Apps**: frappe, erpnext, posawesome

---

## Part 1: Multi-Company Setup (Your Own Businesses)

### What You Get
- ✅ Multiple companies in same database
- ✅ Shared users across companies (users can switch between companies)
- ✅ Consolidated financial reporting
- ✅ Centralized user management
- ✅ Inter-company transactions
- ✅ Group-level reporting

### When to Use
- Your own multiple business entities
- Example: "Byrne Accounting", "Byrne Consulting", "Byrne Retail"
- Businesses that need consolidated reporting
- Same team managing multiple companies

---

### How to Create Additional Companies

#### Method 1: Via Web Interface (Recommended)

1. **Login to ERPNext**: https://erp.byrne-accounts.org
2. **Search for "Company"** (Ctrl+K or use search bar)
3. **Click "+ New"**
4. **Fill in details**:
   ```
   Company Name: Byrne Consulting Ltd
   Abbreviation: BCL (2-5 characters, used in account codes)
   Default Currency: GBP
   Country: United Kingdom
   Chart of Accounts: Based on Template (UK)
   Existing Company: House of Trae (if you want to copy settings)
   ```
5. **Save**

#### Method 2: Via Command Line

```bash
# Access the container
docker exec -it erpnext-backend bash

# Navigate to bench directory
cd /home/frappe/frappe-bench

# Create company using bench console
bench --site erp.byrne-accounts.org console

# In the Python console:
from erpnext.setup.doctype.company.company import create_company

company = frappe.get_doc({
    "doctype": "Company",
    "company_name": "Byrne Consulting Ltd",
    "abbr": "BCL",
    "default_currency": "GBP",
    "country": "United Kingdom"
})
company.insert()
frappe.db.commit()
print(f"Company created: {company.name}")
exit()
```

---

### Managing Multi-Company Users

#### Give Users Access to Multiple Companies

1. **Go to**: User List (search "User")
2. **Select a user** or create new one
3. **Scroll to "Allowed In Transactions"** section
4. **Check companies** the user can access:
   - ☑ House of Trae
   - ☑ Byrne Consulting Ltd
   - ☑ Byrne Retail Ltd
5. **Set default company** for the user
6. **Save**

Users can switch companies via the "Company" dropdown in the desk sidebar.

---

### Consolidated Reporting

#### View Group Reports

1. **Financial Statements**:
   - Reports > Financial Statements > Consolidated Financial Statement
   - Select multiple companies
   - View combined P&L, Balance Sheet

2. **Custom Reports**:
   - Report Builder allows filtering by company
   - Use "Company" field in filters
   - Export combined data to Excel/CSV

3. **Dashboard Widgets**:
   - Create widgets showing data from all companies
   - Workspace > Dashboard > Add Chart
   - Select "All Companies" or specific set

---

### Chart of Accounts Per Company

Each company gets its own Chart of Accounts with the company abbreviation:

**House of Trae (HOT)**:
- `1000 - Cash - HOT`
- `2000 - Accounts Payable - HOT`

**Byrne Consulting (BCL)**:
- `1000 - Cash - BCL`
- `2000 - Accounts Payable - BCL`

---

### Inter-Company Transactions

ERPNext supports transactions between your companies:

1. **Enable Inter-Company Invoicing**:
   - Setup > Company > Company Settings
   - Enable "Allow Inter Company Transactions"

2. **Link Companies**:
   - Setup > Company > Internal Company
   - Create relationships between companies

3. **Create Inter-Company Invoice**:
   - Sales Invoice from Company A → auto-creates Purchase Invoice in Company B
   - Keeps accounts balanced across entities

---

## Part 2: Multi-Site Setup (Client Subscriptions)

### What You Get
- ✅ Completely separate database per client
- ✅ Isolated user accounts (no shared logins)
- ✅ Different domains: `client1.byrne-accounts.org`, `client2.byrne-accounts.org`
- ✅ Can run different ERPNext versions per client
- ✅ Client data 100% isolated
- ✅ Billing/subscription ready

### When to Use
- External client subscriptions (SaaS model)
- Clients who want their own ERPNext instance
- Complete data isolation required
- Different customizations per client

---

### Prerequisites

1. **DNS Setup**: Create DNS records for each client domain
   ```
   client1.byrne-accounts.org → A record → your server IP
   client2.byrne-accounts.org → A record → your server IP
   ```

2. **Database**: MariaDB supports multiple databases (already configured)

3. **Storage**: Each site needs ~2-5GB (plan accordingly)

---

### Creating a New Client Site

#### Step 1: Create the Site

```bash
# Access the container
docker exec -it erpnext-backend bash
cd /home/frappe/frappe-bench

# Get database root password
DB_ROOT_PASS=$(cat /run/secrets/erpnext_db_password)

# Create new site
bench new-site client1.byrne-accounts.org \
  --mariadb-root-password "$DB_ROOT_PASS" \
  --admin-password "SecurePassword123!" \
  --install-app erpnext

# Optional: Install POS Awesome
bench --site client1.byrne-accounts.org install-app posawesome

# Verify site created
bench --site client1.byrne-accounts.org list-apps
```

#### Step 2: Update Compose Configuration

Currently, your `compose.yml` has hardcoded `SITE_NAME: erp.byrne-accounts.org`. We need to make it dynamic:

**Option A: Remove Hardcoded SITE_NAME** (Bench auto-detects from HTTP Host header)

Edit `compose.yml`:

```yaml
# Line 1000 - Remove or comment out
# environment:
#   SITE_NAME: erp.byrne-accounts.org

# Line 1047 - Remove
# environment:
#   SITE_NAME: erp.byrne-accounts.org

# Line 1078 - Remove
# environment:
#   SITE_NAME: erp.byrne-accounts.org

# Line 1102 - Remove
# environment:
#   SITE_NAME: erp.byrne-accounts.org
```

**Option B: Keep Using SITE_NAME for Workers** (Recommended)

Workers and scheduler need explicit site names. Better approach:

```yaml
# erpnext-backend (line 999-1001)
environment:
  # SITE_NAME removed - bench uses HTTP Host header

# erpnext-socketio (line 1046-1051)
environment:
  # Auto-detect site from Host header
  REDIS_CACHE: redis://erpnext-redis-cache:6379
  REDIS_QUEUE: redis://erpnext-redis-queue:6379

# erpnext-worker (line 1077-1081)
environment:
  # Workers run for ALL sites
  REDIS_CACHE: redis://erpnext-redis-cache:6379
  REDIS_QUEUE: redis://erpnext-redis-queue:6379

# Change worker command to process all sites (line 1081)
command: ["bash", "-c", "cd /home/frappe/frappe-bench && bench worker --queue default,short,long"]

# erpnext-scheduler (line 1102-1103)
# Change to run for all sites (line 1103)
command: ["bash", "-c", "cd /home/frappe/frappe-bench && bench schedule"]
```

#### Step 3: Add Traefik Routes for New Site

Add labels to `erpnext-backend` in `compose.yml`:

```yaml
labels:
  - traefik.enable=true
  - traefik.docker.network=securenexus-fullstack_proxy

  # Original site (erp.byrne-accounts.org)
  - traefik.http.routers.erp.rule=Host(`erp.byrne-accounts.org`)
  - traefik.http.routers.erp.entrypoints=websecure
  - traefik.http.routers.erp.tls.certresolver=le
  - traefik.http.routers.erp.middlewares=secure-headers@file
  - traefik.http.routers.erp.service=erp
  - traefik.http.services.erp.loadbalancer.server.port=8000

  # New client site (client1)
  - traefik.http.routers.erp-client1.rule=Host(`client1.byrne-accounts.org`)
  - traefik.http.routers.erp-client1.entrypoints=websecure
  - traefik.http.routers.erp-client1.tls.certresolver=le
  - traefik.http.routers.erp-client1.middlewares=secure-headers@file
  - traefik.http.routers.erp-client1.service=erp

  # SocketIO for original site
  - traefik.http.routers.erpnext-socketio.rule=Host(`erp.byrne-accounts.org`) && PathPrefix(`/socket.io`)
  - traefik.http.routers.erpnext-socketio.entrypoints=websecure
  - traefik.http.routers.erpnext-socketio.tls.certresolver=le
  - traefik.http.services.erpnext-socketio.loadbalancer.server.port=9000

  # SocketIO for client1
  - traefik.http.routers.erpnext-socketio-client1.rule=Host(`client1.byrne-accounts.org`) && PathPrefix(`/socket.io`)
  - traefik.http.routers.erpnext-socketio-client1.entrypoints=websecure
  - traefik.http.routers.erpnext-socketio-client1.tls.certresolver=le
  - traefik.http.services.erpnext-socketio-client1.loadbalancer.server.port=9000
```

#### Step 4: Restart Services

```bash
docker compose restart erpnext-backend erpnext-socketio erpnext-worker erpnext-scheduler
```

#### Step 5: Access New Site

Navigate to: `https://client1.byrne-accounts.org`

**Login**:
- Username: `Administrator`
- Password: `SecurePassword123!` (the one you set during `bench new-site`)

---

### Managing Multiple Sites

#### List All Sites

```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && ls -1 sites/ | grep -v assets | grep -v apps | grep '\\.'"
```

#### Site-Specific Commands

```bash
# Check site status
bench --site client1.byrne-accounts.org migrate
bench --site client1.byrne-accounts.org list-apps

# Backup specific site
bench --site client1.byrne-accounts.org backup --with-files

# Clear cache for specific site
bench --site client1.byrne-accounts.org clear-cache

# Create user for specific site
bench --site client1.byrne-accounts.org add-user john@client1.com --password SecurePass123
```

#### Run Commands for All Sites

```bash
# Migrate all sites
bench --site all migrate

# Backup all sites
bench --site all backup

# Clear cache for all sites
bench --site all clear-cache
```

---

### Client Subscription Management

#### Track Client Sites

Create a simple tracking file: `sites_manifest.json`

```json
{
  "sites": [
    {
      "domain": "erp.byrne-accounts.org",
      "type": "internal",
      "company": "Byrne Accounts",
      "created": "2025-10-18",
      "plan": "Owner"
    },
    {
      "domain": "client1.byrne-accounts.org",
      "type": "client",
      "company": "ABC Corp",
      "created": "2025-10-24",
      "plan": "Professional",
      "monthly_fee": "£99",
      "users": 10
    }
  ]
}
```

#### Automated Provisioning Script

Create `scripts/provision-client-site.sh`:

```bash
#!/bin/bash
# Usage: ./scripts/provision-client-site.sh client2.byrne-accounts.org

SITE_DOMAIN="$1"
ADMIN_PASSWORD=$(openssl rand -base64 32)
DB_ROOT_PASS=$(docker exec erpnext-backend cat /run/secrets/erpnext_db_password)

if [ -z "$SITE_DOMAIN" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

echo "Creating new client site: $SITE_DOMAIN"

# Create site
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench new-site $SITE_DOMAIN \
    --mariadb-root-password '$DB_ROOT_PASS' \
    --admin-password '$ADMIN_PASSWORD' \
    --install-app erpnext"

# Install POS Awesome
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site $SITE_DOMAIN install-app posawesome"

# Save credentials
mkdir -p /home/tristian/securenexus-fullstack/client-credentials
cat > /home/tristian/securenexus-fullstack/client-credentials/${SITE_DOMAIN}.txt <<EOF
Site: https://${SITE_DOMAIN}
Username: Administrator
Password: ${ADMIN_PASSWORD}
Created: $(date)
EOF

echo "✅ Site created successfully!"
echo "📝 Credentials saved to: client-credentials/${SITE_DOMAIN}.txt"
echo ""
echo "⚠️  Next steps:"
echo "1. Add DNS record: $SITE_DOMAIN → $(curl -s ifconfig.me)"
echo "2. Add Traefik labels to compose.yml"
echo "3. Restart Traefik: docker compose restart traefik"
```

Make it executable:
```bash
chmod +x scripts/provision-client-site.sh
```

---

### Resource Considerations

#### Per-Site Resource Usage (Approximate)

| Resource | Per Site | 10 Sites | 50 Sites |
|----------|----------|----------|----------|
| Database | 500MB-2GB | 5-20GB | 25-100GB |
| Files | 1-5GB | 10-50GB | 50-250GB |
| Memory | Shared | Shared | Shared |

#### Shared Resources (Current Setup)

- **MariaDB**: All sites share one database server (separate databases)
- **Redis**: Shared cache and queue
- **Backend Workers**: Process jobs for all sites
- **Scheduler**: Runs scheduled tasks for all sites

#### Scaling Considerations

**Up to 10 sites**: Current setup is fine

**10-50 sites**:
- Consider increasing MariaDB memory
- Add more worker containers
- Monitor Redis memory usage

**50+ sites**:
- Separate MariaDB per client group
- Dedicated worker pools
- Consider Frappe Cloud or cluster setup

---

## Part 3: Best Practices

### Security

**Multi-Company (Your Sites)**:
- ✅ Role-based permissions per company
- ✅ Users see only their assigned companies
- ✅ Restrict sensitive reports to admins

**Multi-Site (Client Sites)**:
- ✅ Unique admin passwords per site (never reuse)
- ✅ Regular backups per site
- ✅ Consider adding rate limiting per domain
- ✅ Store client credentials securely

### Backups

**Multi-Company**:
```bash
# Backup entire site (includes all companies)
bench --site erp.byrne-accounts.org backup --with-files
```

**Multi-Site**:
```bash
# Backup all client sites
bench --site all backup --with-files

# Or backup individually
for site in $(ls sites/ | grep '\\.'); do
  bench --site $site backup --with-files
done
```

### Monitoring

**Track per site**:
```bash
# Database size per site
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e \
  "SELECT table_schema AS 'Site',
   ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
   FROM information_schema.tables
   WHERE table_schema LIKE '%byrne%'
   GROUP BY table_schema;"
```

### Performance

**Optimize for Multi-Site**:

1. **Enable Redis Cache** (already configured)
2. **Use Background Jobs** (already configured via workers)
3. **Regular Maintenance**:
```bash
# Optimize all databases weekly
bench --site all optimize-tables

# Clear old sessions
bench --site all clear-sessions
```

---

## Part 4: Billing & Subscriptions (Future)

### ERPNext Subscription Management

Once you start charging clients, track subscriptions:

1. **Create "Subscription Plan" doctype** in your internal site
2. **Track**:
   - Client name
   - Site domain
   - Plan (Basic/Pro/Enterprise)
   - Monthly fee
   - User limit
   - Storage limit
   - Start date / End date
   - Auto-renewal

3. **Automate**:
   - Monthly invoicing (via ERPNext scheduled task)
   - Usage monitoring (storage, users)
   - Site suspension for non-payment
   - Automatic backups before suspension

### Integration with Stripe/PayPal

ERPNext has payment integrations you can enable:
- Setup > Integrations > Payment Gateway
- Stripe, PayPal, Razorpay, etc.

---

## Quick Reference Commands

### Multi-Company Commands
```bash
# List all companies in a site
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site erp.byrne-accounts.org execute frappe.get_all --args \"['Company', ['name', 'abbr']]\""

# Switch default company for a user (via console)
bench --site erp.byrne-accounts.org console
# Then: frappe.set_value('User', 'user@example.com', 'default_company', 'New Company')
```

### Multi-Site Commands
```bash
# List all sites
bench --site all list-apps

# Create new site
bench new-site newclient.byrne-accounts.org --mariadb-root-password PASSWORD

# Delete a site (DANGEROUS)
bench drop-site oldclient.byrne-accounts.org --force --no-backup

# Migrate all sites
bench --site all migrate

# Backup all sites
bench --site all backup
```

---

## Next Steps

### For Your Own Companies (Multi-Company)
1. ✅ You already have "House of Trae"
2. Create additional companies via web UI
3. Assign users to multiple companies
4. Set up consolidated reporting

### For Client Subscriptions (Multi-Site)
1. Wait for actual client signup
2. Prepare DNS wildcard or manual records
3. Use provisioning script to create new sites
4. Add Traefik routing for each new domain
5. Implement billing/subscription tracking

---

## Support & Documentation

- **ERPNext Multi-Company**: https://docs.erpnext.com/docs/user/manual/en/setting-up/articles/managing-multiple-companies
- **Frappe Multi-Tenancy**: https://frappeframework.com/docs/user/en/bench/guides/multitenancy
- **Traefik Dynamic Config**: https://doc.traefik.io/traefik/providers/docker/

---

**Summary**:
- Your current site (`erp.byrne-accounts.org`) = Multi-Company for your businesses ✅
- Future client sites = Multi-Site with separate databases (when needed) 📋

You're all set! 🚀
