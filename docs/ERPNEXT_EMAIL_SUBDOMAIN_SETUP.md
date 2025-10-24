# ERPNext Email Setup - Subdomain Approach

## 🎯 Strategy

Each client gets their own subdomain for email:
- **Dickinson**: `admin@dickinson.byrne-accounts.org`
- **Client2**: `admin@client2.byrne-accounts.org`
- **Your site**: `admin@erp.byrne-accounts.org`

This provides:
- ✅ Professional appearance
- ✅ Complete email isolation per client
- ✅ Easy to track who's sending what
- ✅ Can upgrade to client's own domain later
- ✅ All under your control (byrne-accounts.org)

---

## 🚀 Setup for Dickinson Site

### Step 1: Add Domain to Mailcow

1. **Access Mailcow UI**: https://mail.securenexus.net:8443

2. **Login** as admin

3. **Go to**: Configuration → Email → Domains

4. **Click**: "+ Add domain"

5. **Fill in**:
   ```
   Domain: dickinson.byrne-accounts.org
   Description: Dickinson Client Email
   Max. number of mailboxes: 10
   Max. quota for domain (MiB): 10240 (10GB)
   Max. quota per mailbox (MiB): 2048 (2GB)
   Default mailbox quota (MiB): 1024 (1GB)
   ```

6. **Advanced Settings** (optional):
   - Relay all recipients: No
   - Relay all users: No
   - Backup MX: No

7. **Click**: "Add domain and restart SOGo"

8. **Wait**: ~30 seconds for services to restart

---

### Step 2: Get DKIM Key from Mailcow

After adding the domain:

1. **Stay on**: Configuration → Email → Domains

2. **Find**: dickinson.byrne-accounts.org in the list

3. **Click**: "DKIM" button (or Configuration tab)

4. **Copy the DKIM public key** - it looks like:
   ```
   v=DKIM1;k=rsa;t=s;s=email;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
   ```

5. **Keep this open** - you'll need it for DNS

---

### Step 3: Configure DNS Records

Edit your DNS zone file:

```bash
nano /home/tristian/securenexus-fullstack/dns/zones/byrne-accounts.org.zone
```

**Add these records** (after line 23, before the final blank line):

```dns
; ================================================
; Email records for dickinson subdomain
; ================================================

; MX record - directs email to mail.securenexus.net
dickinson.byrne-accounts.org. IN MX 10 mail.securenexus.net.

; SPF record - authorizes mail.securenexus.net to send
dickinson.byrne-accounts.org. IN TXT "v=spf1 mx a:mail.securenexus.net ~all"

; DMARC policy - quarantine suspicious emails
_dmarc.dickinson.byrne-accounts.org. IN TXT "v=DMARC1; p=quarantine; rua=mailto:admin@securenexus.net; pct=100"

; DKIM key - paste the value from Mailcow (Step 2)
dkim._domainkey.dickinson.byrne-accounts.org. IN TXT "v=DKIM1;k=rsa;t=s;s=email;p=PASTE_YOUR_DKIM_KEY_HERE"
```

**Important**: Replace `PASTE_YOUR_DKIM_KEY_HERE` with the actual DKIM public key from Step 2.

---

### Step 4: Update Serial and Reload DNS

1. **Update serial number** in the zone file:
   ```dns
   ; Change from:
   2025101101 ; serial

   ; To (today's date + increment):
   2025102401 ; serial
   ```

2. **Save the file** (Ctrl+X, Y, Enter)

3. **Reload CoreDNS**:
   ```bash
   docker compose restart coredns
   ```

4. **Verify DNS propagation**:
   ```bash
   # Test MX record
   dig MX dickinson.byrne-accounts.org @localhost +short
   # Should return: 10 mail.securenexus.net.

   # Test SPF record
   dig TXT dickinson.byrne-accounts.org @localhost +short
   # Should return: "v=spf1 mx a:mail.securenexus.net ~all"

   # Test DKIM record
   dig TXT dkim._domainkey.dickinson.byrne-accounts.org @localhost +short
   # Should return: "v=DKIM1;k=rsa;..."
   ```

---

### Step 5: Create Email Accounts in Mailcow

Now create the actual mailboxes:

#### Account 1: Admin Account

1. **In Mailcow UI**: Configuration → Email → Mailboxes

2. **Click**: "+ Add mailbox"

3. **Fill in**:
   ```
   Domain: dickinson.byrne-accounts.org (select from dropdown)
   Username (local part): admin
   Name: Dickinson Administrator
   Password: [Generate strong password - save it!]
   Quota (MiB): 2048
   Send only: No
   ```

4. **Advanced** (leave defaults):
   - Enable IMAP: Yes
   - Enable POP3: Yes
   - Enable SMTP: Yes

5. **Click**: "Add"

**Result**: `admin@dickinson.byrne-accounts.org` created ✅

#### Account 2: No-Reply Account

1. **Click**: "+ Add mailbox" again

2. **Fill in**:
   ```
   Domain: dickinson.byrne-accounts.org
   Username (local part): noreply
   Name: Dickinson No-Reply
   Password: [Generate strong password]
   Quota (MiB): 1024
   Send only: Yes (check this - for outgoing only)
   ```

