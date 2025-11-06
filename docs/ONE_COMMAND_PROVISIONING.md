# One-Command Client Provisioning Guide

## Overview

**Complete client setup in ONE command** including:
- ✅ ERPNext site (business management)
- ✅ POS Awesome (point of sale)
- ✅ Email system with **multiple addresses → ONE inbox**
- ✅ Traefik routing (HTTPS)
- ✅ Credential generation
- ✅ Documentation

**Time**: ~5 minutes
**Manual steps**: Just 2 (add Traefik labels + add to portal)

---

## The Magic: Email Alias System

### Problem
Clients need multiple professional email addresses:
- `support@client.com` - for customer support
- `info@client.com` - for general inquiries
- `financial@client.com` - for billing
- `sales@client.com` - for sales inquiries
- `accounts@client.com` - for account management

**BUT** checking 5 different inboxes is a nightmare! 😱

### Solution: Email Aliases ✨

Create **ONE main mailbox**:
```
client@byrne-accounts.org  (the actual mailbox)
```

Create **aliases that forward to it**:
```
support@byrne-accounts.org   → client@byrne-accounts.org
info@byrne-accounts.org      → client@byrne-accounts.org
financial@byrne-accounts.org → client@byrne-accounts.org
sales@byrne-accounts.org     → client@byrne-accounts.org
accounts@byrne-accounts.org  → client@byrne-accounts.org
```

**Result**:
- ✅ Check ONE inbox
- ✅ Receive ALL emails
- ✅ Reply FROM any address
- ✅ Professional appearance

---

## Prerequisites

### 1. Mailcow API Key (One-Time Setup)

```bash
# 1. Login to Mailcow
https://mail.securenexus.net
Username: admin

# 2. Generate API key
User Menu (top right) → API → Generate Key

# 3. Save it
echo "YOUR-API-KEY" > secrets/mailcow_api_key.txt
chmod 600 secrets/mailcow_api_key.txt
```

**See**: `/docs/MAILCOW_API_SETUP.md` for detailed instructions

### 2. Verify Prerequisites

```bash
# Check secrets exist
ls -la secrets/erpnext_db_password.txt
ls -la secrets/mailcow_api_key.txt

# Check script is executable
ls -la scripts/provision-client-complete.sh
```

---

## Usage

### Basic Usage (Shared Email Domain)

```bash
./scripts/provision-client-complete.sh \
  --name "ACME Corporation" \
  --subdomain "acme"

# Creates:
# • ERP: acme.byrne-accounts.org
# • Email: acme@byrne-accounts.org
# • Aliases: support@, info@, financial@, sales@, accounts@
```

### Advanced Usage (Custom Domain)

```bash
./scripts/provision-client-complete.sh \
  --name "ACME Corporation" \
  --subdomain "acme" \
  --domain "acmecorp.com" \
  --plan "enterprise"

# Creates:
# • ERP: acme.byrne-accounts.org
# • Email: acme@acmecorp.com
# • Aliases: support@acmecorp.com, info@acmecorp.com, etc.
```

### Help

```bash
./scripts/provision-client-complete.sh --help
```

---

## What the Script Does

### Automated Steps (90%)

1. **Creates ERPNext Site**
   - Site: `{subdomain}.byrne-accounts.org`
   - Installs ERPNext + POS Awesome
   - Generates secure admin password
   - ~3 minutes

2. **Sets Up Email System**
   - Creates main mailbox: `{subdomain}@{domain}`
   - Creates 5 aliases (support@, info@, etc.)
   - All forward to main mailbox
   - Configures SOGo webmail access
   - ~30 seconds

3. **Generates Credentials**
   - ERP admin password (secure random)
   - Email password (secure random)
   - Saves to `/client-credentials/{site}.txt`
   - Read-only file permissions

4. **Creates Documentation**
   - Complete access instructions
   - All URLs and passwords
   - Email client settings
   - Support contact info

### Manual Steps (10%)

After script completes:

#### Step 1: Add Traefik Labels

Script shows you the labels. Add to `compose.yml`:

