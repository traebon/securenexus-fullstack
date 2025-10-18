# ERPNext Quick Reference Guide

**Version**: 2.0
**Last Updated**: October 2025
**For**: Byrne Accounting ERPNext Deployment

This is a quick reference companion to the comprehensive [ERPNext Setup Guide](ERPNEXT_SETUP.md).

---

## Quick Start Commands

```bash
# Deploy full stack
make up-byrne

# Install AwesomePOS (after ERPNext is initialized)
make install-awesomepos

# Check service status
docker compose ps | grep -E "byrne|erpnext"

# View logs
make erp-logs              # ERPNext backend only
make byrne-logs            # All Byrne services

# Access shell
make erp-shell             # Open bash in backend container

# Restart service
make restart S=erpnext-backend
```

---

## Service URLs

| Service | URL | Access Level |
|---------|-----|--------------|
| Marketing Website | https://byrne-accounts.org | Public |
| ERP System | https://erp.byrne-accounts.org | SSO (Authentik) |
| AwesomePOS | https://pos.byrne-accounts.org | SSO (Authentik) |

---

## Container Architecture

```
byrne-website           # Nginx serving static site
erpnext-backend         # Frappe/ERPNext app server (gunicorn on :8000)
erpnext-socketio        # Real-time notifications (:9000)
erpnext-worker          # Background job processor
erpnext-scheduler       # Scheduled tasks (cron)
erpnext-db              # MariaDB 10.6 database
erpnext-redis-cache     # Redis L1 cache (512MB LRU)
erpnext-redis-queue     # Redis job queue
```

---

## Common Operations

### Access ERPNext Console

```bash
make erp-shell
bench --site erp.byrne-accounts.org console

# Now you're in Python REPL with Frappe context
>>> import frappe
>>> frappe.get_all("User")
```

### Clear Cache

```bash
make erp-shell
bench --site erp.byrne-accounts.org clear-cache
```

### Run Database Migrations

```bash
make erp-shell
bench --site erp.byrne-accounts.org migrate
```

### Backup Database

```bash
# Automated (included in daily backups)
ls -lh /backup/securenexus/daily/*/databases/erpnext.sql

# Manual backup
docker exec -it erpnext-db mysqldump -u root -p$(cat secrets/erpnext_db_password.txt) \
  --all-databases > erpnext-backup-$(date +%Y%m%d).sql
```

### Restore Database

```bash
# Stop services
docker compose stop erpnext-backend erpnext-worker erpnext-scheduler

# Restore from backup
cat erpnext-backup-YYYYMMDD.sql | \
  docker exec -i erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt)

# Restart services
docker compose start erpnext-backend erpnext-worker erpnext-scheduler
```

---

## Troubleshooting Quick Fixes

### Service Won't Start

```bash
# Check logs for errors
docker compose logs erpnext-backend | tail -50

# Common fix: restart with dependencies
docker compose restart erpnext-db erpnext-redis-cache erpnext-redis-queue
sleep 15
docker compose restart erpnext-backend
```

### Database Connection Issues

```bash
# Verify database is up
docker compose ps erpnext-db

# Test connection
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "SHOW DATABASES;"

# Check credentials match site config
make erp-shell
cat sites/erp.byrne-accounts.org/site_config.json | grep db_password
```

### Workers Not Processing Jobs

```bash
# Check worker status
docker compose ps erpnext-worker

# Check queue length
docker exec erpnext-redis-queue redis-cli -a "$(cat secrets/erpnext_redis_queue_password.txt)" LLEN rq:queue:default

# Restart worker
make restart S=erpnext-worker
```

### Scheduler Not Running

```bash
# Check scheduler status
docker compose ps erpnext-scheduler

# Verify enabled in site
make erp-shell
bench --site erp.byrne-accounts.org console
# >>> frappe.db.get_value("System Settings", None, "enable_scheduler")

# Restart scheduler
make restart S=erpnext-scheduler
```

### 502 Bad Gateway

```bash
# Check backend health
docker compose ps erpnext-backend

# View backend logs
make erp-logs

# Common fix: restart backend
make restart S=erpnext-backend
```

### Redis Out of Memory

```bash
# Check memory usage
docker stats --no-stream erpnext-redis-cache

# Clear cache (safe operation)
docker exec erpnext-redis-cache redis-cli -a "$(cat secrets/erpnext_redis_cache_password.txt)" FLUSHALL

# Increase memory limit in compose.yml if needed:
# command: [..., "--maxmemory 1024mb"]
```

---

## Configuration Locations

### Site Configuration

