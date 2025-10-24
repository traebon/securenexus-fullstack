# ERPNext + Mailcow Email Integration Guide

## Overview

This guide shows how to integrate Mailcow email service with your ERPNext sites (both your own and client sites). Each ERPNext site can have its own email domain and accounts.

---

## 🎯 Current Setup

**Mailcow Server**: `mail.securenexus.net`
- **Admin UI**: https://mail.securenexus.net:8443 or http://mail.securenexus.net:8880
- **SMTP Ports**: 25 (public), 587 (STARTTLS), 465 (SSL)
- **IMAP Ports**: 143 (STARTTLS), 993 (SSL)
- **POP3 Ports**: 110 (STARTTLS), 995 (SSL)

**ERPNext Sites**:
- `erp.byrne-accounts.org` - Your companies
- `dickinson.byrne-accounts.org` - Client site
- Future client sites...

---

## 📋 Integration Strategy

### Option 1: Separate Email Domain Per Client (Recommended)
- **Your site**: `erp@byrne-accounts.org`
- **Dickinson**: `admin@dickinson.byrne-accounts.org` or `noreply@dickinson.byrne-accounts.org`
- **Pros**: Complete isolation, professional appearance
- **Cons**: Requires DNS setup per domain

### Option 2: Shared Domain with Different Mailboxes
- **Your site**: `byrne@securenexus.net`
- **Dickinson**: `dickinson@securenexus.net`
- **Pros**: Simple DNS, all under one domain
- **Cons**: Less professional for clients

**Recommendation**: Start with Option 2 for testing, move to Option 1 for production clients.

---

## 🚀 Quick Setup (Option 2 - Shared Domain)

### Step 1: Access Mailcow Admin UI

1. Open browser and navigate to:
   ```
   https://mail.securenexus.net:8443
   ```

2. Login with Mailcow admin credentials
   - Default username: `admin`
   - Password: Check `/home/tristian/securenexus-fullstack/mail/mailcow-dockerized/mailcow.conf` for `MAILCOW_ADMIN_PASS`

3. If you don't know the admin password:
   ```bash
   cd /home/tristian/securenexus-fullstack/mail/mailcow-dockerized
   grep "^MAILCOW_ADMIN_PASS" mailcow.conf
   ```

### Step 2: Create Email Account for Dickinson Site

In Mailcow Admin UI:

1. **Go to**: Configuration → Email → Mailboxes
2. **Click**: "+ Add mailbox"
3. **Fill in**:
   ```
   Domain: securenexus.net
   Local part: dickinson-erp
   Name: Dickinson ERP System
   Password: [Generate strong password]
   Quota: 1024 MB (or as needed)
   ```
4. **Save**

**Result**: Email account `dickinson-erp@securenexus.net` created

5. **Save the credentials**:
   ```bash
   mkdir -p /home/tristian/securenexus-fullstack/mail-credentials
   cat > /home/tristian/securenexus-fullstack/mail-credentials/dickinson.txt <<EOF
   Email: dickinson-erp@securenexus.net
   Password: YOUR_GENERATED_PASSWORD
   SMTP Server: mail.securenexus.net
   SMTP Port: 587 (STARTTLS) or 465 (SSL)
   IMAP Server: mail.securenexus.net
   IMAP Port: 993 (SSL)
   EOF
   chmod 600 /home/tristian/securenexus-fullstack/mail-credentials/dickinson.txt
   ```

### Step 3: Configure ERPNext Email Settings

#### A. Access Dickinson ERPNext Site

1. Login to: https://dickinson.byrne-accounts.org
2. Username: `Administrator`
3. Password: From `client-credentials/dickinson.byrne-accounts.org.txt`

#### B. Configure Email Domain

1. **Search for**: "Email Domain" (Ctrl+K or use search bar)
2. **Click**: "+ New"
3. **Fill in**:
   ```
   Domain Name: securenexus.net
   Email ID: dickinson-erp@securenexus.net
   Email Server: mail.securenexus.net
   Use IMAP: ☑ Checked
   Use TLS: ☑ Checked
   Use SSL: ☐ Unchecked (for IMAP 993, check this and uncheck TLS)
   Attachment Limit: 10 (MB)
   SMTP Server: mail.securenexus.net
   Port: 587
   Use TLS for Outgoing: ☑ Checked
   ```
4. **Authentication Settings**:
   ```
   Login Id: dickinson-erp@securenexus.net
   Password: YOUR_GENERATED_PASSWORD
   ```
5. **Save**

#### C. Set Default Email Account

1. **Search for**: "Email Account" (Ctrl+K)
2. **Click**: "+ New"
3. **Fill in**:
   ```
   Email Account Name: Dickinson ERP Default
   Email ID: dickinson-erp@securenexus.net
   Domain: securenexus.net (select from dropdown)
   Default Outgoing: ☑ Checked
   Default Incoming: ☑ Checked
   ```
4. **SMTP Settings**:
   ```
   SMTP Server: mail.securenexus.net
   Use TLS: ☑ Checked
   Port: 587
   Login Id: dickinson-erp@securenexus.net
   Password: YOUR_GENERATED_PASSWORD
   ```