```yaml
# In erpnext-backend service labels section:
      # Client site: acme.byrne-accounts.org
      - traefik.http.routers.erp-acme.rule=Host(`acme.byrne-accounts.org`)
      - traefik.http.routers.erp-acme.entrypoints=websecure
      - traefik.http.routers.erp-acme.tls.certresolver=le
      - traefik.http.routers.erp-acme.middlewares=secure-headers@file
      - traefik.http.routers.erp-acme.service=erp
      - traefik.http.routers.erp-acme-http.rule=Host(`acme.byrne-accounts.org`)
      - traefik.http.routers.erp-acme-http.entrypoints=web
      - traefik.http.routers.erp-acme-http.middlewares=redirect-to-https@file
```

Then restart:
```bash
docker compose restart erpnext-backend
```

#### Step 2: Add to Portal

Edit `byrne-website/portal.html`:

```html
<select id="clientSelect">
    <option value="">-- Choose Client --</option>
    <option value="erp.byrne-accounts.org">Byrne Accounting (Internal)</option>
    <option value="demo.byrne-accounts.org">Demo Client</option>
    <option value="acme.byrne-accounts.org">ACME Corporation</option>  <!-- NEW -->
</select>
```

**Done!** Client is fully provisioned.

---

## Complete Example

### Provision "TechStart Inc"

```bash
./scripts/provision-client-complete.sh \
  --name "TechStart Inc" \
  --subdomain "techstart"
```

**Output**:
```
═══════════════════════════════════════════════════════════
  Byrne Accounts - Complete Client Provisioning
═══════════════════════════════════════════════════════════

Client Details:
  Name:          TechStart Inc
  Subdomain:     techstart
  ERP Site:      https://techstart.byrne-accounts.org
  Email Domain:  byrne-accounts.org
  Main Email:    techstart@byrne-accounts.org
  Plan:          professional

Generated Credentials:
  ERP Admin:     Administrator / kL9mP2nQ8vX4wR7t
  Email:         techstart@byrne-accounts.org / Bv5nM8jK3qP9wL2x

Continue with provisioning? (y/n) y

════════════════════════════════════════════════════════════
  Step 1: Creating ERPNext Site
════════════════════════════════════════════════════════════
Creating ERPNext site: techstart.byrne-accounts.org...
✓ ERPNext site created
Installing POS Awesome...
✓ POS Awesome installed

════════════════════════════════════════════════════════════
  Step 2: Setting Up Email System
════════════════════════════════════════════════════════════
Creating main mailbox: techstart@byrne-accounts.org...
✓ Mailbox created: techstart@byrne-accounts.org
Creating email aliases...
  ✓ Alias created: support@byrne-accounts.org → techstart@byrne-accounts.org
  ✓ Alias created: info@byrne-accounts.org → techstart@byrne-accounts.org
  ✓ Alias created: financial@byrne-accounts.org → techstart@byrne-accounts.org
  ✓ Alias created: sales@byrne-accounts.org → techstart@byrne-accounts.org
  ✓ Alias created: accounts@byrne-accounts.org → techstart@byrne-accounts.org
✓ Email system configured

════════════════════════════════════════════════════════════
  Step 3: Configuring Traefik Routing
════════════════════════════════════════════════════════════
Adding Traefik labels to compose.yml...

[Shows labels to add]

Press Enter after adding labels...

Restarting ERPNext backend...
✓ Traefik routing configured

════════════════════════════════════════════════════════════
  Step 4: Saving Credentials
════════════════════════════════════════════════════════════
✓ Credentials saved to: client-credentials/techstart.byrne-accounts.org.txt

════════════════════════════════════════════════════════════
  ✓ PROVISIONING COMPLETE!
════════════════════════════════════════════════════════════

Client Successfully Created:

  Client Name:    TechStart Inc
  ERP Site:       https://techstart.byrne-accounts.org
  POS:            https://techstart.byrne-accounts.org/pos
  Email:          techstart@byrne-accounts.org
  Aliases:        support@, info@, financial@, sales@, accounts@

Next Steps:

1. View credentials:
   cat client-credentials/techstart.byrne-accounts.org.txt

2. Test ERP access:
   https://techstart.byrne-accounts.org
   Login: Administrator / kL9mP2nQ8vX4wR7t

3. Test email:
   https://mail.securenexus.net
   Login: techstart@byrne-accounts.org / Bv5nM8jK3qP9wL2x

4. Send welcome email to client with credentials

Ready to onboard client! 🎉
```

### View Credentials

```bash
cat client-credentials/techstart.byrne-accounts.org.txt
```

