# Complete Client Onboarding Guide

Unified end-to-end client provisioning and ERPNext configuration wizard.

## Overview

The client onboarding script provides a **single command** to:
1. ✅ Collect client information
2. ✅ Provision complete infrastructure (ERP + Email + Routing)
3. ✅ Launch interactive ERPNext configuration wizard
4. ✅ Generate comprehensive access credentials
5. ✅ Provide next steps and handoff documentation

## Quick Start

```bash
cd /home/tristian/securenexus-fullstack
./scripts/onboard-new-client.sh
```

That's it! The wizard will guide you through everything.

## What Gets Created

### Infrastructure (Automatic)
- **ERPNext Site**: Custom subdomain (e.g., `acme.byrne-accounts.org`)
- **Database**: Dedicated MariaDB database for client
- **Email System**:
  - Main mailbox: `subdomain@domain.com`
  - 5 aliases: support@, info@, financial@, sales@, accounts@
  - Webmail access via Mailcow
- **SSL Certificates**: Automatic via Let's Encrypt
- **HTTPS Routing**: Traefik reverse proxy configuration
- **POS Awesome**: Pre-installed point of sale system

### Configuration (Guided Wizard)
The wizard walks through 16 comprehensive sections:

#### Essential Setup (Sections 1-10)
1. Initial ERPNext setup wizard
2. Company settings & details
3. Chart of accounts
4. Point of Sale configuration
5. Inventory & warehouse management
6. Products/services catalog
7. User management & permissions
8. Email integration
9. Print formats & templates
10. Custom branding

#### Advanced Features (Sections 11-16)
11. Advanced accounting (budgeting, cost centers)
12. HR & payroll
13. CRM & sales pipeline
14. Custom reports & dashboards
15. Workflow automation
16. System testing & verification

## Workflow Phases

### Phase 1: Client Information Collection

The script prompts for:

```
Client Company Name: ACME Corporation
Subdomain for ERP: acme
Email domain: acmecorp.com (or press Enter for byrne-accounts.org)
Subscription plan: [starter/professional/enterprise]
```

**Generates:**
- ERP URL: `https://acme.byrne-accounts.org`
- Main Email: `acme@acmecorp.com`
- Secure passwords (20 characters, cryptographically random)

### Phase 2: Infrastructure Provisioning

Automatically creates:

```
✓ ERPNext site with custom domain
✓ Database and application stack
✓ Email domain and mailbox (10GB quota)
✓ Email aliases (5 addresses → 1 inbox)
✓ Traefik HTTPS routing
✓ SSL certificates
✓ POS Awesome installation
```

**Behind the scenes:**
- Calls `provision-client-complete.sh`
- Creates database: `_acme_byrne_accounts_org`
- Configures Mailcow via API
- Updates Traefik routing
- Saves credentials to `client-credentials/`

### Phase 3: ERPNext Configuration Wizard

Launches the interactive wizard (`erp-setup-wizard.sh`) with:
- Pre-configured site URL
- Admin credentials displayed
- Progress tracking
- Section-by-section guidance

**User can:**
- Complete all sections in one session
- Resume later (progress is saved)
- Skip advanced sections
- Jump to any section non-linearly

### Phase 4: Completion Summary

Shows:
- All access URLs and credentials
- Credentials file location
- Next steps checklist
- Useful commands
- Client handoff instructions

## Example Session

```bash
$ ./scripts/onboard-new-client.sh

╔═══════════════════════════════════════════════════════════════╗
║   ██████╗ ██╗   ██╗██████╗ ███╗   ██╗███████╗                ║
║   ██╔══██╗╚██╗ ██╔╝██╔══██╗████╗  ██║██╔════╝                ║
║   ██████╔╝ ╚████╔╝ ██████╔╝██╔██╗ ██║█████╗                  ║
║   ██╔══██╗  ╚██╔╝  ██╔══██╗██║╚██╗██║██╔══╝                  ║
║   ██████╔╝   ██║   ██║  ██║██║ ╚████║███████╗                ║
║   ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝                ║
║                                                               ║
║            COMPLETE CLIENT ONBOARDING WIZARD                  ║
║         Infrastructure + Full ERPNext Configuration           ║
╚═══════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════
  PHASE 1: Client Information Collection
═══════════════════════════════════════════════════════════════

Client Company Name: ACME Corporation
Subdomain for ERP: acme
Email domain [byrne-accounts.org]: acmecorp.com

Subscription Plan:
  1) Starter   - Basic features
  2) Professional - Full features (recommended)
  3) Enterprise - Advanced features + priority support
Select plan [1-3] (default: 2): 2

[... shows summary and asks for confirmation ...]

═══════════════════════════════════════════════════════════════
  PHASE 2: Infrastructure Provisioning
═══════════════════════════════════════════════════════════════

✓ ERPNext site created
✓ POS Awesome installed
✓ Mailbox created: acme@acmecorp.com
✓ Email aliases created (5)
✓ Traefik routing configured
✓ Credentials saved

═══════════════════════════════════════════════════════════════
  PHASE 3: ERPNext Configuration Wizard
═══════════════════════════════════════════════════════════════

[... launches interactive wizard ...]

═══════════════════════════════════════════════════════════════
  CLIENT ONBOARDING COMPLETE! 🎉
═══════════════════════════════════════════════════════════════
```

