# Complete Proof of Concept - Test Guide

## 🎯 Goal

Demonstrate the **complete multi-tenant system** working end-to-end:
1. ✅ Landing page
2. ✅ Client portal with selector
3. ✅ ERPNext site creation
4. ✅ POS Awesome installation
5. ✅ Email system with aliases (multiple addresses → ONE inbox)
6. ✅ All 3 components accessible via portal

---

## Step-by-Step Test

### Phase 1: Access Mailcow & Get API Key (10 minutes)

#### 1.1 Run Helper Script

```bash
cd /home/tristian/securenexus-fullstack
./scripts/mailcow-get-api-key.sh
```

**This will guide you through**:
- Opening Mailcow web interface
- Logging in as admin
- Generating API key
- Saving it to `secrets/mailcow_api_key.txt`

#### 1.2 Access Mailcow Admin

**URL**: `https://mail.securenexus.net`

**Default Credentials** (if never changed):
- Username: `admin`
- Password: `moohoo` (Mailcow default)

**If password was changed**: Check your Mailcow setup notes

#### 1.3 Generate API Key

1. Login to Mailcow
2. Click **username** (top right) → **Edit**
3. Scroll to **API** section
4. Check **"Activate API"**
5. Select **"Read/Write access"**
6. Copy the API key (format: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)

#### 1.4 Save API Key

```bash
# Save to secrets file
echo 'PASTE-YOUR-API-KEY-HERE' > secrets/mailcow_api_key.txt

# Secure permissions
chmod 600 secrets/mailcow_api_key.txt

# Verify
cat secrets/mailcow_api_key.txt
```

#### 1.5 Test API Key

```bash
# Run helper script again to test
./scripts/mailcow-get-api-key.sh
```

**Expected**: "✓ API key is valid!"

---

### Phase 2: Test Manual Email Creation (5 minutes)

Before running the full provisioning, let's test email creation manually:

#### 2.1 Create Test Mailbox

```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)

curl -X POST "https://mail.securenexus.net/api/v1/add/mailbox" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "local_part": "poctest",
    "domain": "byrne-accounts.org",
    "name": "POC Test User",
    "password": "TestPass2025!",
    "password2": "TestPass2025!",
    "quota": "5120",
    "active": "1",
    "sogo_access": "1"
  }' | jq .
```

**Expected Output**:
```json
[
  {
    "type": "success",
    "log": [
      ["mailbox", "add", "poctest@byrne-accounts.org", "OK"]
    ],
    "msg": ["mailbox_added", "poctest@byrne-accounts.org"]
  }
]
```

#### 2.2 Create Test Alias

```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)

curl -X POST "https://mail.securenexus.net/api/v1/add/alias" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "address": "support-test@byrne-accounts.org",
    "goto": "poctest@byrne-accounts.org",
    "active": "1"
  }' | jq .
```

**Expected**: Success message

#### 2.3 Test Email Login

**Webmail**: `https://mail.securenexus.net`
- Email: `poctest@byrne-accounts.org`
- Password: `TestPass2025!`

**Expected**: You should be able to login and see empty inbox

#### 2.4 Cleanup Test

```bash
API_KEY=$(cat secrets/mailcow_api_key.txt)

# Delete alias
curl -X POST "https://mail.securenexus.net/api/v1/delete/alias" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '["support-test@byrne-accounts.org"]' | jq .

# Delete mailbox
curl -X POST "https://mail.securenexus.net/api/v1/delete/mailbox" \
  -H "X-API-Key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '["poctest@byrne-accounts.org"]' | jq .
```

---

### Phase 3: Run Complete Client Provisioning (5 minutes)

Now let's provision a complete test client with ALL THREE components:

#### 3.1 Run Provisioning Script

```bash
cd /home/tristian/securenexus-fullstack

./scripts/provision-client-complete.sh \
  --name "POC Test Client" \
  --subdomain "poctest"
```

**Script will**:
1. Create ERPNext site: `poctest.byrne-accounts.org`
2. Install POS Awesome
3. Create mailbox: `poctest@byrne-accounts.org`
4. Create aliases:
   - `support@byrne-accounts.org` → poctest@
   - `info@byrne-accounts.org` → poctest@
   - `financial@byrne-accounts.org` → poctest@
   - `sales@byrne-accounts.org` → poctest@
   - `accounts@byrne-accounts.org` → poctest@
5. Generate secure passwords
6. Save credentials

**Time**: ~3-5 minutes

#### 3.2 Add Traefik Labels

When prompted, add these labels to `compose.yml` in the `erpnext-backend` service:

```yaml
      # Client site: poctest.byrne-accounts.org
      - traefik.http.routers.erp-poctest.rule=Host(`poctest.byrne-accounts.org`)
      - traefik.http.routers.erp-poctest.entrypoints=websecure
      - traefik.http.routers.erp-poctest.tls.certresolver=le
      - traefik.http.routers.erp-poctest.middlewares=secure-headers@file
      - traefik.http.routers.erp-poctest.service=erp
      - traefik.http.routers.erp-poctest-http.rule=Host(`poctest.byrne-accounts.org`)
      - traefik.http.routers.erp-poctest-http.entrypoints=web
      - traefik.http.routers.erp-poctest-http.middlewares=redirect-to-https@file
```

