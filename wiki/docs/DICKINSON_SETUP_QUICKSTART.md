# Dickinson Site Setup - Quick Start Guide

## 🎯 Goal

Set up the dickinson.byrne-accounts.org ERPNext site with:
1. ✅ Professional email: `admin@dickinson.byrne-accounts.org`
2. ✅ Multi-tier admin access (you = super-admin, client = restricted admin)
3. ✅ Fully isolated from other client sites

---

## 📋 Quick Checklist

- [ ] Part 1: Set up multi-tier admin (15 min)
- [ ] Part 2: Set up email domain in Mailcow (10 min)
- [ ] Part 3: Configure DNS records (5 min)
- [ ] Part 4: Configure email in ERPNext (10 min)
- [ ] Part 5: Test everything (5 min)

**Total time**: ~45 minutes

---

## Part 1: Multi-Tier Admin Setup (15 min)

### Step 1: Login and Secure Administrator Account

1. **Go to**: https://dickinson.byrne-accounts.org

2. **Login**:
   - Username: `Administrator`
   - Password: From `client-credentials/dickinson.byrne-accounts.org.txt`

3. **Change password** (top right menu → My Settings)
   - Set a STRONG password only you know
   - Save it securely

### Step 2: Create Your Super-Admin User

1. **Search**: "User" (Ctrl+K)
2. **Click**: "+ New"
3. **Fill in**:
   - Email: `sysadmin@byrne-accounts.org`
   - First Name: Tristian
   - Roles: ☑ System Manager, ☑ Administrator
