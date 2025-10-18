# Byrne Accounting Deployment Checklist

Use this checklist to ensure a successful deployment of the Byrne Accounting system.

## Pre-Deployment Checklist

### 1. Infrastructure Prerequisites

- [ ] SecureNexus core services running
  ```bash
  docker compose ps | grep -E "traefik|authentik_server|coredns"
  ```
  - [ ] Traefik (reverse proxy)
  - [ ] Authentik (SSO)
  - [ ] CoreDNS (DNS)
  - [ ] CrowdSec (security)

### 2. DNS Configuration

- [ ] External DNS configured at domain registrar
  ```
  byrneaccounting.net       A    137.74.40.208
  *.byrneaccounting.net     A    137.74.40.208
  ```
  OR
  ```
  byrneaccounting.net       NS   ns1.securenexus.net
  byrneaccounting.net       NS   ns2.securenexus.net
  ```

- [ ] Verify DNS propagation
  ```bash
  dig byrneaccounting.net
  dig erp.byrneaccounting.net
  dig pos.byrneaccounting.net
  ```

### 3. System Resources

- [ ] Sufficient disk space (50GB+ available)
  ```bash
  df -h
  ```

- [ ] Sufficient memory (8GB+ RAM available)
  ```bash
  free -h
  ```

- [ ] CPU cores (4+ recommended)
  ```bash
  nproc
  ```

### 4. Secrets Preparation

- [ ] Generate all required secrets
  ```bash
  make secrets
  ```

- [ ] Verify Byrne secrets created
  ```bash
  ls -la secrets/erpnext_*
  ```

- [ ] Save ERPNext admin password
  ```bash
  cat secrets/erpnext_admin_password.txt > ~/erpnext_admin_password_backup.txt
  chmod 600 ~/erpnext_admin_password_backup.txt
  ```

### 5. Docker Configuration

- [ ] Validate Docker Compose syntax
  ```bash
  docker compose config --quiet && echo "✓ Valid"
  ```

- [ ] Check Byrne services defined
  ```bash
  docker compose --profile byrne config --services
  ```
  Should show 8 services: byrne-website, erpnext-db, erpnext-redis-cache, erpnext-redis-queue, erpnext-backend, erpnext-worker, erpnext-scheduler

---

## Deployment Steps

### Step 1: Initial Deployment

- [ ] Build and start all Byrne services
  ```bash
  make up-byrne
  ```

- [ ] Verify services started
  ```bash
  docker compose ps | grep -E "byrne|erpnext"
  ```
  All should show `Up` status

### Step 2: Monitor ERPNext Initialization

- [ ] Watch ERPNext backend logs
  ```bash
  docker compose logs -f erpnext-backend
  ```

- [ ] Wait for initialization messages (5-10 minutes)
  Look for:
  - ✓ Database initialized
  - ✓ Site erp.byrneaccounting.net created
  - ✓ App erpnext installed
  - ✓ Bench started

- [ ] Verify all containers healthy
  ```bash
  docker compose ps | grep -E "byrne|erpnext"
  ```
  Look for `healthy` status on all services with health checks

### Step 3: Install AwesomePOS

- [ ] Wait for ERPNext to be fully ready
  ```bash
  docker compose exec erpnext-backend bench --site erp.byrneaccounting.net list-apps
  ```
  Should show: frappe, erpnext

- [ ] Install AwesomePOS plugin
  ```bash
  make install-awesomepos
  ```

- [ ] Verify AwesomePOS installed
  ```bash
  docker compose exec erpnext-backend bench --site erp.byrneaccounting.net list-apps
  ```
  Should show: frappe, erpnext, awesome_pos

---

## Post-Deployment Verification

### 1. Website Access Tests

- [ ] Public website accessible
  ```bash
  curl -I https://byrneaccounting.net
  # Should return: HTTP/2 200
  ```

- [ ] Portal page accessible
  ```bash
  curl -I https://byrneaccounting.net/portal
  # Should return: HTTP/2 200
  ```

- [ ] Visual check in browser
  - [ ] https://byrneaccounting.net loads with proper styling
  - [ ] Navigation works
  - [ ] Portal page accessible

### 2. ERP System Tests

- [ ] ERP redirects to Authentik (SSO protection active)
  ```bash
  curl -I https://erp.byrneaccounting.net
  # Should return: HTTP/2 302 (redirect)
  ```

- [ ] Test direct admin login (temporarily bypass SSO if needed)
  - [ ] Access via https://erp.byrneaccounting.net
  - [ ] Login as: Administrator
  - [ ] Password from: `cat secrets/erpnext_admin_password.txt`
  - [ ] ERPNext dashboard loads

### 3. POS System Tests

- [ ] POS redirects to Authentik
  ```bash
  curl -I https://pos.byrneaccounting.net
  # Should return: HTTP/2 302 (redirect)
  ```