Then restart:
```bash
docker compose restart erpnext-backend
```

#### 3.3 Add to Portal

Edit `byrne-website/portal.html`, add this option:

```html
<select id="clientSelect">
    <option value="">-- Choose Client --</option>
    <option value="erp.byrne-accounts.org">Byrne Accounting (Internal)</option>
    <option value="demo.byrne-accounts.org">Demo Client</option>
    <option value="poctest.byrne-accounts.org">POC Test Client</option>  <!-- NEW -->
</select>
```

#### 3.4 View Credentials

```bash
cat client-credentials/poctest.byrne-accounts.org.txt
```

**Save these credentials** - you'll need them for testing!

---

### Phase 4: Test Complete System (15 minutes)

Now test that ALL components work together:

#### 4.1 Test Portal Access

**URL**: `https://byrne-accounts.org/portal.html`

**Steps**:
1. Open portal
2. Select "POC Test Client" from dropdown
3. Verify 3 cards appear:
   - ERP System
   - POS System
   - Email Management

#### 4.2 Test ERP Access

**Click**: "Access ERP System" button

**URL**: `https://poctest.byrne-accounts.org`

**Login**:
- Username: `Administrator`
- Password: [from credentials file]

**Verify**:
- ✅ Login works
- ✅ ERPNext dashboard loads
- ✅ Can navigate around
- ✅ Create a test customer

#### 4.3 Test POS Access

**Click**: "Access POS System" button

**URL**: `https://poctest.byrne-accounts.org/pos`

**Login**: Same as ERP

**Verify**:
- ✅ POS Awesome interface loads
- ✅ Touch-friendly interface
- ✅ Can select items (if any exist)

#### 4.4 Test Email Access

**Click**: "Access Webmail" button

**URL**: `https://mail.securenexus.net`

**Login**:
- Email: `poctest@byrne-accounts.org`
- Password: [from credentials file]

**Verify**:
- ✅ SOGo webmail loads
- ✅ Can see inbox
- ✅ Can compose email
- ✅ Calendar available
- ✅ Contacts available

#### 4.5 Test Email Aliases

**Test that all aliases forward to main inbox**:

1. **Send test email TO**: `support@byrne-accounts.org`
   - From your personal email or another test account
   - Subject: "Test Support Email"

2. **Check main inbox**: Login to `poctest@byrne-accounts.org`
   - ✅ Email should appear in inbox
   - ✅ Shows "To: support@byrne-accounts.org"

3. **Reply FROM alias**:
   - In SOGo, reply to the email
   - ✅ Reply should come FROM: `support@byrne-accounts.org`

4. **Repeat for other aliases**:
   - Send to: `info@byrne-accounts.org` → arrives in poctest@ inbox
   - Send to: `financial@byrne-accounts.org` → arrives in poctest@ inbox
   - Send to: `sales@byrne-accounts.org` → arrives in poctest@ inbox

**Result**: ONE inbox receives ALL emails!

---

### Phase 5: Test Data Isolation (10 minutes)

Verify that different clients can't see each other's data:

#### 5.1 Create Data in POC Test Client

1. Login to: `https://poctest.byrne-accounts.org`
2. Navigate to: **Selling → Customer**
3. Create customer:
   - Customer Name: "POC Test Customer 123"
   - Save

#### 5.2 Check Other Client

1. Login to: `https://demo.byrne-accounts.org`
   - Username: `Administrator`
   - Password: `DemoClient2025!`
2. Navigate to: **Selling → Customer**
3. Search for: "POC Test Customer 123"

**Expected**: ✅ Customer does NOT appear (complete isolation!)

#### 5.3 Check Database Isolation

```bash
# Show separate databases
docker exec erpnext-db mysql -u root -p$(cat secrets/erpnext_db_password.txt) -e "
SELECT
  table_schema AS 'Database',
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema LIKE '%byrne-accounts%'
GROUP BY table_schema
ORDER BY table_schema;"
```

**Expected Output**:
```
+-------------------------------+-----------+
| Database                      | Size (MB) |
+-------------------------------+-----------+
| _demo_byrne_accounts_org      |     45.23 |
| _erp_byrne_accounts_org       |    123.45 |
| _poctest_byrne_accounts_org   |     12.34 |
+-------------------------------+-----------+
```

**Verification**: ✅ Each client has separate database

---

## ✅ Success Criteria

### Complete Proof of Concept Verified When:

