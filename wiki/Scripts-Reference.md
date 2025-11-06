# Scripts Reference

**Location:** `scripts/`
**Total Scripts:** 30+
**Language:** Bash, Python
**Purpose:** Automation, provisioning, management

---

## Quick Reference

### Client Provisioning
| Script | Purpose | Usage |
|--------|---------|-------|
| `provision-client-complete.sh` | Complete client setup | `./scripts/provision-client-complete.sh client-name domain.com` |
| `onboard-new-client.sh` | Initialize new client | `./scripts/onboard-new-client.sh client-name` |

### ERP Management
| Script | Purpose | Usage |
|--------|---------|-------|
| `erp-setup-wizard.sh` | Run ERP setup wizard | `./scripts/erp-setup-wizard.sh site-url` |
| `erp-automate-setup.py` | Python automation | `python3 ./scripts/erp-automate-setup.py` |
| `monitor-erpnext-install.sh` | Monitor installation | `./scripts/monitor-erpnext-install.sh` |

### SSO Configuration
| Script | Purpose | Usage |
|--------|---------|-------|
| `automate-erpnext-sso.sh` | Configure ERP SSO | `./scripts/automate-erpnext-sso.sh` |
| `setup-dickinson-sso.sh` | Dickinson SSO setup | `./scripts/setup-dickinson-sso.sh` |

### Branding & Themes
| Script | Purpose | Usage |
|--------|---------|-------|
| `apply-byrne-theme.sh` | Apply Byrne branding | `./scripts/apply-byrne-theme.sh` |
| `apply-dickson-theme.sh` | Apply Dickinson branding | `./scripts/apply-dickson-theme.sh` |

### User Management
| Script | Purpose | Usage |
|--------|---------|-------|
| `create-sysadmin-user.sh` | Create admin user | `./scripts/create-sysadmin-user.sh username email` |
| `create-dickinson-user.sh` | Create client user | `./scripts/create-dickinson-user.sh` |
| `list-users-by-group.sh` | List users by group | `./scripts/list-users-by-group.sh group-name` |
| `configure-app-access.sh` | Configure access | `./scripts/configure-app-access.sh app user` |

### Backup & Maintenance
| Script | Purpose | Usage |
|--------|---------|-------|
| `backup-all.sh` | Full system backup | `./scripts/backup-all.sh` |
| `backup-rotation.sh` | Backup with rotation | `./scripts/backup-rotation.sh` |

### Email Integration
| Script | Purpose | Usage |
|--------|---------|-------|
| `mailcow-get-api-key.sh` | Get Mailcow API key | `./scripts/mailcow-get-api-key.sh` |

### Monitoring
| Script | Purpose | Usage |
|--------|---------|-------|
| `postgres-exporter-wrapper.sh` | PostgreSQL metrics | `./scripts/postgres-exporter-wrapper.sh` |
| `redis-exporter-wrapper.sh` | Redis metrics | `./scripts/redis-exporter-wrapper.sh` |
| `redis-exporter-entrypoint.sh` | Redis exporter setup | Used in Docker |

### Security & Access
| Script | Purpose | Usage |
|--------|---------|-------|
| `remove-vpn-requirement.sh` | Remove VPN requirement | `./scripts/remove-vpn-requirement.sh service` |
| `keycloak-fix-frame-options.sh` | Fix Keycloak headers | `./scripts/keycloak-fix-frame-options.sh` |
| `verify-keycloak-headers.sh` | Verify headers | `./scripts/verify-keycloak-headers.sh` |

---

## Detailed Documentation

### Client Provisioning Scripts

#### provision-client-complete.sh
**Purpose:** Complete automated client deployment
**Time:** 15-20 minutes
**Requirements:** Docker, compose, secrets

**Usage:**
```bash
./scripts/provision-client-complete.sh client-name client-domain.com
```

**Steps Performed:**
1. Validates prerequisites
2. Creates database secrets
3. Generates Redis passwords
4. Creates admin password
5. Adds service definitions to compose.yml
6. Creates DNS zone file
7. Starts infrastructure services
8. Creates ERPNext site
9. Installs ERPNext and POS apps
10. Configures SSO with Authentik
11. Applies custom branding
12. Creates SSL certificates
13. Verifies deployment
14. Creates backup