4. **Set password** (don't email)
5. **Save**

### Step 3: Create "Client Administrator" Role

1. **Search**: "Role"
2. **Click**: "+ New"
3. **Role Name**: `Client Administrator`
4. **Desk Access**: ☑ Checked
5. **Save**

### Step 4: Configure Client Admin Permissions

1. **Search**: "Role Permission Manager"
2. **Select**: "Client Administrator"
3. **Grant permissions**:
   - ✅ Customer, Supplier, Item (all permissions)
   - ✅ Sales Invoice, Purchase Invoice, Payment (all)
   - ✅ User (Read, Write, Create - NOT Delete)
   - ❌ System Settings (NO access)
   - ❌ Role (NO access)
   - ❌ DocType (NO access)
4. **Save**

### Step 5: Create Client Admin User

1. **Search**: "User"
2. **Click**: "+ New"
3. **Fill in**:
   - Email: `admin@dickinson.byrne-accounts.org`
   - First Name: Dickinson
   - Last Name: Admin
   - Roles: ☑ Client Administrator, ☑ Accounts Manager, ☑ Sales Manager
   - ☐ DO NOT check "System Manager" or "Administrator"
4. **Set strong password**
5. **Save**

6. **Save credentials**:
   ```bash
   cat >> client-credentials/dickinson.byrne-accounts.org.txt <<EOF

   CLIENT ADMIN (for Dickinson):
   Username: admin@dickinson.byrne-accounts.org
   Password: CLIENT_PASSWORD_HERE
   Role: Client Administrator (restricted)
   EOF
   ```

### Step 6: Test Admin Hierarchy

1. **Logout**
2. **Login as**: `admin@dickinson.byrne-accounts.org`
3. **Try**: Settings → System Settings (should fail ✅)
4. **Try**: Create new customer (should work ✅)
5. **Logout**
6. **Login as**: `sysadmin@byrne-accounts.org` (should have full access ✅)

**✅ Part 1 Complete!** You're now the super-admin, client has restricted access.

---

## Part 2: Email Domain Setup in Mailcow (10 min)

### Step 1: Access Mailcow

1. **Open**: https://mail.securenexus.net:8443

2. **Login** as admin

3. **If you don't know password**:
   ```bash
   cd /home/tristian/securenexus-fullstack/mail/mailcow-dockerized
   grep -i "admin" mailcow.conf | grep -i pass
   ```

### Step 2: Add dickinson Domain

1. **Go to**: Configuration → Email → Domains

2. **Click**: "+ Add domain"

3. **Fill in**:
   - Domain: `dickinson.byrne-accounts.org`
   - Description: Dickinson Client Email
   - Max mailboxes: 10
   - Max quota (MiB): 10240
   - Default quota (MiB): 1024

4. **Click**: "Add domain and restart SOGo"

5. **Wait**: 30 seconds

### Step 3: Get DKIM Key

1. **Stay on**: Configuration → Email → Domains

2. **Find**: dickinson.byrne-accounts.org

3. **Click**: "DKIM" or "Configuration"

4. **Copy the DKIM public key** - starts with `v=DKIM1;k=rsa;p=...`

5. **Save it** - you'll need this for DNS

### Step 4: Create Mailboxes

**Admin mailbox**:
1. **Go to**: Configuration → Email → Mailboxes
2. **Click**: "+ Add mailbox"
3. **Fill**:
   - Domain: `dickinson.byrne-accounts.org`
   - Username: `admin`
   - Name: Dickinson Administrator
   - Password: [Generate strong password - SAVE IT!]
   - Quota: 2048
4. **Add**

**No-reply mailbox** (optional):
1. **Click**: "+ Add mailbox" again
2. **Fill**:
   - Domain: `dickinson.byrne-accounts.org`
   - Username: `noreply`
   - Name: Dickinson No-Reply
   - Password: [Generate strong password]
   - Quota: 1024
   - Send only: ☑ Checked
3. **Add**

**Save credentials**:
```bash
cat > mail-credentials/dickinson.txt <<EOF
Email: admin@dickinson.byrne-accounts.org
Password: YOUR_PASSWORD_HERE
SMTP: mail.securenexus.net:587
IMAP: mail.securenexus.net:993
Created: $(date)
EOF
chmod 600 mail-credentials/dickinson.txt
```

**✅ Part 2 Complete!** Email domain and accounts created in Mailcow.

---

## Part 3: DNS Configuration (5 min)

### Step 1: Edit DNS Zone File

```bash
nano /home/tristian/securenexus-fullstack/dns/zones/byrne-accounts.org.zone
```

### Step 2: Add Email Records

**Add these lines before the final blank line**:

```dns
; ================================================
; Email for dickinson subdomain
; ================================================
dickinson.byrne-accounts.org. IN MX 10 mail.securenexus.net.
dickinson.byrne-accounts.org. IN TXT "v=spf1 mx a:mail.securenexus.net ~all"
_dmarc.dickinson.byrne-accounts.org. IN TXT "v=DMARC1; p=quarantine; rua=mailto:admin@securenexus.net"
dkim._domainkey.dickinson.byrne-accounts.org. IN TXT "PASTE_DKIM_KEY_FROM_MAILCOW_HERE"
```

**Replace** `PASTE_DKIM_KEY_FROM_MAILCOW_HERE` with the actual DKIM key from Part 2, Step 3.

### Step 3: Update Serial Number

Find the line with `serial` and increment it:
```dns
; Change from:
2025101101 ; serial

; To (today's date + 01):
2025102401 ; serial
```

### Step 4: Save and Reload

1. **Save**: Ctrl+X, Y, Enter

2. **Reload DNS**:
   ```bash
   docker compose restart coredns
   ```

3. **Verify**:
   ```bash
   dig MX dickinson.byrne-accounts.org @localhost +short
   # Should return: 10 mail.securenexus.net.

   dig TXT dickinson.byrne-accounts.org @localhost +short
   # Should return: "v=spf1 mx a:mail.securenexus.net ~all"
   ```

**✅ Part 3 Complete!** DNS configured for email.

---

## Part 4: Configure Email in ERPNext (10 min)

### Step 1: Login as Super-Admin

1. **Go to**: https://dickinson.byrne-accounts.org

2. **Login as**: `sysadmin@byrne-accounts.org`

### Step 2: Create Email Account

1. **Search**: "Email Account" (Ctrl+K)

2. **Click**: "+ New"

3. **Fill in**:

   **Basic Info**:
   - Email Account Name: `Dickinson Default`
   - Email ID: `admin@dickinson.byrne-accounts.org`
   - ☑ Default Outgoing
   - ☑ Default Incoming
   - ☑ Enable Incoming
   - ☑ Enable Outgoing

   **Outgoing (SMTP)**:
   - SMTP Server: `mail.securenexus.net`
   - ☑ Use TLS
   - Port: `587`
   - Login Id: `admin@dickinson.byrne-accounts.org`
   - Password: [From mail-credentials/dickinson.txt]

   **Incoming (IMAP)**:
   - Email Server: `mail.securenexus.net`
   - ☑ Use IMAP
   - ☑ Use SSL
   - Port: `993`

4. **Save**

5. **Scroll down** → **"Send Test Email"**

6. **Enter your email** → **Send**

7. **Check your inbox** - you should receive the test email ✅

**✅ Part 4 Complete!** Email integrated with ERPNext.

---

## Part 5: Final Testing (5 min)

### Test 1: Multi-Tier Admin

1. **Logout** from ERPNext

2. **Login as client**:
   - User: `admin@dickinson.byrne-accounts.org`
   - Pass: From client-credentials

3. **Verify client CAN**:
   - Create customer
   - Create invoice
   - View reports

4. **Verify client CANNOT**:
   - Access System Settings
   - Modify roles
   - Delete your sysadmin user

5. **Logout** and **login as**: `sysadmin@byrne-accounts.org`

6. **Verify you CAN**:
   - Access System Settings ✅
   - Modify roles ✅
   - Full admin access ✅

### Test 2: Email Sending

1. **While logged in as sysadmin**:

2. **Search**: "Customer" → Create test customer

3. **Search**: "Sales Invoice" → Create test invoice

4. **Click**: "Email" button

5. **Send to**: Your personal email

6. **Verify**:
   - Email received ✅
   - From: admin@dickinson.byrne-accounts.org ✅
   - Not in spam ✅

### Test 3: Email Receiving

1. **Send an email TO**: admin@dickinson.byrne-accounts.org

2. **Wait**: 2-5 minutes

3. **In ERPNext**: Home → Email → Communication

4. **Verify**: Your email appears ✅

---

## ✅ Setup Complete!

You now have:

- ✅ **dickinson.byrne-accounts.org** - Fully functional ERPNext site
- ✅ **Multi-tier admin** - You're super-admin, client has restricted access
- ✅ **Professional email** - admin@dickinson.byrne-accounts.org
- ✅ **Complete isolation** - Site is separate from others
- ✅ **Email notifications** - Ready for invoices, receipts, alerts

---

## 📚 Reference Documents

For detailed explanations:
- **Admin hierarchy**: `docs/ERPNEXT_MULTI_TIER_ADMIN_SETUP.md`
- **Email setup**: `docs/ERPNEXT_EMAIL_SUBDOMAIN_SETUP.md`
- **Multi-company vs multi-site**: `docs/ERPNEXT_MULTI_COMPANY_AND_MULTISITE.md`

---

## 🔑 Your Access Summary

```
=== YOUR ACCESS (Super Admin) ===
Site: https://dickinson.byrne-accounts.org
User 1: Administrator / [from client-credentials]
User 2: sysadmin@byrne-accounts.org / [your password]
Role: Full system access
Can: Do anything, fix anything, recover from disasters

=== CLIENT ACCESS (Restricted Admin) ===
Site: https://dickinson.byrne-accounts.org
User: admin@dickinson.byrne-accounts.org / [from client-credentials]
Role: Client Administrator
Can: Daily operations, user management, reports
Cannot: System settings, roles, break things

=== EMAIL ACCESS ===
Email: admin@dickinson.byrne-accounts.org
SMTP: mail.securenexus.net:587 (STARTTLS)
IMAP: mail.securenexus.net:993 (SSL)
Webmail: https://mail.securenexus.net:8443 (login with email@password)
```

---

## 🚀 Next Steps

1. **Hand over to client**:
   - Give them: admin@dickinson.byrne-accounts.org credentials
   - Guide them through initial setup wizard
   - Train on their restricted access level

2. **Complete ERPNext setup**:
   - Run setup wizard (Company info, currency, etc.)
   - Create POS profile
   - Add products/services
   - Configure print formats

3. **Set up for next client**:
   - Repeat this process for client2
   - Email: admin@client2.byrne-accounts.org
   - Same multi-tier structure

---

**Congratulations! Dickinson site is production-ready!** 🎉
