# Mailcow API Setup for Automated Client Provisioning

## Overview

To enable **fully automated client provisioning** (including email setup), we need to configure Mailcow API access.

---

## Step 1: Generate Mailcow API Key

### Access Mailcow Admin

```bash
URL: https://mail.securenexus.net
Username: admin
Password: [your Mailcow admin password]
```

### Create API Key

1. **Login** to Mailcow admin panel

2. **Navigate to API**
   - Click your username (top right)
   - Select "Edit" or "Access"
   - Look for "API" section

3. **Generate API Key**
   - Click "Add API key" or similar
   - Description: "Client Provisioning Script"
   - Access Level: **Read/Write**
   - Allow these endpoints:
     - `/api/v1/add/mailbox`
     - `/api/v1/add/alias`
     - `/api/v1/add/domain` (if creating custom domains)
   - Click "Generate" or "Create"

4. **Copy the API Key**
   - You'll see a long string like: `XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX`
   - **Copy this immediately** - you can't see it again!

### Save API Key Securely

```bash
# Save to secrets file
echo "YOUR-API-KEY-HERE" > secrets/mailcow_api_key.txt

# Secure permissions
chmod 600 secrets/mailcow_api_key.txt

# Verify
cat secrets/mailcow_api_key.txt
```

---

## Step 2: Test API Access

### Test API Key

```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)

# Test endpoint - list domains
curl -s "https://mail.securenexus.net/api/v1/get/domain/all" \
  -H "X-API-Key: ${API_KEY}" | jq .
```

**Expected Output**: JSON array of domains

### Test Mailbox Creation (Dry Run)

```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)

# Create test mailbox
curl -X POST "https://mail.securenexus.net/api/v1/add/mailbox" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "local_part": "test",
    "domain": "byrne-accounts.org",
    "name": "Test User",
    "password": "TestPassword123!",
    "password2": "TestPassword123!",
    "quota": "5120",
    "active": "1",
    "sogo_access": "1"
  }' | jq .
```

**Expected Output**: Success message

**Cleanup** (delete test mailbox):
```bash
curl -X POST "https://mail.securenexus.net/api/v1/delete/mailbox" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"items":["test@byrne-accounts.org"]}' | jq .
```

---

## Step 3: Update Provisioning Script

The provisioning script will automatically use the API key from:
```
secrets/mailcow_api_key.txt
```

**If file exists**: Email setup is automated
**If file missing**: Script shows manual instructions

---

## Mailcow API Endpoints Used

### 1. Create Mailbox

**Endpoint**: `POST /api/v1/add/mailbox`

**Example**:
```bash
curl -X POST "https://mail.securenexus.net/api/v1/add/mailbox" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "local_part": "demo",
    "domain": "byrne-accounts.org",
    "name": "Demo Client",
    "password": "SecurePassword123!",
    "password2": "SecurePassword123!",
    "quota": "10240",
    "active": "1",
    "force_pw_update": "0",
    "sogo_access": "1"
  }'
```

**Parameters**:
- `local_part`: Username part (e.g., "demo" for demo@domain.com)
- `domain`: Email domain (e.g., "byrne-accounts.org")
- `name`: Display name for mailbox
- `password` / `password2`: Password (must match)
- `quota`: Size in MB (10240 = 10GB, 0 = unlimited)
- `active`: 1 = active, 0 = disabled
- `force_pw_update`: 0 = no, 1 = force password change on first login
- `sogo_access`: 1 = enable webmail access

### 2. Create Email Alias

**Endpoint**: `POST /api/v1/add/alias`

**Example**:
```bash
curl -X POST "https://mail.securenexus.net/api/v1/add/alias" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "address": "support@byrne-accounts.org",
    "goto": "demo@byrne-accounts.org",
    "active": "1"
  }'
```

**Parameters**:
- `address`: Alias email address
- `goto`: Destination mailbox (where emails are forwarded)
- `active`: 1 = active, 0 = disabled

**Multiple Destinations**:
```json
{
  "address": "support@byrne-accounts.org",
  "goto": "demo@byrne-accounts.org,admin@byrne-accounts.org",
  "active": "1"
}
```

### 3. Add Domain (Optional)

**Endpoint**: `POST /api/v1/add/domain`

**Example**:
```bash
curl -X POST "https://mail.securenexus.net/api/v1/add/domain" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "newclient.com",
    "description": "New Client Email",
    "aliases": "400",
    "mailboxes": "50",
    "defquota": "10240",
    "maxquota": "10240",
    "quota": "102400",
    "active": "1"
  }'
```

---

