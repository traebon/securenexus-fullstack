# Client Email Setup Guide

## Complete 3-Component Client System

Each Byrne Accounts client gets access to **THREE core services**:

1. ✅ **ERPNext** - Business management (accounting, inventory, CRM, HR)
2. ✅ **POS Awesome** - Point of sale system
3. ✅ **Webmail** - Professional email with calendar and contacts

---

## Email Architecture

### Mailcow System
- **Central Mail Server**: `mail.securenexus.net`
- **Webmail Interface**: SOGo (included with Mailcow)
- **Features**: SMTP, IMAP, POP3, Calendar, Contacts, Mobile Sync
- **Security**: Spam filtering (Rspamd), Antivirus (ClamAV), DKIM, SPF, DMARC

### Per-Client Email Options

#### Option 1: Shared Domain (Recommended for PoC)
All clients use `@byrne-accounts.org` with unique addresses:
- `demo@byrne-accounts.org`
- `dickinson@byrne-accounts.org`
- `acme@byrne-accounts.org`

**Pros**:
- Quick setup
- One domain to manage
- Professional appearance

**Cons**:
- Clients don't have "their own" domain

#### Option 2: Custom Client Domains
Each client can have their own domain:
- `admin@demo-client.com`
- `info@dickinson-supplies.com`
- `contact@acmecorp.com`

**Pros**:
- Clients have their own branded email
- More professional for client businesses

**Cons**:
- Requires DNS configuration per client
- More setup time

---

## Setting Up Email for Demo Client

### Step 1: Access Mailcow Admin

```bash
# URL
https://mail.securenexus.net

# Admin Credentials (check your setup)
Username: admin
Password: [stored in secrets or Mailcow config]
```

### Step 2: Create Mailbox for Demo Client

1. **Login to Mailcow**
   - Navigate to: `https://mail.securenexus.net`
   - Login as admin

2. **Go to Mailboxes**
   - Click "Configuration" → "Mail Setup" → "Mailboxes"
   - Click "+ Add mailbox"

3. **Create Demo Client Mailbox**
   ```
   Username: demo
   Domain: byrne-accounts.org
   Full Email: demo@byrne-accounts.org
   Name: Demo Client
   Password: DemoMail2025!
   Quota: 5GB (or unlimited)
   ```

4. **Save**

### Step 3: Test Email Access

**Via Webmail (SOGo)**:
```
URL: https://mail.securenexus.net/SOGo
Username: demo@byrne-accounts.org
Password: DemoMail2025!
```

**Via Email Client (Outlook, Thunderbird, etc.)**:
```
IMAP Settings:
  Server: mail.securenexus.net
  Port: 993 (SSL/TLS)
  Username: demo@byrne-accounts.org
  Password: DemoMail2025!

SMTP Settings:
  Server: mail.securenexus.net
  Port: 587 (STARTTLS) or 465 (SSL/TLS)
  Username: demo@byrne-accounts.org
  Password: DemoMail2025!
```

---

## Adding Email to Client Portal

### Updated Portal Flow

When user selects "Demo Client" from portal:

1. **ERP Card** → `https://demo.byrne-accounts.org`
   - Login: Administrator / DemoClient2025!

2. **POS Card** → `https://demo.byrne-accounts.org/pos`
   - Login: Administrator / DemoClient2025!

3. **Webmail Card** → `https://mail.securenexus.net`
   - Login: demo@byrne-accounts.org / DemoMail2025!

**Portal URL**: `https://byrne-accounts.org/portal.html`

---

## Setting Up Custom Domain Email (Advanced)

If client wants `@demo-client.com` instead of `@byrne-accounts.org`:

### Step 1: Add Domain to Mailcow

1. **Login to Mailcow Admin**
2. **Go to Domains**
   - Configuration → Mail Setup → Domains
   - Click "+ Add domain"

3. **Add Client Domain**
   ```
   Domain: demo-client.com
   Description: Demo Client Email
   Max mailboxes: 10 (or unlimited)
   Max quota: 50GB (adjust as needed)
   ```

4. **Save**

### Step 2: Configure DNS Records

Add these DNS records to `demo-client.com`:

