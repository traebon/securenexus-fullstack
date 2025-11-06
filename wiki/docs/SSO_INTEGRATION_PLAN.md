# SSO Integration Plan - Authentik with ERPNext & Mailcow

## 🎯 Goal

Implement Single Sign-On (SSO) using Authentik for:

1. **You (Sysadmin)**:
   - Login once → Access Mailcow admin + All ERPNext sites

2. **Each Client**:
   - Login once → Access their ERPNext + their Mailcow webmail + POS
   - Completely isolated from other clients

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    AUTHENTIK SSO                        │
│              (sso.securenexus.net)                     │
└─────────────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   MAILCOW    │  │   ERPNEXT    │  │     POS      │
│   Webmail    │  │ dickinson... │  │   (same)     │
│   SOGo       │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

### User Login Flow

**Client Login**:
1. User visits: https://dickinson.byrne-accounts.org
2. Redirected to: https://sso.securenexus.net (Authentik)
3. Login with: client@dickinson.byrne-accounts.org
4. Authenticated → Redirected back to ERPNext (logged in)
5. Click webmail link → Auto-logged into Mailcow webmail
6. Click POS → Auto-logged in (same session)

**Your Login**:
1. Login to Authentik once
2. Access any ERPNext site → Auto-logged in
3. Access Mailcow admin → Auto-logged in
4. Single logout = logged out everywhere

---

## 🔐 SSO Implementation Strategy

### Phase 1: Sysadmin SSO (Your Access)

**Goal**: You login to Authentik once, access Mailcow + all ERPNext sites

#### Step 1.1: Configure Mailcow OIDC

Mailcow supports OAuth2/OIDC authentication:

1. **In Authentik**: Create OAuth2/OIDC Provider
   - Name: `Mailcow Admin`
   - Client Type: Confidential
   - Redirect URI: `https://mail.securenexus.net:8443/oauth/callback`
   - Scopes: openid, email, profile

2. **In Mailcow**: Configure OAuth
   - Edit `mailcow.conf`:
     ```
     OAUTH2_ENABLE=y
     OAUTH2_PROVIDER_NAME=Authentik
     OAUTH2_CLIENT_ID=mailcow-client-id
     OAUTH2_CLIENT_SECRET=your-secret
     OAUTH2_AUTHORIZATION_URL=https://sso.securenexus.net/application/o/authorize/
     OAUTH2_TOKEN_URL=https://sso.securenexus.net/application/o/token/
     OAUTH2_USERINFO_URL=https://sso.securenexus.net/application/o/userinfo/
     ```

3. **Result**: Mailcow admin UI uses Authentik for login

#### Step 1.2: Configure ERPNext OIDC

ERPNext has built-in OIDC support:

1. **In Authentik**: Create OAuth2/OIDC Provider
   - Name: `ERPNext Dickinson`
   - Redirect URI: `https://dickinson.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik`

2. **In ERPNext**: Setup → Integrations → Social Login Key
   - Provider Name: `Authentik`
   - Client ID: From Authentik
   - Client Secret: From Authentik
   - Base URL: `https://sso.securenexus.net`
   - Authorize URL: `/application/o/authorize/`
   - Access Token URL: `/application/o/token/`
   - Redirect URL: `/api/method/frappe.integrations.oauth2_logins.custom/authentik`

3. **Result**: ERPNext shows "Login with Authentik" button

---

### Phase 2: Client SSO (Per-Client Isolation)

**Challenge**: Each client needs their own isolated SSO tenant

**Solution**: Use Authentik's multi-tenancy features

#### Step 2.1: Create Client Tenant in Authentik

For each client (e.g., Dickinson):

1. **Create Group**: `Dickinson Users`
   - All Dickinson employees are members

2. **Create Application**: `Dickinson ERPNext`
   - Provider: OAuth2/OIDC
   - Policy binding: Only allow "Dickinson Users" group

3. **Create Application**: `Dickinson Webmail`
   - Provider: OAuth2/OIDC (for SOGo)
   - Policy binding: Only allow "Dickinson Users" group

4. **Result**: Dickinson users can ONLY access Dickinson apps

#### Step 2.2: User Provisioning

**Option A: Manual Creation**
- You create users in Authentik for each client
- Assign them to client's group

**Option B: Self-Service Registration**
- Client admin can invite users
- Users register via Authentik enrollment flow
- Auto-assigned to correct group based on email domain

**Option C: LDAP Sync (Advanced)**
- If client has existing LDAP/AD
- Sync users from their directory

---

### Phase 3: Mailcow Webmail SSO (SOGo)