5. **IMAP Settings**:
   ```
   Email Server: mail.securenexus.net
   Use IMAP: ☑ Checked
   Use SSL: ☑ Checked (for port 993)
   Port: 993
   ```
6. **Save**

#### D. Test Email Configuration

1. In the Email Account form, scroll down
2. Click **"Send Test Email"** button
3. Enter a test recipient email
4. Check if email is received

---

## 🔧 Advanced Setup (Option 1 - Separate Domain Per Client)

### Prerequisites

You need to:
1. Own or control the client's domain (e.g., `dickinson.byrne-accounts.org`)
2. Be able to add MX and other DNS records

### Step 1: Add Domain to Mailcow

In Mailcow Admin UI:

1. **Go to**: Configuration → Email → Domains
2. **Click**: "+ Add domain"
3. **Fill in**:
   ```
   Domain: dickinson.byrne-accounts.org
   Description: Dickinson Client Email
   Mailboxes: 10 (or as needed)
   Quota: 10240 MB (10GB total for domain)
   ```
4. **Save**

### Step 2: Configure DNS Records

You need to add these DNS records to `byrne-accounts.org` zone:

#### Add to: `/home/tristian/securenexus-fullstack/dns/zones/byrne-accounts.org.zone`

```dns
; Mail records for dickinson subdomain
dickinson.byrne-accounts.org. IN MX 10 mail.securenexus.net.

; SPF record (authorize securenexus mail server to send for dickinson)
dickinson.byrne-accounts.org. IN TXT "v=spf1 mx a:mail.securenexus.net ~all"

; DMARC policy
_dmarc.dickinson.byrne-accounts.org. IN TXT "v=DMARC1; p=quarantine; rua=mailto:admin@securenexus.net"

; DKIM (will be generated by Mailcow - see below)
; dkim._domainkey.dickinson.byrne-accounts.org. IN TXT "v=DKIM1;k=rsa;..."
```

**After adding, increment the serial number and reload**:

```bash
# Edit zone file
nano /home/tristian/securenexus-fullstack/dns/zones/byrne-accounts.org.zone

# Change serial from 2025101101 to 2025102401 (today's date + 01)

# Reload CoreDNS
docker compose restart coredns
```

#### Get DKIM Key from Mailcow

1. In Mailcow UI: Configuration → Email → Domains
2. Click on `dickinson.byrne-accounts.org`
3. Click "DKIM" tab
4. Copy the DKIM public key
5. Add it to your DNS zone file as shown above

### Step 3: Create Mailbox for Dickinson Domain

1. **Go to**: Configuration → Email → Mailboxes
2. **Click**: "+ Add mailbox"
3. **Fill in**:
   ```
   Domain: dickinson.byrne-accounts.org
   Local part: admin (or noreply, erp, etc.)
   Name: Dickinson Admin
   Password: [Strong password]
   Quota: 2048 MB
   ```
4. **Save**

**Result**: Email account `admin@dickinson.byrne-accounts.org` created

### Step 4: Configure ERPNext with New Domain

Follow **Step 3** from Quick Setup above, but use:
- Email: `admin@dickinson.byrne-accounts.org`
- Domain: `dickinson.byrne-accounts.org`

---

## 📧 ERPNext Email Features to Configure

Once email is set up, configure these ERPNext features:

### 1. Email Notifications

**Go to**: Settings → Email Settings

Enable:
- ☑ Send Notifications
- ☑ Send Print in Email
- ☑ Email Footer (add company branding)

### 2. Email Templates

**Go to**: Settings → Email Template

Create templates for:
- Invoice emails
- Payment receipts
- POS receipts
- Order confirmations
- Quotations

### 3. Auto-Email Reports

**Go to**: Home → Reports → Auto Email Report

Schedule automatic reports:
- Daily sales summary
- Weekly inventory report
- Monthly financial statements

### 4. Email Alerts

**Go to**: Settings → Email Alert

Set up alerts for:
- Low stock notifications
- High-value transactions
- Failed payments
- System errors

### 5. Communication Tracking

ERPNext automatically tracks all emails sent/received:
- **View**: Each document has a "Comments/Activity" section
- **See all**: Home → Email → Communication

---

## 🔍 Troubleshooting

### Email Not Sending

1. **Check SMTP credentials**:
   ```bash
   docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
     bench --site dickinson.byrne-accounts.org console" <<EOF
   frappe.get_doc("Email Account", "Dickinson ERP Default").get_password()
   exit()
   EOF
   ```

2. **Test SMTP manually**:
   ```bash
   # Install swaks if needed
   apt-get install swaks

   # Test SMTP
   swaks --to test@example.com \
     --from dickinson-erp@securenexus.net \
     --server mail.securenexus.net:587 \
     --tls \
     --auth LOGIN \
     --auth-user dickinson-erp@securenexus.net \
     --auth-password "YOUR_PASSWORD"
   ```