```dns
; MX Record (mail routing)
demo-client.com.  IN MX 10 mail.securenexus.net.

; SPF Record (sender authentication)
demo-client.com.  IN TXT "v=spf1 mx a:mail.securenexus.net ~all"

; DMARC Record (email security)
_dmarc.demo-client.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:postmaster@demo-client.com"

; DKIM Record (get from Mailcow)
; Configuration → ARC/DKIM Keys → demo-client.com → Copy public key
dkim._domainkey.demo-client.com. IN TXT "v=DKIM1; k=rsa; p=PUBLIC_KEY_HERE"
```

### Step 3: Create Mailbox on New Domain

```
Username: admin (or any username)
Domain: demo-client.com
Full Email: admin@demo-client.com
Password: SecurePass123!
```

### Step 4: Verify DNS Propagation

```bash
# Check MX record
dig MX demo-client.com

# Check SPF record
dig TXT demo-client.com

# Check DMARC record
dig TXT _dmarc.demo-client.com
```

Allow 1-24 hours for DNS propagation.

---

## Email Features for Clients

### SOGo Webmail Features

- ✅ **Email**: Full inbox, sent, drafts, trash
- ✅ **Calendar**: Shared calendars, meeting invitations
- ✅ **Contacts**: Address book with import/export
- ✅ **Tasks**: To-do lists integrated with calendar
- ✅ **Mobile Sync**: ActiveSync support (iOS, Android)
- ✅ **Filters**: Server-side rules and filters
- ✅ **Out of Office**: Auto-reply configuration

### Mobile Device Setup

**iOS (iPhone/iPad)**:
1. Settings → Mail → Accounts → Add Account
2. Select "Microsoft Exchange" (for ActiveSync)
3. Enter:
   - Email: demo@byrne-accounts.org
   - Server: mail.securenexus.net
   - Username: demo@byrne-accounts.org
   - Password: DemoMail2025!

**Android**:
1. Settings → Accounts → Add Account → Corporate
2. Enter email and password
3. Exchange server: mail.securenexus.net
4. Complete setup

---

## Bulk Client Email Setup

### For Multiple Clients

Create a script to automate mailbox creation:

```bash
#!/bin/bash
# File: scripts/create-client-email.sh

CLIENT_NAME="$1"
CLIENT_EMAIL="$2"
CLIENT_PASSWORD="$3"

# Mailcow API endpoint
MAILCOW_API="https://mail.securenexus.net/api/v1"
API_KEY="your-mailcow-api-key"

# Create mailbox via API
curl -X POST "${MAILCOW_API}/add/mailbox" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"local_part\": \"${CLIENT_EMAIL%@*}\",
    \"domain\": \"${CLIENT_EMAIL#*@}\",
    \"name\": \"${CLIENT_NAME}\",
    \"password\": \"${CLIENT_PASSWORD}\",
    \"password2\": \"${CLIENT_PASSWORD}\",
    \"quota\": \"5120\",
    \"active\": \"1\"
  }"

echo "✅ Email created: ${CLIENT_EMAIL}"
echo "Password: ${CLIENT_PASSWORD}"
```

**Usage**:
```bash
./scripts/create-client-email.sh "Demo Client" "demo@byrne-accounts.org" "DemoMail2025!"
./scripts/create-client-email.sh "Dickinson Supplies" "dickinson@byrne-accounts.org" "DickinsonMail2025!"
```

---

## Client Credential Template

For each client, store in `/client-credentials/{clientname}.byrne-accounts.org.txt`:

```
=== Demo Client Access ===

ERP System:
  URL: https://demo.byrne-accounts.org
  Username: Administrator
  Password: DemoClient2025!

POS System:
  URL: https://demo.byrne-accounts.org/pos
  Username: Administrator
  Password: DemoClient2025!

Email (Webmail):
  URL: https://mail.securenexus.net
  Email: demo@byrne-accounts.org
  Password: DemoMail2025!

Email (IMAP/SMTP):
  IMAP: mail.securenexus.net:993 (SSL)
  SMTP: mail.securenexus.net:587 (STARTTLS)
  Username: demo@byrne-accounts.org
  Password: DemoMail2025!

Portal Access:
  URL: https://byrne-accounts.org/portal.html
  Select: "Demo Client" from dropdown

Created: [Date]
```