```bash
# Main site config
/home/frappe/frappe-bench/sites/erp.byrne-accounts.org/site_config.json

# View from host
docker exec erpnext-backend cat sites/erp.byrne-accounts.org/site_config.json
```

### Docker Volumes

```bash
# List ERPNext volumes
docker volume ls | grep erpnext

# Inspect volume
docker volume inspect securenexus-fullstack_erpnext-sites-data
```

### Secrets

```bash
# All secrets in local directory
ls -la secrets/erpnext*.txt

secrets/erpnext_db_password.txt           # MariaDB root password
secrets/erpnext_admin_password.txt        # ERPNext Administrator password
secrets/erpnext_redis_cache_password.txt  # Redis cache password
secrets/erpnext_redis_queue_password.txt  # Redis queue password
```

---

## Key Bench Commands

```bash
# All commands must be run inside container
make erp-shell

# Site management
bench list-apps                                    # List installed apps
bench --site erp.byrne-accounts.org migrate        # Run migrations
bench --site erp.byrne-accounts.org console        # Python console
bench --site erp.byrne-accounts.org clear-cache    # Clear cache
bench --site erp.byrne-accounts.org doctor         # Health check

# User management
bench --site erp.byrne-accounts.org add-user user@example.com First Last
bench --site erp.byrne-accounts.org set-admin-password newpassword

# App management
bench get-app https://github.com/org/app-name     # Download app
bench --site erp.byrne-accounts.org install-app app_name  # Install app
bench build --apps app_name                        # Build assets

# Database
bench --site erp.byrne-accounts.org --force restore backup.sql  # Restore
bench backup                                       # Backup all sites
```

---

## Monitoring & Health Checks

### Container Health

```bash
# All services
docker compose ps

# ERPNext services only
docker compose ps | grep erpnext

# Watch in real-time
watch -n 5 'docker compose ps | grep erpnext'
```

### Resource Usage

```bash
# Current stats
docker stats --no-stream | grep erpnext

# Continuous monitoring
docker stats | grep erpnext
```

### Logs

```bash
# Follow all Byrne logs
make byrne-logs

# Follow specific service
docker compose logs -f erpnext-backend
docker compose logs -f erpnext-worker
docker compose logs -f erpnext-db

# View last N lines
docker compose logs --tail 100 erpnext-backend

# Search logs
docker compose logs erpnext-backend | grep -i error
```

### Application Health

```bash
# Check via API
curl -I https://erp.byrne-accounts.org/api/method/ping

# Check backend directly
curl -I http://localhost:8000/api/method/ping  # From Traefik container

# Database connections
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) \
  -e "SHOW PROCESSLIST;"
```

---

## Python Console Quick Reference

```python
# Access console
make erp-shell
bench --site erp.byrne-accounts.org console

# Common operations
import frappe

# Database queries
frappe.get_all("User")                          # List all users
frappe.get_doc("User", "user@example.com")      # Get specific user
frappe.db.get_value("Company", None, "country") # Get field value

# Create records
doc = frappe.new_doc("Customer")
doc.customer_name = "Test Customer"
doc.insert()
frappe.db.commit()

# Update records
doc = frappe.get_doc("Customer", "CUST-00001")
doc.customer_group = "Commercial"
doc.save()
frappe.db.commit()

# Delete records
frappe.delete_doc("Customer", "CUST-00001")
frappe.db.commit()

# System settings
frappe.db.set_value("System Settings", None, "country", "Ireland")
frappe.db.commit()

# Send email
frappe.sendmail(
    recipients=['user@example.com'],
    subject='Test Email',
    message='This is a test'
)

# Clear cache
frappe.clear_cache()

# Session info
frappe.session.user                             # Current user
frappe.get_installed_apps()                     # Installed apps
```

---

## Security Quick Checks

### Verify SSO is Active

```bash
# Should redirect to Authentik (302)
curl -I https://erp.byrne-accounts.org

# Check Traefik middleware
docker exec traefik cat /etc/traefik/dynamic/traefik_dynamic.yml | grep -A 10 "sso@file"
```

### Check SSL Certificate

```bash
# Verify certificate validity
echo | openssl s_client -servername erp.byrne-accounts.org -connect erp.byrne-accounts.org:443 2>/dev/null | openssl x509 -noout -dates

# View certificate in Traefik ACME storage
docker exec traefik cat /acme/acme.json | jq '.le.Certificates[] | select(.domain.main == "erp.byrne-accounts.org")'
```

### Review Active Sessions

```python
# In ERPNext console
import frappe
sessions = frappe.get_all("Sessions", fields=["user", "lastupdate"])
for s in sessions:
    print(f"{s.user}: {s.lastupdate}")
```