## Subscription Plans

### Starter
- Basic ERPNext features
- Single user
- Email support
- Standard SLA

### Professional (Recommended)
- Full ERPNext features
- Unlimited users
- POS Awesome
- Email + phone support
- Priority SLA

### Enterprise
- Everything in Professional
- Custom integrations
- Dedicated support
- Custom SLA
- Training included

## Generated Credentials File

Location: `client-credentials/{site-domain}.txt`

Example:
```
═══════════════════════════════════════════════════════════
  ACME Corporation - Complete Access Credentials
═══════════════════════════════════════════════════════════

PORTAL ACCESS:
  URL: https://byrne-accounts.org/portal.html
  Select: "ACME Corporation" from dropdown

ERP SYSTEM:
  URL: https://acme.byrne-accounts.org
  Username: Administrator
  Password: aB3dE5fG7hJ9kL2mN4pQ
  Features: Accounting, Inventory, CRM, HR, Projects

POS SYSTEM:
  URL: https://acme.byrne-accounts.org/pos
  Username: Administrator
  Password: aB3dE5fG7hJ9kL2mN4pQ

EMAIL SYSTEM:
  Webmail: https://mail.securenexus.net
  Main Email: acme@acmecorp.com
  Password: xY8zW6vU4tS2rQ1pO3nM

  Available Addresses (all go to acme@acmecorp.com):
  • acme@acmecorp.com (main inbox)
  • support@acmecorp.com
  • info@acmecorp.com
  • financial@acmecorp.com
  • sales@acmecorp.com
  • accounts@acmecorp.com

SUBSCRIPTION:
  Plan: professional
  Created: 2025-10-31
  Database: _acme_byrne_accounts_org
```

## Progress Tracking & Resuming

The wizard saves progress automatically:

```bash
# Phase tracking file
/tmp/client-onboarding-phase.txt

# ERPNext wizard progress
/tmp/erp-wizard-progress.txt
```

**Resume a paused onboarding:**
```bash
# Just run the script again
./scripts/onboard-new-client.sh

# It will resume from the last completed phase
```

**Start fresh:**
```bash
# Remove progress files
rm /tmp/client-onboarding-phase.txt
rm /tmp/erp-wizard-progress.txt

# Run script
./scripts/onboard-new-client.sh
```

## Post-Onboarding Tasks

### 1. Add to Portal Dropdown

Edit `byrne-website/portal.html`:

```html
<select id="clientSelector">
  <option value="">Select Client</option>
  <option value="acme.byrne-accounts.org">ACME Corporation</option>
  <!-- Add your new client here -->
</select>
```

### 2. DNS Configuration (if using custom domain)

Add DNS records for email domain:

```
MX    @    10 mail.securenexus.net
TXT   @    "v=spf1 mx a:mail.securenexus.net ~all"
TXT   _dmarc    "v=DMARC1; p=quarantine; rua=mailto:postmaster@acmecorp.com"
```

### 3. Send Welcome Email

```bash
# View credentials to send to client
cat client-credentials/acme.byrne-accounts.org.txt

# Include:
# - Access URLs
# - Login credentials
# - Quick start guide
# - Support contact information
# - Training schedule (if applicable)
```

### 4. Import Client Data

**Via ERPNext:**
1. Login as Administrator
2. Go to: Data Import
3. Import spreadsheets for:
   - Customers
   - Suppliers
   - Items/Products
   - Opening balances

### 5. Custom Configuration