---

## Email Integration with ERPNext

### Link Email to ERPNext Account

ERPNext can send/receive emails through Mailcow:

1. **Login to ERPNext** (demo.byrne-accounts.org)

2. **Setup Email Domain**
   - Search: "Email Domain"
   - New Email Domain
   - Domain Name: byrne-accounts.org
   - SMTP Server: mail.securenexus.net
   - SMTP Port: 587
   - Use TLS: Yes

3. **Setup Email Account**
   - Search: "Email Account"
   - New Email Account
   - Email Address: demo@byrne-accounts.org
   - Email ID: demo@byrne-accounts.org
   - Password: DemoMail2025!
   - IMAP Settings:
     - Server: mail.securenexus.net
     - Port: 993
     - Use SSL: Yes
   - SMTP Settings:
     - Server: mail.securenexus.net
     - Port: 587
     - Use TLS: Yes

4. **Test**
   - Send test email from ERPNext
   - Check inbox in webmail

**Benefits**:
- Send invoices via email directly from ERPNext
- Track email conversations with customers
- Receive inquiries in ERPNext inbox
- Automated email notifications

---

## Troubleshooting Email

### Issue: Cannot Login to Webmail

**Check**:
```bash
# Verify mailbox exists
docker exec mailcowdockerized-postfix-mailcow-1 doveadm user demo@byrne-accounts.org

# Check Mailcow logs
cd mail/mailcow-dockerized
docker compose logs sogo-mailcow
```

**Solution**:
- Reset password in Mailcow admin panel
- Check username format (must be full email address)

### Issue: Cannot Send Email

**Check DNS Records**:
```bash
dig MX byrne-accounts.org
dig TXT byrne-accounts.org  # Check SPF
```

**Check Mailcow Logs**:
```bash
cd mail/mailcow-dockerized
docker compose logs postfix-mailcow | tail -50
```

**Common Fixes**:
- Verify SMTP settings (port 587, STARTTLS)
- Check SPF/DKIM records
- Verify sender domain matches email domain

### Issue: Email Goes to Spam

**Setup DKIM**:
1. Mailcow Admin → Configuration → ARC/DKIM Keys
2. Select domain → Generate DKIM key
3. Add DNS TXT record with public key

**Verify Email Authentication**:
```bash
# Send test email to: check-auth@verifier.port25.com
# Reply will show SPF, DKIM, DMARC results
```

---

## Client Email Checklist

For each new client:

- [ ] Create mailbox in Mailcow
- [ ] Test webmail login
- [ ] Save credentials securely
- [ ] Add email card to portal (if custom)
- [ ] Configure mobile devices
- [ ] Setup SPF/DKIM/DMARC (if custom domain)
- [ ] Link email to ERPNext account
- [ ] Send welcome email with instructions
- [ ] Document credentials in `/client-credentials/`

---

## Quick Reference

### Demo Client Email

```
Webmail URL: https://mail.securenexus.net
Email: demo@byrne-accounts.org
Password: DemoMail2025!

IMAP: mail.securenexus.net:993 (SSL)
SMTP: mail.securenexus.net:587 (STARTTLS)
```

### Mailcow Admin

```
URL: https://mail.securenexus.net
Username: admin
Password: [check Mailcow setup docs]
```

---

## Next Steps

1. **Create demo client mailbox** in Mailcow
2. **Test 3-component access**:
   - Portal → Select Demo Client
   - Click ERP → Login to ERPNext
   - Click POS → Access point of sale
   - Click Webmail → Login to SOGo
3. **Document credentials**
4. **Show client the complete system**

---

## Summary

✅ Each client now gets **3 integrated services**:
1. **ERPNext** - Full business management
2. **POS Awesome** - Modern point of sale
3. **Webmail** - Professional email with calendar

All accessible through the **Client Portal** at:
`https://byrne-accounts.org/portal.html`

---

*Last Updated: October 28, 2025*
*Version: 1.0*