**Output:**
- New client fully operational
- DNS configured
- SSL active
- SSO working
- Admin credentials saved

**Error Handling:**
- Validates each step
- Rolls back on failure
- Saves logs to `/tmp/provision-client.log`

---

#### onboard-new-client.sh
**Purpose:** Initial client setup (manual steps)
**Time:** 5 minutes

**Usage:**
```bash
./scripts/onboard-new-client.sh client-name
```

**Steps:**
1. Creates directory structure
2. Generates secrets
3. Templates configuration files
4. Provides next steps

**Requires Manual:**
- Adding to compose.yml
- DNS configuration
- Service restart

---

### ERP Management Scripts

#### erp-setup-wizard.sh
**Purpose:** Automate ERPNext setup wizard
**Time:** 2-3 minutes

**Usage:**
```bash
./scripts/erp-setup-wizard.sh https://erp.client.com
```

**Configures:**
- Company information
- Fiscal year
- Currency
- Country/region
- Chart of accounts
- Tax settings
- Initial modules

**Interactive:** Prompts for company details

---

#### monitor-erpnext-install.sh
**Purpose:** Monitor long-running installations
**Time:** Continuous until complete

**Usage:**
```bash
./scripts/monitor-erpnext-install.sh container-name
```

**Monitors:**
- Installation progress
- Error messages
- Completion status
- Resource usage

**Output:** Real-time log streaming

---

### SSO Configuration Scripts

#### automate-erpnext-sso.sh
**Purpose:** Configure Authentik SSO for ERPNext
**Time:** 2-3 minutes

**Usage:**
```bash
./scripts/automate-erpnext-sso.sh
```

**Requires:**
- Authentik running
- ERPNext site created
- OAuth credentials

**Configures:**
- OAuth provider in Authentik
- Application in Authentik
- site_config.json in ERPNext
- Attribute mappings

**Output:** SSO login button on ERPNext

---

### Branding Scripts

#### apply-byrne-theme.sh
**Purpose:** Apply Byrne Accounting branding
**Time:** 1 minute

**Usage:**
```bash
./scripts/apply-byrne-theme.sh
```

**Applies:**
- Logo upload
- Color scheme (blue/green)
- Custom CSS
- Favicon
- Login page branding

**Files Modified:**
- Website Settings
- Custom CSS
- public/files/

---

### User Management Scripts

#### create-sysadmin-user.sh
**Purpose:** Create system administrator account
**Time:** 30 seconds

**Usage:**
```bash
./scripts/create-sysadmin-user.sh username email@domain.com
```

**Creates:**
- User in Authentik
- Admin group membership
- Initial password (random)
- Email notification

**Output:** Credentials saved to secrets/

---

#### list-users-by-group.sh
**Purpose:** Query users in specific groups
**Time:** Instant

**Usage:**
```bash
./scripts/list-users-by-group.sh group-name
```

**Output:**
- Username
- Email
- Full name
- Active status
- Last login

**Format:** Table or JSON

---

### Backup Scripts

#### backup-all.sh
**Purpose:** Complete system backup
**Time:** 5-10 minutes (depends on data size)

**Usage:**
```bash
./scripts/backup-all.sh
```

**Backs Up:**
- PostgreSQL databases (Authentik, Keycloak)
- MariaDB databases (all ERP instances)
- MySQL database (CoreDNS)
- etcd snapshot (DNS records)
- Grafana dashboards
- Prometheus data
- Loki logs
- Uptime Kuma data
- Configuration files
- Secrets (encrypted)
- SSL certificates

**Output Location:** `/backup/securenexus/YYYYMMDD_HHMMSS/`
**Manifest:** Created in backup directory

---

#### backup-rotation.sh
**Purpose:** Backup with rotation policy
**Time:** 5-10 minutes + cleanup

**Usage:**
```bash
./scripts/backup-rotation.sh
```