**Output**:
```
═══════════════════════════════════════════════════════════
  TechStart Inc - Complete Access Credentials
═══════════════════════════════════════════════════════════

PORTAL ACCESS:
  URL: https://byrne-accounts.org/portal.html
  Select: "TechStart Inc" from dropdown

ERP SYSTEM:
  URL: https://techstart.byrne-accounts.org
  Username: Administrator
  Password: kL9mP2nQ8vX4wR7t
  Features: Accounting, Inventory, CRM, HR, Projects

POS SYSTEM:
  URL: https://techstart.byrne-accounts.org/pos
  Username: Administrator
  Password: kL9mP2nQ8vX4wR7t
  Features: Touch POS, Barcode Scanning, Offline Mode

EMAIL SYSTEM:
  Webmail: https://mail.securenexus.net
  Main Email: techstart@byrne-accounts.org
  Password: Bv5nM8jK3qP9wL2x

  Available Addresses (all go to techstart@byrne-accounts.org):
  • techstart@byrne-accounts.org (main inbox)
  • support@byrne-accounts.org
  • info@byrne-accounts.org
  • financial@byrne-accounts.org
  • sales@byrne-accounts.org
  • accounts@byrne-accounts.org

  Email Client Settings (IMAP/SMTP):
  • IMAP Server: mail.securenexus.net
  • IMAP Port: 993 (SSL/TLS)
  • SMTP Server: mail.securenexus.net
  • SMTP Port: 587 (STARTTLS) or 465 (SSL/TLS)
  • Username: techstart@byrne-accounts.org
  • Password: Bv5nM8jK3qP9wL2x

SUBSCRIPTION:
  Plan: professional
  Created: Mon Oct 28 2025 14:30:22
  Database: _techstart_byrne_accounts_org

NOTES:
  • All emails sent to support@, info@, financial@, sales@, or accounts@
    will be delivered to the main inbox: techstart@byrne-accounts.org
  • You can reply FROM any of these addresses in webmail
  • Only ONE inbox to monitor
  • Full calendar and contacts included

SUPPORT:
  Email: support@byrne-accounts.org
  Portal: https://byrne-accounts.org

═══════════════════════════════════════════════════════════
```

---

## Email Alias Benefits

### Scenario: Customer Support

**Customer sends email to**: `support@byrne-accounts.org`

**What happens**:
1. Email arrives at Mailcow server
2. Mailcow sees it's an alias
3. Forwards to main inbox: `techstart@byrne-accounts.org`
4. Client checks ONE inbox, sees the email
5. Client replies **FROM** `support@byrne-accounts.org`
6. Customer sees professional reply from support@

**Result**: Professional experience, ONE inbox!

### All Emails in One Place

Client only needs to check:
```
techstart@byrne-accounts.org
```

Receives emails sent to:
- `techstart@byrne-accounts.org`
- `support@byrne-accounts.org`
- `info@byrne-accounts.org`
- `financial@byrne-accounts.org`
- `sales@byrne-accounts.org`
- `accounts@byrne-accounts.org`

**No more checking multiple inboxes!**

---

## Custom Domain Email

### Client Wants Their Own Domain

```bash
./scripts/provision-client-complete.sh \
  --name "ACME Corporation" \
  --subdomain "acme" \
  --domain "acmecorp.com"

# Creates:
# • acme@acmecorp.com (main)
# • support@acmecorp.com → acme@acmecorp.com
# • info@acmecorp.com → acme@acmecorp.com
# • financial@acmecorp.com → acme@acmecorp.com
# • sales@acmecorp.com → acme@acmecorp.com
# • accounts@acmecorp.com → acme@acmecorp.com
```

### Additional DNS Setup Required

Add to `acmecorp.com` DNS:

```dns
; MX Record
acmecorp.com.  IN MX 10 mail.securenexus.net.

; SPF Record
acmecorp.com.  IN TXT "v=spf1 mx a:mail.securenexus.net ~all"

; DMARC Record
_dmarc.acmecorp.com.  IN TXT "v=DMARC1; p=quarantine; rua=mailto:postmaster@acmecorp.com"

; DKIM Record (get from Mailcow admin panel)
dkim._domainkey.acmecorp.com.  IN TXT "v=DKIM1; k=rsa; p=PASTE_PUBLIC_KEY_HERE"
```

**DNS propagation**: 1-24 hours

---

## Troubleshooting

### Script Can't Find Mailcow API Key

**Error**: `Mailcow API key not found`