## Email Alias Strategy

### Standard Aliases Per Client

When provisioning a client, create these standard aliases:

1. **support@** - Customer support inquiries
2. **info@** - General information requests
3. **financial@** - Billing/accounting questions
4. **sales@** - Sales inquiries
5. **accounts@** - Account management

**All forward to ONE main inbox** (e.g., `clientname@byrne-accounts.org`)

### Benefits

✅ **ONE inbox to monitor**
✅ **Professional appearance** (clients see support@, not admin@)
✅ **Easy to manage** (add/remove aliases without changing inbox)
✅ **Reply FROM any alias** (Mailcow supports sender identity)

---

## Security Best Practices

### 1. API Key Storage
- ✅ Store in `secrets/` directory (gitignored)
- ✅ Set file permissions: `chmod 600`
- ✅ Never commit to git
- ✅ Rotate keys quarterly

### 2. API Key Permissions
- ✅ Create separate keys for different purposes
- ✅ Limit to specific endpoints if possible
- ✅ Document what each key is used for
- ✅ Revoke unused keys

### 3. Password Generation
- ✅ Use strong random passwords: `openssl rand -base64 32`
- ✅ Different password for each client
- ✅ Store securely in `/client-credentials/`
- ✅ Encrypt backup files containing credentials

---

## Complete Workflow Example

### Provision New Client with Email

```bash
# 1. Ensure API key is set up
cat secrets/mailcow_api_key.txt

# 2. Run provisioning script
./scripts/provision-client-complete.sh \
  --name "ACME Corporation" \
  --subdomain "acme" \
  --domain "acmecorp.com" \
  --plan "professional"

# Script will:
# ✅ Create ERPNext site (acme.byrne-accounts.org)
# ✅ Install POS Awesome
# ✅ Create main mailbox (acme@acmecorp.com)
# ✅ Create 5 aliases (support@, info@, financial@, sales@, accounts@)
# ✅ All aliases forward to main mailbox
# ✅ Configure Traefik routing
# ✅ Save credentials
# ✅ Generate setup instructions
```

**Result**: Complete client system in ~5 minutes!

---

## Troubleshooting

### API Key Not Working

**Check API key format**:
```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)
echo "Length: ${#API_KEY}"  # Should be ~40-60 characters
```

**Test directly**:
```bash
curl -s "https://mail.securenexus.net/api/v1/get/domain/all" \
  -H "X-API-Key: YOUR-KEY-HERE" -w "\nHTTP Status: %{http_code}\n"
```

**Expected**: HTTP Status: 200
**If 401**: API key is invalid
**If 403**: API key lacks permissions

### Mailbox Creation Fails

**Check if mailbox already exists**:
```bash
curl -s "https://mail.securenexus.net/api/v1/get/mailbox/demo@byrne-accounts.org" \
  -H "X-API-Key: ${API_KEY}" | jq .
```

**Check domain exists**:
```bash
curl -s "https://mail.securenexus.net/api/v1/get/domain/byrne-accounts.org" \
  -H "X-API-Key: ${API_KEY}" | jq .
```

### Alias Creation Fails

**Ensure destination mailbox exists first**:
```bash
# Create mailbox BEFORE creating aliases
# Alias destination must be a real mailbox
```

---

## API Documentation

**Official Mailcow API Docs**:
- URL: `https://mail.securenexus.net/api`
- Interactive: Swagger UI included
- Test endpoints directly in browser

**View in Browser**:
```
https://mail.securenexus.net/api
```

---

## Quick Reference

### Get API Key
```bash
cat secrets/mailcow_api_key.txt
```

### Test API
```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)
curl -s "https://mail.securenexus.net/api/v1/get/domain/all" \
  -H "X-API-Key: ${API_KEY}" | jq .
```

### Create Mailbox
```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)
curl -X POST "https://mail.securenexus.net/api/v1/add/mailbox" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"local_part":"user","domain":"byrne-accounts.org","name":"User","password":"Pass123!","password2":"Pass123!","quota":"5120","active":"1"}'
```

### Create Alias
```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)
curl -X POST "https://mail.securenexus.net/api/v1/add/alias" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"address":"support@byrne-accounts.org","goto":"user@byrne-accounts.org","active":"1"}'
```

---

## Next Steps

1. ✅ Generate Mailcow API key
2. ✅ Save to `secrets/mailcow_api_key.txt`
3. ✅ Test API access
4. ✅ Run provisioning script
5. ✅ Verify email system works

**Ready to provision clients with one command!** 🚀

---

*Last Updated: October 28, 2025*
*Version: 1.0*