3. **Check ERPNext error log**:
   - In ERPNext: Tools → Error Log
   - Search for "email" or "smtp"

4. **Check Mailcow logs**:
   ```bash
   cd /home/tristian/securenexus-fullstack/mail/mailcow-dockerized
   docker compose logs postfix-mailcow | grep dickinson | tail -50
   ```

### Email Not Receiving (IMAP)

1. **Verify IMAP credentials** in ERPNext Email Account

2. **Test IMAP connection**:
   ```bash
   # Install openssl if needed
   openssl s_client -connect mail.securenexus.net:993 -crlf
   # Then type:
   # a1 LOGIN dickinson-erp@securenexus.net YOUR_PASSWORD
   # a2 LIST "" "*"
   # a3 LOGOUT
   ```

3. **Check Mailcow Dovecot logs**:
   ```bash
   cd /home/tristian/securenexus-fullstack/mail/mailcow-dockerized
   docker compose logs dovecot-mailcow | grep dickinson | tail -50
   ```

### Authentication Failed

1. **Verify password** in Mailcow admin UI:
   - Configuration → Email → Mailboxes
   - Find the mailbox
   - Reset password if needed

2. **Check for special characters**:
   - Some passwords with special characters may need escaping
   - Try a simpler password for testing

### DNS Issues (for separate domains)

1. **Verify MX record**:
   ```bash
   dig MX dickinson.byrne-accounts.org +short
   # Should return: 10 mail.securenexus.net.
   ```

2. **Verify SPF record**:
   ```bash
   dig TXT dickinson.byrne-accounts.org +short
   # Should include: "v=spf1 mx a:mail.securenexus.net ~all"
   ```

3. **Test email deliverability**:
   - Send test email to: https://www.mail-tester.com
   - Check spam score and DNS configuration

---

## 📊 Email Monitoring

### Mailcow Queue Management

1. **View queue**: Configuration → Queue Manager
2. **Check logs**: Logs → Postfix
3. **Rspamd stats**: Rspamd UI (linked from main page)

### ERPNext Email Status

1. **Sent emails**: Home → Email → Communication
2. **Failed emails**: Tools → Error Log (filter: "email")
3. **Email Queue**: Home → Email → Email Queue

---

## 🔐 Security Best Practices

### 1. Use Strong Passwords
- Generate passwords: `openssl rand -base64 32`
- Store in password manager

### 2. Enable Two-Factor Auth (Mailcow)
- Admin Settings → Two-Factor Authentication
- Enable for all admin accounts

### 3. Rate Limiting
- Already configured in Mailcow
- Prevents abuse and spam

### 4. SPF, DKIM, DMARC
- Essential for email deliverability
- Follow DNS setup in "Advanced Setup" section

### 5. Regular Backups
- Mailcow data is in `/home/tristian/securenexus-fullstack/mail/mailcow-dockerized/data`
- Backup with your regular backup script
- Or use Mailcow's built-in backup: `./helper-scripts/backup_and_restore.sh backup all`

---

## 📝 Email Account Naming Convention

### For Your Sites (byrne-accounts.org)
- `erp@byrne-accounts.org` - Main ERP notifications
- `pos@byrne-accounts.org` - POS receipts
- `noreply@byrne-accounts.org` - Automated emails
- `support@byrne-accounts.org` - Customer support

### For Client Sites
**Option A: Shared domain**
- `clientname-erp@securenexus.net`
- `clientname-pos@securenexus.net`

**Option B: Separate domain**
- `erp@clientdomain.com`
- `noreply@clientdomain.com`

---

## 🎯 Quick Reference

### SMTP Settings (for ERPNext)
```
Server: mail.securenexus.net
Port: 587
Security: STARTTLS
Auth: Required
Username: your-email@domain.com
Password: your-password
```

### IMAP Settings (for ERPNext)
```
Server: mail.securenexus.net
Port: 993
Security: SSL
Auth: Required
Username: your-email@domain.com
Password: your-password
```

### Mailcow Admin UI
```
URL: https://mail.securenexus.net:8443
Username: admin
Password: [See mailcow.conf]
```

### Get Mailcow Admin Password
```bash
cd /home/tristian/securenexus-fullstack/mail/mailcow-dockerized
grep "^MAILCOW_ADMIN_PASS" mailcow.conf
```

---

## 🚀 Next Steps

1. ✅ Access Mailcow admin UI
2. ✅ Create email account for dickinson site
3. ✅ Configure Email Domain in ERPNext
4. ✅ Configure Email Account in ERPNext
5. ✅ Test sending email
6. ✅ Test receiving email
7. ✅ Set up email templates
8. ✅ Configure notifications

---

## 📚 Additional Resources

- **Mailcow Docs**: https://docs.mailcow.email/
- **ERPNext Email Setup**: https://docs.erpnext.com/docs/user/manual/en/setting-up/email
- **Email Deliverability**: https://www.mail-tester.com
- **DMARC Analyzer**: https://dmarcian.com/dmarc-inspector/

---

**Ready to set up email for dickinson.byrne-accounts.org!** 🎉