3. **Click**: "Add"

**Result**: `noreply@dickinson.byrne-accounts.org` created ✅

---

### Step 6: Save Email Credentials

```bash
cat > /home/tristian/securenexus-fullstack/mail-credentials/dickinson-byrne-accounts-org.txt <<'EOF'
=====================================
Dickinson Email Accounts
=====================================

ADMIN ACCOUNT (for system notifications):
Email: admin@dickinson.byrne-accounts.org
Password: YOUR_ADMIN_PASSWORD
SMTP: mail.securenexus.net:587 (STARTTLS)
IMAP: mail.securenexus.net:993 (SSL)
Purpose: System emails, alerts, two-way communication

NO-REPLY ACCOUNT (for automated emails):
Email: noreply@dickinson.byrne-accounts.org
Password: YOUR_NOREPLY_PASSWORD
SMTP: mail.securenexus.net:587 (STARTTLS)
Purpose: Invoices, receipts, automated notifications

=====================================
Created: $(date)
Domain: dickinson.byrne-accounts.org
Mailcow: https://mail.securenexus.net:8443
=====================================
EOF

chmod 600 /home/tristian/securenexus-fullstack/mail-credentials/dickinson-byrne-accounts-org.txt
```

---

### Step 7: Configure ERPNext Email Account

#### Login to Dickinson ERPNext

1. **URL**: https://dickinson.byrne-accounts.org
2. **User**: `sysadmin@byrne-accounts.org` (your super-admin account)
3. **Password**: Your super-admin password

#### Create Email Account

1. **Search**: "Email Account" (Ctrl+K)

2. **Click**: "+ New"

3. **Fill in**:

   ```
   ===== BASIC INFO =====
   Email Account Name: Dickinson Default
   Email ID: admin@dickinson.byrne-accounts.org

   ☑ Default Outgoing
   ☑ Default Incoming
   ☑ Enable Incoming
   ☑ Enable Outgoing

   ===== OUTGOING (SMTP) =====
   SMTP Server: mail.securenexus.net
   ☑ Use TLS
   ☐ Use SSL (leave unchecked for port 587)
   Port: 587
   Login Id: admin@dickinson.byrne-accounts.org
   Password: [Your admin password from Step 6]

   ===== INCOMING (IMAP) =====
   Email Server: mail.securenexus.net
   ☑ Use IMAP
   ☑ Use SSL (checked for port 993)
   ☐ Use TLS (leave unchecked when SSL is checked)
   Port: 993

   ===== ADDITIONAL SETTINGS =====
   Append To: Communication
   Enable Auto Reply: No (unless needed)
   Signature: [Optional company signature]
   ```

4. **Save**

5. **Scroll down** and click: **"Send Test Email"**

6. **Enter test email** and click "Send"

7. **Check**: You should receive the test email ✅

---

### Step 8: Create No-Reply Email Account (Optional)

For automated notifications that don't need replies:

1. **Search**: "Email Account" (Ctrl+K)

2. **Click**: "+ New"

3. **Fill in**:
   ```
   Email Account Name: Dickinson No-Reply
   Email ID: noreply@dickinson.byrne-accounts.org

   ☐ Default Outgoing (unchecked)
   ☐ Default Incoming (unchecked)
   ☐ Enable Incoming (unchecked - send only)
   ☑ Enable Outgoing

   ===== OUTGOING (SMTP) =====
   SMTP Server: mail.securenexus.net
   ☑ Use TLS
   Port: 587
   Login Id: noreply@dickinson.byrne-accounts.org
   Password: [Your noreply password from Step 6]
   ```

4. **Save**

**Use this for**: Automated invoices, POS receipts, system notifications where replies aren't needed.

---

## 🔧 Configure Email for Specific Features

### 1. Set Default Email for POS Receipts

1. **Search**: "POS Profile"

2. **Open**: Your POS profile

3. **Set**:
   ```
   Email Account: Dickinson No-Reply (or Default)
   ```

4. **Save**

### 2. Configure Invoice Email Template

1. **Search**: "Email Template"

2. **Find**: "Sales Invoice"

3. **Customize** template with client branding

4. **Set**: From address = noreply@dickinson.byrne-accounts.org

### 3. Enable Automated Reports

1. **Search**: "Auto Email Report"

2. **Create**: Daily/weekly reports

3. **From Email**: Use admin@dickinson.byrne-accounts.org

---

## ✅ Testing Checklist

### Test 1: Send Email from ERPNext

1. Create a test Sales Invoice
2. Click "Email" button
3. Send to your personal email
4. **Check**:
   - [ ] Email received
   - [ ] From address shows: admin@dickinson.byrne-accounts.org
   - [ ] Not marked as spam

### Test 2: Receive Email in ERPNext

1. Send email TO: admin@dickinson.byrne-accounts.org
2. Wait 5 minutes
3. In ERPNext: Home → Email → Communication
4. **Check**:
   - [ ] Email appears in Communications
   - [ ] Can read content

### Test 3: Email Deliverability

Send test email to: check@mail-tester.com