**Company-specific setup:**
- Custom fields (if needed)
- Workflow approvals
- Print format branding
- Email templates
- Custom reports

### 6. User Training

**Schedule:**
- System overview (1 hour)
- Daily operations (2 hours)
- Reporting & analysis (1 hour)
- Support & troubleshooting (30 min)

**Materials:**
- `docs/ERPNEXT_QUICK_REFERENCE.md`
- `docs/ERPNEXT_WIZARD_GUIDE.md`
- Official ERPNext docs

### 7. Go-Live Checklist

- [ ] All client data imported
- [ ] Test transaction complete (quote → order → invoice → payment)
- [ ] POS tested with sample items
- [ ] Email send/receive working
- [ ] Print formats reviewed and approved
- [ ] Users created with appropriate permissions
- [ ] Backup schedule verified
- [ ] Support channel established
- [ ] Client trained and comfortable

## Troubleshooting

### Infrastructure provisioning fails

```bash
# Check Docker containers
docker compose ps | grep erpnext

# View logs
docker compose logs erpnext-backend

# Restart services
docker compose restart erpnext-backend erpnext-db
```

### Email creation fails

If Mailcow API key is missing:

```bash
# Get API key manually
./scripts/mailcow-get-api-key.sh

# Save to secrets
echo "YOUR_API_KEY" > secrets/mailcow_api_key.txt

# Retry provisioning
```

Or create mailbox manually:
1. Login: https://mail.securenexus.net
2. Mailboxes → Add mailbox
3. Fill in details from credentials file

### ERPNext site not accessible

```bash
# Verify Traefik routing
docker compose logs traefik | grep acme

# Check DNS
dig acme.byrne-accounts.org

# Restart Traefik
docker compose restart traefik

# Verify site exists
docker exec -it erpnext-backend bench --site acme.byrne-accounts.org list-apps
```

### Wizard won't launch

```bash
# Check script exists
ls -lh scripts/erp-setup-wizard.sh

# Make executable
chmod +x scripts/erp-setup-wizard.sh

# Run manually
./scripts/erp-setup-wizard.sh
```

## Related Documentation

- `docs/ERPNEXT_WIZARD_GUIDE.md` - Detailed wizard usage
- `docs/ERPNEXT_COMPLETE_SETUP_GUIDE.md` - Manual setup guide
- `docs/ERPNEXT_MULTI_COMPANY_AND_MULTISITE.md` - Multi-tenant architecture
- `docs/ERPNEXT_MAILCOW_INTEGRATION.md` - Email system details
- `docs/ONE_COMMAND_PROVISIONING.md` - Infrastructure provisioning

## Command Reference

```bash
# Full onboarding (recommended)
./scripts/onboard-new-client.sh

# Just provision infrastructure (no wizard)
./scripts/provision-client-complete.sh --name "ACME Corp" --subdomain "acme"

# Just run ERPNext wizard (infrastructure exists)
./scripts/erp-setup-wizard.sh

# View client credentials
cat client-credentials/{site-domain}.txt

# List all clients
ls -1 client-credentials/

# Remove client (DESTRUCTIVE)
docker exec erpnext-backend bench drop-site {site-domain} --force
```

## Security Best Practices

1. **Secure Credentials File**
   - Permissions: 600 (owner read/write only)
   - Delete after sending to client
   - Use encrypted email for transmission

2. **Change Default Passwords**
   - Client should change passwords on first login
   - Enable two-factor authentication
   - Set password expiry policies

3. **User Permissions**
   - Create role-based access
   - Disable Administrator account for daily use
   - Regular permission audits

4. **Backups**
   - Automated daily backups (already configured)
   - Test restore procedures monthly
   - Off-site backup replication

## Tips for Success

1. **Complete in One Session**: Aim to finish infrastructure + essential wizard sections (1-10) in one sitting
2. **Test Everything**: Run test transactions before client goes live
3. **Document Customizations**: Keep notes on any custom fields, workflows, or configurations
4. **Set Expectations**: Train client on what they'll need to provide (customers, items, etc.)
5. **Schedule Follow-up**: Book check-in call 1 week after go-live

## Support

For issues or questions:
- Email: support@byrne-accounts.org
- Documentation: `/docs` directory
- ERPNext Forum: https://discuss.erpnext.com
- Frappe Cloud: https://frappecloud.com/support

---

**Version**: 1.0
**Last Updated**: October 31, 2025
**Maintainer**: Byrne Accounts Team