### Check Failed Login Attempts

```bash
# View Authentik logs
docker compose logs authentik_server | grep -i "failed\|error" | tail -20
```

---

## Performance Tuning Quick Reference

### Increase Redis Cache

```yaml
# Edit compose.yml line 772
command: ["sh", "-c", "exec redis-server --requirepass \"$$(cat /run/secrets/erpnext_redis_cache_password)\" --maxmemory 1024mb --maxmemory-policy allkeys-lru"]
```

### Tune Gunicorn Workers

```yaml
# Edit compose.yml line 857 (default: 4 workers)
command: ["gunicorn", "-b", "0.0.0.0:8000", "--workers", "8", "--timeout", "120", "--graceful-timeout", "30", "frappe.app:application"]
```

### MariaDB Optimization

```yaml
# Add to erpnext-db service in compose.yml
command:
  - --character-set-server=utf8mb4
  - --collation-server=utf8mb4_unicode_ci
  - --skip-character-set-client-handshake
  - --skip-innodb-read-only-compressed
  - --innodb-buffer-pool-size=2G
  - --innodb-log-file-size=512M
  - --max-connections=200
```

---

## Backup Quick Reference

### Automated Backups

```bash
# Check backup schedule
crontab -l | grep backup

# View latest backup
ls -lh /backup/securenexus/daily/

# Check backup manifest
cat /backup/securenexus/daily/*/MANIFEST.txt | grep erpnext
```

### Manual Backup

```bash
# Run full system backup
sudo ./scripts/backup-rotation.sh

# Backup only ERPNext database
docker exec -it erpnext-db mysqldump -u root -p$(cat secrets/erpnext_db_password.txt) \
  --all-databases | gzip > erpnext-$(date +%Y%m%d).sql.gz
```

### Quick Restore

```bash
# Stop services
docker compose stop erpnext-backend erpnext-worker erpnext-scheduler

# Restore database
zcat erpnext-YYYYMMDD.sql.gz | \
  docker exec -i erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt)

# Restart services
docker compose start erpnext-backend erpnext-worker erpnext-scheduler
```

---

## Emergency Procedures

### Complete Service Restart

```bash
# Stop all Byrne services
docker compose stop byrne-website erpnext-backend erpnext-socketio \
  erpnext-worker erpnext-scheduler erpnext-db \
  erpnext-redis-cache erpnext-redis-queue

# Wait 10 seconds
sleep 10

# Start in order
docker compose up -d erpnext-db erpnext-redis-cache erpnext-redis-queue
sleep 15
docker compose up -d erpnext-backend erpnext-socketio erpnext-worker erpnext-scheduler
docker compose up -d byrne-website

# Verify all healthy
docker compose ps | grep erpnext
```

### Database Emergency Repair

```bash
# Stop services
docker compose stop erpnext-backend erpnext-worker erpnext-scheduler

# Repair database
docker exec erpnext-db mysqlcheck -u root -p$(cat secrets/erpnext_db_password.txt) \
  --auto-repair --all-databases

# Optimize after repair
docker exec erpnext-db mysqlcheck -u root -p$(cat secrets/erpnext_db_password.txt) \
  --optimize --all-databases

# Restart services
docker compose start erpnext-backend erpnext-worker erpnext-scheduler
```

### Clear All Caches

```bash
# Redis cache
docker exec erpnext-redis-cache redis-cli -a "$(cat secrets/erpnext_redis_cache_password.txt)" FLUSHALL

# ERPNext cache
make erp-shell
bench --site erp.byrne-accounts.org clear-cache

# Restart backend to reload
exit
make restart S=erpnext-backend
```

---

## Update Procedures

### Update ERPNext

```bash
# Backup first!
sudo ./scripts/backup-rotation.sh

# Pull latest image
docker compose pull frappe/erpnext:latest

# Restart services
make restart S=erpnext-backend
make restart S=erpnext-worker
make restart S=erpnext-scheduler

# Run migrations
make erp-shell
bench --site erp.byrne-accounts.org migrate
```

### Update Custom Branding

```bash
# Edit branding scripts
nano erp/branding/install-branding.sh

# Re-apply branding
make erp-branding
```

---

## AwesomePOS Quick Commands