**Check score**:
- 8-10/10 = Excellent ✅
- 6-7/10 = Good (needs improvement)
- Below 6/10 = Check DNS records

---

## 🔄 Repeat for Other Clients

For each new client site, repeat this process:

```bash
# Example for client2

# 1. In Mailcow: Add domain "client2.byrne-accounts.org"
# 2. Get DKIM key
# 3. Add DNS records to byrne-accounts.org.zone:

client2.byrne-accounts.org. IN MX 10 mail.securenexus.net.
client2.byrne-accounts.org. IN TXT "v=spf1 mx a:mail.securenexus.net ~all"
_dmarc.client2.byrne-accounts.org. IN TXT "v=DMARC1; p=quarantine; rua=mailto:admin@securenexus.net"
dkim._domainkey.client2.byrne-accounts.org. IN TXT "v=DKIM1;k=rsa;..."

# 4. Increment serial, reload DNS
# 5. Create mailboxes in Mailcow
# 6. Configure in ERPNext
```

---

## 📋 DNS Zone File Template

Here's the complete DNS section to add for each client:

```dns
; ================================================
; Email for CLIENT_NAME (clientname.byrne-accounts.org)
; ================================================
; MX record
clientname.byrne-accounts.org. IN MX 10 mail.securenexus.net.

; SPF record
clientname.byrne-accounts.org. IN TXT "v=spf1 mx a:mail.securenexus.net ~all"

; DMARC policy
_dmarc.clientname.byrne-accounts.org. IN TXT "v=DMARC1; p=quarantine; rua=mailto:admin@securenexus.net; pct=100"

; DKIM key (get from Mailcow after adding domain)
dkim._domainkey.clientname.byrne-accounts.org. IN TXT "v=DKIM1;k=rsa;..."
```

---

## 🚨 Troubleshooting

### Email Not Sending

1. **Check SMTP credentials** in ERPNext Email Account

2. **Test SMTP manually**:
   ```bash
   swaks --to test@example.com \
     --from admin@dickinson.byrne-accounts.org \
     --server mail.securenexus.net:587 \
     --tls \
     --auth LOGIN \
     --auth-user admin@dickinson.byrne-accounts.org \
     --auth-password "PASSWORD"
   ```

3. **Check Mailcow logs**:
   ```bash
   cd /home/tristian/securenexus-fullstack/mail/mailcow-dockerized
   docker compose logs postfix-mailcow | grep dickinson | tail -50
   ```

### Email Marked as Spam

1. **Verify SPF record**:
   ```bash
   dig TXT dickinson.byrne-accounts.org +short
   ```

2. **Verify DKIM signature**:
   ```bash
   dig TXT dkim._domainkey.dickinson.byrne-accounts.org +short
   ```

3. **Test deliverability**: https://www.mail-tester.com

4. **Check reverse DNS** for mail server IP

### DNS Not Propagating

1. **Check serial increment**:
   ```bash
   grep "serial" /home/tristian/securenexus-fullstack/dns/zones/byrne-accounts.org.zone
   ```

2. **Restart CoreDNS**:
   ```bash
   docker compose restart coredns
   ```

3. **Query directly**:
   ```bash
   dig @137.74.40.208 MX dickinson.byrne-accounts.org +short
   ```

---

## 💰 Future: Client's Own Domain

When a client wants to upgrade to their own domain:

### Option 1: Point Their Domain to Your Mail Server

Client adds to their DNS:
```dns
MX 10 mail.securenexus.net.
TXT "v=spf1 mx a:mail.securenexus.net ~all"
```

You add their domain to Mailcow.

### Option 2: Migrate to Their Own Mail Server

Export their mailbox from Mailcow, import to their server.

---

## 📊 Email Account Summary

| Client | Domain | Admin Email | No-Reply Email | Quota |
|--------|--------|-------------|----------------|-------|
| Dickinson | dickinson.byrne-accounts.org | admin@dickinson... | noreply@dickinson... | 10GB |
| Client2 | client2.byrne-accounts.org | admin@client2... | noreply@client2... | 10GB |
| Your Site | erp.byrne-accounts.org | admin@erp... | noreply@erp... | 20GB |

---

## 🎯 Quick Command Reference

### Add DNS records for new client
```bash
# Edit zone file
nano /home/tristian/securenexus-fullstack/dns/zones/byrne-accounts.org.zone

# Increment serial (change last 2 digits)
# Add MX, SPF, DMARC, DKIM records

# Reload DNS
docker compose restart coredns

# Verify
dig MX clientname.byrne-accounts.org @localhost +short
```

### Check Mailcow logs
```bash
cd /home/tristian/securenexus-fullstack/mail/mailcow-dockerized
docker compose logs -f postfix-mailcow
```

### Test SMTP from command line
```bash
swaks --to test@gmail.com \
  --from admin@dickinson.byrne-accounts.org \
  --server mail.securenexus.net:587 \
  --tls --auth LOGIN \
  --auth-user admin@dickinson.byrne-accounts.org \
  --auth-password "PASSWORD"
```

---

**All set! Each client gets professional email under your control!** 🎉