**Challenge**: SOGo (Mailcow's webmail) has limited SSO support

**Solutions**:

#### Option A: Use Authentik Proxy Provider (Recommended)

Authentik can act as an authentication proxy:

1. **Create Proxy Provider** in Authentik
   - Name: `Dickinson Webmail Proxy`
   - External host: `https://webmail.dickinson.byrne-accounts.org`
   - Internal host: `http://sogo-mailcow:8080`
   - Authorization flow: Dickinson Users only

2. **Route through Traefik**:
   ```yaml
   # In compose.yml - add Traefik labels
   labels:
     - traefik.http.routers.dickinson-webmail.rule=Host(`webmail.dickinson.byrne-accounts.org`)
     - traefik.http.routers.dickinson-webmail.middlewares=authentik-proxy@file
   ```

3. **Result**: Accessing webmail.dickinson... requires Authentik login first

#### Option B: Direct IMAP Auth with Authentik (Advanced)

Configure Mailcow to use Authentik as LDAP backend:

1. **Enable LDAP in Authentik**
2. **Configure Dovecot** to authenticate against Authentik LDAP
3. **Result**: Email passwords are managed by Authentik

#### Option C: Keep Separate (Simple)

- Client logs into ERPNext/POS via SSO
- Webmail stays separate password
- Still convenient (browser remembers password)

**Recommendation**: Start with Option C, upgrade to Option A later

---

## 📋 Implementation Phases

### Phase 1: Sysadmin SSO (Week 1)

- [x] Documented architecture
- [ ] Configure Mailcow OAuth for your access
- [ ] Configure Authentik OIDC provider for Mailcow
- [ ] Test: Login to Authentik → Access Mailcow admin
- [ ] Configure ERPNext OIDC on dickinson site
- [ ] Test: Login to Authentik → Access all ERPNext sites

**Outcome**: You have SSO across all systems

### Phase 2: Dickinson Client SSO (Week 2)

- [ ] Create "Dickinson Users" group in Authentik
- [ ] Create Dickinson user accounts in Authentik
- [ ] Configure Dickinson ERPNext app in Authentik
- [ ] Map Authentik users to ERPNext users
- [ ] Test: Client login via Authentik → ERPNext access

**Outcome**: Dickinson client has SSO for ERPNext

### Phase 3: Webmail SSO (Week 3)

- [ ] Evaluate SOGo SSO options
- [ ] Choose implementation (Proxy vs LDAP vs Separate)
- [ ] Configure chosen solution
- [ ] Test: Client SSO → Webmail access

**Outcome**: Complete SSO for all client services

### Phase 4: POS Integration (Week 4)

- [ ] Test POS with SSO session
- [ ] Configure session sharing between ERP and POS
- [ ] Test: Login once → Access ERP and POS

**Outcome**: Single login for all client touchpoints

### Phase 5: Multi-Client Rollout (Ongoing)

- [ ] Template Authentik configuration
- [ ] Automate client tenant creation
- [ ] Update provision-client-site.sh to include SSO setup
- [ ] Document client onboarding with SSO

**Outcome**: Scalable SSO for new clients

---

## 🔧 Technical Implementation Details

### Authentik OIDC Provider Configuration

**For Mailcow**:
```yaml
Name: Mailcow Admin
Client Type: Confidential
Client ID: mailcow-${RANDOM}
Redirect URIs:
  - https://mail.securenexus.net:8443/oauth/callback
Scopes:
  - openid
  - email
  - profile
  - groups
Token validity: 10 hours
Refresh token validity: 30 days
```

**For ERPNext (Dickinson)**:
```yaml
Name: ERPNext Dickinson
Client Type: Confidential
Client ID: erpnext-dickinson-${RANDOM}
Redirect URIs:
  - https://dickinson.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik
Scopes:
  - openid
  - email
  - profile
Token validity: 24 hours
```

### ERPNext OIDC Configuration

In ERPNext (Setup → Integrations → Social Login Key):

```json
{
  "provider_name": "Authentik",
  "client_id": "erpnext-dickinson-CLIENT-ID",
  "client_secret": "YOUR_SECRET",
  "base_url": "https://sso.securenexus.net",
  "authorize_url": "/application/o/authorize/",
  "access_token_url": "/application/o/token/",
  "redirect_url": "/api/method/frappe.integrations.oauth2_logins.custom/authentik",
  "api_endpoint": "/application/o/userinfo/",
  "auth_url_data": {
    "response_type": "code",
    "scope": "openid email profile"
  }
}
```

### User Mapping

**Authentik User** → **ERPNext User**:
- Authentik email: `john@dickinson.byrne-accounts.org`
- ERPNext user: Auto-created on first SSO login
- Role: Assigned based on Authentik group membership
- Permissions: Managed in ERPNext after creation

---

## 🎯 User Experience

### Client User Journey (Dickinson Employee)

**First-Time Login**:
1. Go to: https://dickinson.byrne-accounts.org
2. Click: "Login with Authentik"
3. Redirect to: https://sso.securenexus.net
4. Enter: john@dickinson.byrne-accounts.org / password
5. **First time**: Accept permissions
6. Redirect back: Logged into ERPNext
7. ERPNext auto-creates user account
8. Client admin assigns roles

**Subsequent Logins**:
1. Go to: https://dickinson.byrne-accounts.org
2. Click: "Login with Authentik"
3. **Already logged in** → Instant access (no password needed)
4. Go to POS: https://pos.byrne-accounts.org
5. **Same session** → Instant access
6. Go to Webmail: https://webmail.dickinson... (if using proxy)
7. **Same session** → Instant access

**Logout**:
1. Click logout in any app
2. Logged out of ALL apps
3. Next access requires re-login

### Your Journey (Sysadmin)

**Morning Login**:
1. Go to: https://sso.securenexus.net
2. Login once
3. Go to: https://mail.securenexus.net:8443 → Auto-logged in
4. Go to: https://dickinson.byrne-accounts.org → Auto-logged in
5. Go to: https://client2.byrne-accounts.org → Auto-logged in
6. **Work all day** without re-entering passwords

---

## 🔐 Security Considerations

### Session Management
- Session timeout: 24 hours (configurable)
- Refresh tokens: 30 days
- Revoke on password change: Yes
- Device tracking: Enabled in Authentik

### Multi-Factor Authentication (MFA)
- Enable in Authentik for all users
- Options: TOTP, WebAuthn, SMS
- Required for sysadmin accounts
- Optional for client users (client decision)

### Permission Isolation
- Authentik policies ensure clients only see their apps
- ERPNext role-based access (Client Administrator role)
- Mailcow domain isolation (separate mailboxes)

### Audit Logging
- Authentik logs all authentication events
- ERPNext logs all user actions
- Mailcow logs all email activity
- Centralized in Grafana/Loki

---

## 📊 SSO Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│           AUTHENTIK SSO SERVER                      │
│        (sso.securenexus.net)                       │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │  Sysadmin   │  │  Dickinson  │  │  Client2   │ │
│  │   Group     │  │   Users     │  │   Users    │ │
│  └─────────────┘  └─────────────┘  └────────────┘ │
│         │                │                 │        │
│         ▼                ▼                 ▼        │
│  ┌─────────────────────────────────────────────┐  │
│  │         OIDC Providers (Apps)               │  │
│  │  - Mailcow Admin                            │  │
│  │  - ERPNext Dickinson                        │  │
│  │  - Webmail Dickinson (Proxy)                │  │
│  │  - ERPNext Client2                          │  │
│  │  - Webmail Client2 (Proxy)                  │  │
│  └─────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   MAILCOW    │  │   ERPNEXT    │  │   ERPNEXT    │
│   (OAuth)    │  │  (Dickinson) │  │   (Client2)  │
│              │  │   (OIDC)     │  │    (OIDC)    │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 🚀 Next Steps

### Immediate (This Week)

1. **Review this plan** - Confirm architecture makes sense
2. **Choose webmail SSO approach** - Proxy vs LDAP vs Separate
3. **Test Authentik OIDC** - Create test provider
4. **Configure Mailcow OAuth** - Test your SSO login

### Short-Term (Next 2 Weeks)

1. **Implement Phase 1** - Your SSO access
2. **Create Dickinson tenant** - Users and policies
3. **Test client SSO** - End-to-end flow

### Long-Term (Next Month)

1. **Add webmail SSO** - Complete integration
2. **Automate client creation** - Update provision script
3. **Document for clients** - User guides

---

## 📚 Additional Documentation Needed

Once we implement, we'll create:

- `docs/AUTHENTIK_SSO_SETUP.md` - Complete Authentik configuration
- `docs/ERPNEXT_SSO_INTEGRATION.md` - ERPNext OIDC setup
- `docs/MAILCOW_SSO_INTEGRATION.md` - Mailcow OAuth configuration
- `docs/CLIENT_SSO_ONBOARDING.md` - Client user management

---

## 💡 Alternative Approaches

### Option 1: SAML Instead of OIDC
- More enterprise-standard
- ERPNext supports SAML
- Authentik supports SAML
- **Downside**: More complex setup

### Option 2: LDAP for Everything
- Authentik has LDAP outpost
- ERPNext can auth via LDAP
- Mailcow can auth via LDAP
- **Downside**: Less secure than OIDC, no SSO flow

### Option 3: Per-Site Authentik Instance
- Each client gets their own Authentik
- Complete isolation
- **Downside**: More resources, harder to manage

**Recommendation**: Stick with OIDC (current plan)

---

## ❓ Questions to Answer

Before implementing, decide:

1. **Webmail SSO priority?**
   - High: Implement proxy/LDAP
   - Low: Keep separate for now

2. **User provisioning?**
   - You create all users?
   - Clients can invite users?
   - Self-service registration?

3. **MFA requirement?**
   - Mandatory for all?
   - Optional for clients?
   - Mandatory for sysadmin only?

4. **Session duration?**
   - Short (8 hours, max security)
   - Medium (24 hours, balance)
   - Long (7 days, convenience)

---

**Let's discuss and start implementing!** 🎯