**Rotation Policy:**
- Daily: Keep 7 days (Monday-Saturday)
- Weekly: Keep 4 weeks (Sunday backups)
- Monthly: Keep 12 months (1st of month)

**Automated:** Via cron at 2:00 AM daily

---

### Monitoring Scripts

#### postgres-exporter-wrapper.sh
**Purpose:** Wrapper for PostgreSQL exporter
**Usage:** Called by Docker container

**Exports Metrics:**
- Connection count
- Query performance
- Database size
- Cache hit ratio
- Replication lag

**Endpoint:** `:9187/metrics`

---

#### redis-exporter-wrapper.sh
**Purpose:** Wrapper for Redis exporter
**Usage:** Called by Docker container

**Exports Metrics:**
- Memory usage
- Hit rate
- Eviction count
- Connected clients
- Command stats

**Endpoint:** `:9121/metrics`

---

### Security Scripts

#### remove-vpn-requirement.sh
**Purpose:** Remove VPN requirement from service
**Time:** 1 minute

**Usage:**
```bash
./scripts/remove-vpn-requirement.sh service-name
```

**Modifies:**
- Traefik labels
- Removes `admin-vpn` middleware
- Adds alternative security (CrowdSec, SSO)

**Warning:** Only use for services that should be public

---

#### keycloak-fix-frame-options.sh
**Purpose:** Fix X-Frame-Options for Keycloak
**Time:** 1 minute

**Usage:**
```bash
./scripts/keycloak-fix-frame-options.sh
```

**Fixes:**
- X-Frame-Options header
- Content-Security-Policy
- Allows iframe embedding (if needed)

---

## Script Development Guidelines

### Creating New Scripts

**Template:**
```bash
#!/bin/bash
set -euo pipefail

# Script: script-name.sh
# Purpose: Brief description
# Usage: ./script-name.sh [args]

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Functions
function log_info() {
    echo "[INFO] $1"
}

function log_error() {
    echo "[ERROR] $1" >&2
}

# Main logic
function main() {
    log_info "Starting script"
    # Implementation
    log_info "Complete"
}

# Run
main "$@"
```

**Best Practices:**
- Use `set -euo pipefail` for safety
- Include usage documentation
- Log all operations
- Handle errors gracefully
- Validate inputs
- Provide progress feedback
- Create backups before modifications
- Test in non-production first

---

## Common Script Patterns

### Docker Compose Operations
```bash
# Execute command in container
docker compose exec service-name command

# Copy file to container
docker compose cp local-file service:/container/path

# Get container logs
docker compose logs service-name --tail 100
```

### Secret Management
```bash
# Generate random secret
openssl rand -base64 32 > secrets/secret-name.txt

# Read secret in script
SECRET=$(cat secrets/secret-name.txt)

# Use secret in Docker
secrets:
  - secret-name
```

### Error Handling
```bash
# Check command success
if ! docker compose ps service-name; then
    log_error "Service not running"
    exit 1
fi

# Cleanup on error
trap cleanup EXIT ERR
function cleanup() {
    log_info "Cleaning up"
    # Cleanup operations
}
```

---

## Troubleshooting Scripts

### Script Fails to Execute

**Issue:** Permission denied
```bash
# Fix permissions
chmod +x scripts/script-name.sh
```

**Issue:** Command not found
```bash
# Check dependencies
which docker
which docker-compose
```

### Script Hangs

**Issue:** Waiting for input
```bash
# Run with timeout
timeout 300 ./scripts/script-name.sh
```

**Issue:** Container not responding
```bash
# Check container status
docker compose ps
docker compose logs service-name
```

### Script Errors

**Check Logs:**
```bash
# Script logs (if logging to file)
tail -f /tmp/script-name.log

# System logs
journalctl -f
```

**Debug Mode:**
```bash
# Run with debug output
bash -x ./scripts/script-name.sh
```

---

## Script Locations

**All scripts:** `scripts/`
**Log files:** `/tmp/` or `/var/log/`
**Backup outputs:** `/backup/securenexus/`
**Configuration:** Project root directory

---

**Total Scripts:** 30+
**Last Updated:** November 6, 2025
**Status:** ✅ Production Ready