**Solution**:
```bash
# Generate API key in Mailcow admin
# Save to secrets file
echo "YOUR-API-KEY" > secrets/mailcow_api_key.txt
chmod 600 secrets/mailcow_api_key.txt
```

**See**: `/docs/MAILCOW_API_SETUP.md`

### ERPNext Site Already Exists

**Error**: `Site already exists`

**Solution**:
```bash
# Choose a different subdomain
./scripts/provision-client-complete.sh \
  --name "ACME Corp" \
  --subdomain "acme2"  # Different subdomain
```

### Email Aliases Not Created

**Check**:
```bash
# Verify main mailbox exists first
# Aliases require destination mailbox to exist
```

**Manual creation**:
```bash
# Login to Mailcow admin
Configuration → Mail Setup → Aliases → Add Alias
Address: support@byrne-accounts.org
Destination: techstart@byrne-accounts.org
```

### SSL Certificate Pending

**Info**: Let's Encrypt takes 5-10 minutes to issue certificate

**Check status**:
```bash
docker compose logs traefik | grep techstart.byrne-accounts.org
```

**Wait for**: "Server responded with a certificate"

---

## Best Practices

### 1. Standard Naming Convention

Use consistent subdomains:
- Company name as subdomain
- Remove spaces/special characters
- Use hyphens for multi-word names

```bash
# Good
TechStart Inc → techstart
ACME Corporation → acme
Jane's Bakery → janes-bakery

# Bad
TechStart Inc → tech_start
ACME Corporation → ACME
Jane's Bakery → jane's
```

### 2. Secure Credential Storage

```bash
# Credentials are automatically saved with restrictive permissions
ls -la client-credentials/
# -rw------- (read/write for owner only)

# Back up credentials securely
tar -czf client-creds-backup-$(date +%Y%m%d).tar.gz client-credentials/
# Encrypt the backup
gpg -c client-creds-backup-*.tar.gz
# Delete unencrypted tar
rm client-creds-backup-*.tar.gz
```

### 3. Client Onboarding Email Template

```
Subject: Welcome to Your New Business Management System!

Dear [Client Name],

Your complete business management system is now ready!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ACCESS YOUR PORTAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Visit: https://byrne-accounts.org/portal.html
Select: "[Client Name]" from dropdown

You'll see three services:

1. 💼 ERP SYSTEM - Complete business management
   URL: https://[subdomain].byrne-accounts.org
   Username: Administrator
   Password: [password]

2. 🛒 POINT OF SALE - Modern POS system
   URL: https://[subdomain].byrne-accounts.org/pos
   (Same login as ERP)

3. 📧 EMAIL - Professional email with calendar
   Webmail: https://mail.securenexus.net
   Email: [email]@[domain]
   Password: [password]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
YOUR EMAIL ADDRESSES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You have ONE inbox that receives emails from all these addresses:

• [email]@[domain]
• support@[domain]
• info@[domain]
• financial@[domain]
• sales@[domain]
• accounts@[domain]

Just check one inbox - all emails come there!
You can reply FROM any of these addresses.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Login to your portal
2. Complete the ERPNext setup wizard
3. Add your products/services
4. Set up your team members
5. Start using your POS

Need help? Contact us:
• Email: support@byrne-accounts.org
• Portal: https://byrne-accounts.org

Welcome aboard!

Best regards,
Byrne Accounting Team
```

---

## Quick Reference

### Provision New Client
```bash
./scripts/provision-client-complete.sh --name "Client Name" --subdomain "clientname"
```

### View Client Credentials
```bash
cat client-credentials/[subdomain].byrne-accounts.org.txt
```

### List All Clients
```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && ls -1 sites/ | grep '\.'"
```

### Manual Email Setup (No API Key)
```bash
# Login to Mailcow: https://mail.securenexus.net
# Configuration → Mailboxes → Add
# Then add aliases manually
```

---

## Summary

✅ **ONE command** creates complete client system
✅ **THREE services**: ERP + POS + Email
✅ **MULTIPLE email addresses** → ONE inbox
✅ **PROFESSIONAL appearance** (support@, info@, etc.)
✅ **5-MINUTE setup** (mostly automated)
✅ **SECURE credentials** (auto-generated, stored safely)

**Ready to scale to hundreds of clients!** 🚀

---

*Last Updated: October 28, 2025*
*Version: 1.0*