```bash
# Install AwesomePOS
make install-awesomepos

# Verify installation
docker exec erpnext-backend bench --site erp.byrne-accounts.org list-apps
# Should include: posawesome

# Rebuild POS assets
docker exec erpnext-backend bench build --apps posawesome

# Create POS profile (Python console)
docker exec erpnext-backend bench --site erp.byrne-accounts.org console -c "
import frappe
pos = frappe.get_doc({
    'doctype': 'POS Profile',
    'name': 'Store Counter 1',
    'company': 'Byrne Accounting Ltd',
    'warehouse': 'Stores - BA',
    'currency': 'EUR',
    'selling_price_list': 'Standard Selling',
    'payments': [
        {'mode_of_payment': 'Cash', 'default': 1},
        {'mode_of_payment': 'Credit Card'}
    ]
})
pos.insert()
frappe.db.commit()
print('POS Profile created!')
"

# Check POS profiles
docker exec erpnext-backend bench --site erp.byrne-accounts.org console -c "
import frappe
profiles = frappe.get_all('POS Profile', fields=['name', 'enabled'])
for p in profiles: print(f'{p.name}: {p.enabled}')
"

# List payment methods
docker exec erpnext-backend bench --site erp.byrne-accounts.org console -c "
import frappe
methods = frappe.get_all('Mode of Payment', fields=['name', 'enabled'])
for m in methods: print(f'{m.name}: {m.enabled}')
"

# Check items available for POS
docker exec erpnext-backend bench --site erp.byrne-accounts.org console -c "
import frappe
items = frappe.get_all('Item', filters={'is_sales_item': 1}, fields=['name', 'standard_rate'])
print(f'Total items: {len(items)}')
for item in items[:5]: print(f'{item.name}: €{item.standard_rate}')
"
```

## Useful One-Liners

```bash
# Check all container health
docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep erpnext

# Total database size
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = 'erpnext';"

# Count queued jobs
docker exec erpnext-redis-queue redis-cli -a "$(cat secrets/erpnext_redis_queue_password.txt)" LLEN rq:queue:default

# List all ERPNext users
docker exec erpnext-backend bench --site erp.byrne-accounts.org console -c "import frappe; print('\n'.join([u.name for u in frappe.get_all('User', fields=['name'])]))"

# Disk usage by volume
docker system df -v | grep erpnext

# Recent errors in logs (last hour)
docker compose logs --since 1h erpnext-backend | grep -i error

# Test database connection
docker exec erpnext-db mysqladmin -u root -p$(cat secrets/erpnext_db_password.txt) ping

# Check if scheduler is enabled
docker exec erpnext-backend bench --site erp.byrne-accounts.org console -c "import frappe; print(frappe.db.get_value('System Settings', None, 'enable_scheduler'))"
```

---

## Environment Variables Reference

```bash
# From compose.yml
SITE_NAME=erp.byrne-accounts.org           # Primary site name

# From secrets/
erpnext_db_password.txt                     # Database password
erpnext_admin_password.txt                  # Admin password
erpnext_redis_cache_password.txt            # Cache password
erpnext_redis_queue_password.txt            # Queue password

# Makefile environment
export CLIENT_ID='...'                      # For SSO setup
export CLIENT_SECRET='...'                  # For SSO setup
```

---

## Important File Paths

**In Container**:
- Site config: `/home/frappe/frappe-bench/sites/erp.byrne-accounts.org/site_config.json`
- Site files: `/home/frappe/frappe-bench/sites/erp.byrne-accounts.org/`
- Logs: `/home/frappe/frappe-bench/sites/erp.byrne-accounts.org/logs/`
- Apps: `/home/frappe/frappe-bench/apps/`
- Assets: `/home/frappe/frappe-bench/sites/assets/`

**On Host**:
- Compose file: `compose.yml` (lines 714-955)
- Makefile: `Makefile` (lines 53-134)
- Branding: `erp/branding/`
- Website: `byrne-website/`
- Secrets: `secrets/erpnext*.txt`
- Documentation: `docs/ERPNEXT_SETUP.md`

---

## Support Resources

**Documentation**:
- Full Setup Guide: `docs/ERPNEXT_SETUP.md` (1,175 lines)
- Byrne Accounting Guide: `docs/BYRNE_ACCOUNTING_SETUP.md`
- This Quick Reference: `docs/ERPNEXT_QUICK_REFERENCE.md`

**Commands**:
- `make help` - Show all available commands
- `make erp-shell` - Access ERPNext shell
- `make erp-logs` - View ERPNext logs
- `make byrne-logs` - View all Byrne service logs

**Community**:
- ERPNext Forum: https://discuss.erpnext.com
- Frappe Discord: https://discord.gg/frappe
- GitHub: https://github.com/frappe/erpnext

---

**Quick Reference Version**: 2.0
**Last Updated**: October 2025
**Companion to**: ERPNext Setup Guide (docs/ERPNEXT_SETUP.md)