- [x] **Landing page accessible**: `https://byrne-accounts.org`
- [x] **Portal with selector works**: `https://byrne-accounts.org/portal.html`
- [x] **Client selection shows services**: 3 cards appear
- [x] **ERP accessible**: poctest.byrne-accounts.org
- [x] **POS accessible**: poctest.byrne-accounts.org/pos
- [x] **Email accessible**: mail.securenexus.net (webmail)
- [x] **Email aliases work**: support@, info@, etc. → ONE inbox
- [x] **Data isolation confirmed**: Separate databases, no cross-client access
- [x] **One-command provisioning works**: Complete setup in ~5 minutes
- [x] **Credentials auto-generated**: Secure passwords created and saved

---

## 📊 System Architecture Confirmed

```
┌─────────────────────────────────────┐
│  Landing Page (byrne-accounts.org)  │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│  Portal (with client selector)      │
└────────────┬────────────────────────┘
             │
    ┌────────┴────────┬────────────┐
    ▼                 ▼            ▼
┌─────────┐     ┌─────────┐   ┌─────────┐
│ Internal│     │  Demo   │   │ POC Test│
│  Site   │     │  Site   │   │  Site   │
├─────────┤     ├─────────┤   ├─────────┤
│ • ERP   │     │ • ERP   │   │ • ERP   │
│ • POS   │     │ • POS   │   │ • POS   │
│ • Email │     │ • Email │   │ • Email │
│         │     │         │   │         │
│ DB: _erp│     │ DB:_demo│   │ DB:_poc │
└─────────┘     └─────────┘   └─────────┘
```

---

## 🎯 What We've Proven

### 1. ✅ Multi-Tenant Architecture Works
- Multiple clients on one infrastructure
- Complete data isolation
- Separate databases per client
- No cross-client data leakage

### 2. ✅ Complete 3-Service System
- **ERP**: Full business management (ERPNext)
- **POS**: Modern point of sale (POS Awesome)
- **Email**: Professional email with calendar (Mailcow + SOGo)

### 3. ✅ Email Alias System
- Multiple professional addresses
- ALL forward to ONE inbox
- Easy to manage
- Can reply FROM any alias

### 4. ✅ One-Command Provisioning
- Complete client setup in ~5 minutes
- Automated email creation
- Secure password generation
- Credential documentation

### 5. ✅ Professional User Experience
- Clean landing page
- Intuitive portal with selector
- Seamless access to all services
- Consistent branding

---

## 📝 Test Results Template

```
═══════════════════════════════════════════════════════════
  PROOF OF CONCEPT TEST RESULTS
═══════════════════════════════════════════════════════════

Date: _______________
Tester: _______________

PHASE 1: Mailcow API Setup
[ ] Accessed Mailcow admin
[ ] Generated API key
[ ] Saved to secrets/
[ ] API key tested successfully

PHASE 2: Manual Email Test
[ ] Created test mailbox
[ ] Created test alias
[ ] Logged into webmail
[ ] Cleaned up test data

PHASE 3: Complete Provisioning
[ ] Ran provision script
[ ] Added Traefik labels
[ ] Added to portal
[ ] Credentials saved

PHASE 4: Component Testing
[ ] Landing page works
[ ] Portal selector works
[ ] ERP accessible and functional
[ ] POS accessible and functional
[ ] Email accessible and functional
[ ] Email aliases tested
[ ] Can reply FROM aliases

PHASE 5: Data Isolation
[ ] Created test data in POC client
[ ] Verified not visible in Demo client
[ ] Confirmed separate databases

OVERALL RESULT: [ ] PASS / [ ] FAIL

Notes:
_________________________________________________________
_________________________________________________________
_________________________________________________________

═══════════════════════════════════════════════════════════
```

---

## 🚀 Next Steps After PoC Success

1. **Production Deployment**
   - Move demo clients to production
   - Set up monitoring alerts
   - Configure automated backups

2. **Client Onboarding**
   - Create welcome email template
   - Prepare training materials
   - Set up support ticketing

3. **Scaling Preparation**
   - Monitor resource usage
   - Plan for horizontal scaling
   - Set up load balancing (if needed)

4. **Feature Enhancements**
   - SSO integration (Authentik)
   - Custom branding per client
   - Billing system integration
   - Client self-service portal

---

## 📞 Support

If anything fails during testing:

1. **Check logs**:
   ```bash
   docker compose logs traefik | grep poctest
   docker compose logs erpnext-backend | tail -50
   ```

2. **Verify services**:
   ```bash
   docker compose ps
   ```

3. **Review credentials**:
   ```bash
   cat client-credentials/poctest.byrne-accounts.org.txt
   ```

4. **Test connectivity**:
   ```bash
   curl -k -I https://poctest.byrne-accounts.org
   ```

---

## ✨ Success!

When all tests pass, you have a **complete, production-ready multi-tenant SaaS platform** that can:

✅ Onboard unlimited clients
✅ Provide 3 integrated services per client
✅ Maintain complete data isolation
✅ Automate provisioning
✅ Scale to hundreds of clients

**Ready to launch! 🎉**

---

*Last Updated: October 28, 2025*
*Version: 1.0*