- [ ] AwesomePOS accessible from ERPNext
  - [ ] Login to ERPNext
  - [ ] Navigate to AwesomePOS menu
  - [ ] POS interface loads

### 4. Security Verification

- [ ] HTTPS enforced (HTTP redirects to HTTPS)
  ```bash
  curl -I http://byrneaccounting.net
  # Should return: HTTP/1.1 301 (redirect to HTTPS)
  ```

- [ ] Security headers present
  ```bash
  curl -I https://byrneaccounting.net | grep -E "Strict-Transport|X-Frame|X-Content"
  ```

- [ ] CrowdSec protection active on public site
  ```bash
  docker compose logs crowdsec_bouncer | tail -20
  ```

- [ ] SSO required for ERP/POS
  - [ ] Cannot access ERP without authentication
  - [ ] Cannot access POS without authentication

### 5. Database Connectivity

- [ ] PostgreSQL accepting connections
  ```bash
  docker compose exec erpnext-db pg_isready -U erpnext
  # Should return: accepting connections
  ```

- [ ] Redis cache responding
  ```bash
  docker compose exec erpnext-redis-cache redis-cli -a "$(cat secrets/erpnext_redis_cache_password.txt)" ping
  # Should return: PONG
  ```

- [ ] Redis queue responding
  ```bash
  docker compose exec erpnext-redis-queue redis-cli -a "$(cat secrets/erpnext_redis_queue_password.txt)" ping
  # Should return: PONG
  ```

### 6. Background Jobs

- [ ] Worker process running
  ```bash
  docker compose exec erpnext-worker pgrep -f "frappe worker"
  # Should return: process ID
  ```

- [ ] Scheduler process running
  ```bash
  docker compose exec erpnext-scheduler pgrep -f "frappe schedule"
  # Should return: process ID
  ```

---

## Authentik SSO Configuration

### 1. Create OAuth2 Provider

- [ ] Access Authentik admin: https://authentik.securenexus.net
- [ ] Navigate to: Applications → Providers → Create
- [ ] Fill in provider details:
  - Name: ERPNext Provider
  - Type: OAuth2/OpenID Provider
  - Client Type: Confidential
  - Redirect URIs:
    ```
    https://erp.byrneaccounting.net/api/method/frappe.integrations.oauth2_logins.custom/callback
    https://pos.byrneaccounting.net/api/method/frappe.integrations.oauth2_logins.custom/callback
    ```
  - Scopes: openid profile email
- [ ] Save provider
- [ ] Copy Client ID and Client Secret

### 2. Create Authentik Application

- [ ] Navigate to: Applications → Create
- [ ] Fill in application details:
  - Name: Byrne Accounting - ERPNext
  - Slug: byrne-erp
  - Provider: Select the provider created above
  - Launch URL: https://erp.byrneaccounting.net
- [ ] Save application
- [ ] Assign users or groups who should have access

### 3. Configure ERPNext OAuth

- [ ] Temporarily access ERPNext as Administrator
- [ ] Go to: Settings → Social Login Key → New
- [ ] Fill in OAuth configuration:
  - Provider: Custom
  - Client ID: (from Authentik)
  - Client Secret: (from Authentik)
  - Authorize URL: https://sso.securenexus.net/application/o/authorize/
  - Access Token URL: https://sso.securenexus.net/application/o/token/
  - Redirect URL: https://erp.byrneaccounting.net/api/method/frappe.integrations.oauth2_logins.custom/callback
  - API Endpoint: https://sso.securenexus.net/application/o/userinfo/
- [ ] Save configuration

### 4. Test SSO Flow

- [ ] Log out of ERPNext
- [ ] Access https://erp.byrneaccounting.net
- [ ] Should redirect to Authentik login
- [ ] Log in with Authentik credentials
- [ ] Should redirect back to ERPNext and log in automatically
- [ ] Verify user created in ERPNext

---

## Post-Configuration Tasks

### 1. ERPNext Initial Setup

- [ ] Change Administrator password
  - Go to: User → Administrator → Change Password

- [ ] Complete setup wizard
  - Company details
  - Chart of accounts
  - Fiscal year
  - Currency

- [ ] Create user accounts
  - Go to: Users → Add User
  - Assign appropriate roles

### 2. POS Configuration

- [ ] Configure POS Profile
  - Go to: Retail → POS Profile → Default POS Profile
  - Set warehouse, price list, payment methods

- [ ] Set up inventory items
  - Go to: Stock → Item → New
  - Add items to sell via POS

- [ ] Configure payment methods
  - Go to: Accounts → Mode of Payment
  - Set up Cash, Credit Card, etc.

### 3. Security Hardening

- [ ] Enable MFA in Authentik for all users
  - Go to: Flows & Stages → Create MFA stage
  - Add to authentication flow

- [ ] Review user permissions
  - Ensure least privilege principle
  - Revoke unnecessary admin access

- [ ] Set up session timeouts
  - Configure in Authentik policies

### 4. Backup Verification

- [ ] Verify backups include Byrne data
  ```bash
  sudo ./scripts/backup-rotation.sh
  ls -la /backup/securenexus/daily/
  ```

- [ ] Check backup manifest
  ```bash
  cat /backup/securenexus/daily/*/MANIFEST.txt | grep -E "erpnext|byrne"
  ```

- [ ] Test database restoration (optional but recommended)
  ```bash
  # Create test backup
  docker compose exec -T erpnext-db pg_dump -U erpnext erpnext > test_backup.sql
  # Verify backup is valid
  head -20 test_backup.sql
  ```

---

## Monitoring Setup

### 1. Log Monitoring

- [ ] Set up log rotation for Byrne services
  ```bash
  # Logs automatically managed by Docker
  docker compose logs byrne-website --tail=100
  docker compose logs erpnext-backend --tail=100
  ```

- [ ] Configure log aggregation (optional)
  - Loki already configured in monitoring stack
  - Byrne logs automatically shipped via Promtail

### 2. Uptime Monitoring

- [ ] Add monitors in Uptime Kuma
  - https://byrneaccounting.net (HTTP 200)
  - https://erp.byrneaccounting.net (HTTP 302 redirect)
  - https://pos.byrneaccounting.net (HTTP 302 redirect)

### 3. Prometheus Metrics (Optional)

- [ ] ERPNext exposes metrics on :9090/metrics
- [ ] Add Prometheus scrape config if needed
  ```yaml
  # monitoring/prometheus.yml
  - job_name: 'erpnext'
    static_configs:
      - targets: ['erpnext-backend:9090']
  ```

---

## Troubleshooting Common Issues

### If ERPNext Won't Start

```bash
# Check database
docker compose ps erpnext-db
docker compose logs erpnext-db

# Check Redis
docker compose ps | grep erpnext-redis
docker compose logs erpnext-redis-cache

# Restart with proper order
docker compose restart erpnext-db erpnext-redis-cache erpnext-redis-queue
sleep 10
docker compose restart erpnext-backend
```

### If Website Shows 502 Error

```bash
# Check container status
docker compose ps byrne-website

# Check logs
docker compose logs byrne-website

# Rebuild and restart
make build-byrne-website
docker compose up -d byrne-website
```

### If AwesomePOS Installation Fails

```bash
# Ensure ERPNext is fully ready
docker compose exec erpnext-backend bench --site erp.byrneaccounting.net console

# Manually install
docker exec -it erpnext-backend bash
cd /home/frappe/frappe-bench
bench get-app https://github.com/awesome-erp/awesome_pos --branch version-15
bench --site erp.byrneaccounting.net install-app awesome_pos
bench build --apps awesome_pos
exit

docker compose restart erpnext-backend
```

---

## Final Verification

### System Health Check

- [ ] All containers running and healthy
  ```bash
  docker compose ps | grep -E "byrne|erpnext"
  ```

- [ ] No errors in logs
  ```bash
  docker compose logs --tail=50 | grep -i error
  ```

- [ ] Disk space adequate
  ```bash
  df -h
  docker system df
  ```

### Functional Tests

- [ ] Can browse public website
- [ ] Can access client portal
- [ ] Can log in to ERP via SSO
- [ ] Can access POS via SSO
- [ ] Can create test item in ERPNext
- [ ] Can make test sale in POS
- [ ] Background jobs processing
- [ ] Scheduled tasks running

### Security Audit

- [ ] HTTPS enforced everywhere
- [ ] SSO working correctly
- [ ] CrowdSec protection active
- [ ] Security headers present
- [ ] No default passwords in use
- [ ] Secrets properly secured
- [ ] Backups working

---

## Deployment Complete!

Once all items are checked, your Byrne Accounting system is fully deployed and operational.

### Quick Reference

**Access URLs**:
- Website: https://byrneaccounting.net
- ERP: https://erp.byrneaccounting.net
- POS: https://pos.byrneaccounting.net

**Admin Credentials**:
- Username: Administrator
- Password: `cat secrets/erpnext_admin_password.txt`

**Common Commands**:
```bash
# View status
docker compose ps | grep -E "byrne|erpnext"

# View logs
docker compose logs -f erpnext-backend

# Restart services
docker compose restart erpnext-backend

# Backup
sudo ./scripts/backup-rotation.sh
```

**Documentation**:
- Full Setup Guide: `docs/BYRNE_ACCOUNTING_SETUP.md`
- Implementation Summary: `docs/BYRNE_ACCOUNTING_SUMMARY.md`
- Quick Start: `byrne-website/README.md`

---

**Deployment Date**: _______________
**Deployed By**: _______________
**Notes**: _______________
