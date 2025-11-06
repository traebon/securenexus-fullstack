# SSO-Enabled Webmail Alternatives

## 🎯 The Smart Solution

**Instead of**: Making SOGo work with SSO (complex proxy setup)
**Do this**: Use a webmail client that already supports OAuth/OIDC!

---

## 🔑 Key Insight

You don't need to replace Mailcow! Mailcow is the **EMAIL SERVER** (SMTP, IMAP, spam filtering, etc.).

**Mailcow architecture**:
```
┌─────────────────────────────────────────┐
│           MAILCOW (Keep This!)          │
│                                         │
│  ┌─────────────┐  ┌─────────────┐     │
│  │  Postfix    │  │  Dovecot    │     │
│  │  (SMTP)     │  │  (IMAP)     │     │
│  └─────────────┘  └─────────────┘     │
│                                         │
│  ┌─────────────┐  ┌─────────────┐     │
│  │  Rspamd     │  │  ClamAV     │     │
│  │  (Spam)     │  │  (Virus)    │     │
│  └─────────────┘  └─────────────┘     │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │     SOGo (Webmail Client)       │  │  ← Replace just this!
│  │     - No OAuth support ❌        │  │
│  └─────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**New architecture**:
```
┌─────────────────────────────────────────┐
│           MAILCOW (Same!)               │
│  Postfix, Dovecot, Rspamd, ClamAV      │
└─────────────────────────────────────────┘
                  ↑ IMAP/SMTP
                  │
┌─────────────────────────────────────────┐
│   ROUNDCUBE / SNAPPYMAIL (New!)         │
│   - Native OAuth2/OIDC support ✅       │
│   - Connects to Mailcow IMAP            │
│   - Authentik integration               │
└─────────────────────────────────────────┘
```

---

## 📊 Best SSO-Enabled Webmail Options

### 1. Roundcube ⭐ **RECOMMENDED**

**Official site**: https://roundcube.net/

**Pros**:
- ✅ **Native OAuth2 plugin** available
- ✅ Actively maintained (2023 releases)
- ✅ Lightweight and fast
- ✅ Modern, clean interface
- ✅ Mobile-responsive
- ✅ Huge plugin ecosystem
- ✅ Docker images available
- ✅ Works with any IMAP server

**OAuth Plugin**: https://plugins.roundcube.net/packages/roundcube/oauth2

**Setup complexity**: ⭐⭐ Low-Medium (1-2 hours)

**How it works**:
1. User visits webmail.dickinson.byrne-accounts.org
2. Roundcube redirects to Authentik
3. User logs in to Authentik
4. Authentik sends token to Roundcube
5. Roundcube uses token to get email address
6. Roundcube connects to Mailcow IMAP with stored credentials
7. User sees their email

**Docker deployment**:
```yaml
roundcube:
  image: roundcube/roundcubemail:latest
  environment:
    ROUNDCUBEMAIL_DEFAULT_HOST: ssl://mail.securenexus.net
    ROUNDCUBEMAIL_DEFAULT_PORT: 993
    ROUNDCUBEMAIL_SMTP_SERVER: tls://mail.securenexus.net
    ROUNDCUBEMAIL_SMTP_PORT: 587
    ROUNDCUBEMAIL_PLUGINS: oauth2
  labels:
    - traefik.http.routers.webmail.rule=Host(`webmail.dickinson.byrne-accounts.org`)
```

**Configuration time**: 1-2 hours
**Maintenance**: Low
**User experience**: Excellent

---

### 2. SnappyMail ⭐⭐ **Modern Alternative**

**Official site**: https://snappymail.eu/

**What is it**: Modern fork of RainLoop, actively developed

**Pros**:
- ✅ **Native OIDC support** built-in
- ✅ Very modern, fast interface
- ✅ Mobile-first design
- ✅ Active development (2024 releases)
- ✅ Lightweight (faster than Roundcube)
- ✅ Nice admin panel
- ✅ Docker images available

**Setup complexity**: ⭐⭐ Low-Medium (1-2 hours)

**How it works**: Similar to Roundcube, but with built-in OIDC

**Docker deployment**:
```yaml
snappymail:
  image: djmaze/snappymail:latest
  environment:
    - TZ=Europe/London
  volumes:
    - snappymail-data:/var/lib/snappymail
  labels:
    - traefik.http.routers.webmail.rule=Host(`webmail.dickinson.byrne-accounts.org`)
```

**Configuration**: OIDC settings in admin panel

**Configuration time**: 1-2 hours
**Maintenance**: Low
**User experience**: Excellent (more modern than Roundcube)

---

### 3. Nextcloud Mail (Full Suite)

**Official site**: https://nextcloud.com/

**Pros**:
- ✅ Native OIDC/SAML support
- ✅ Full collaboration suite (files, calendar, contacts, etc.)
- ✅ Enterprise-grade
- ✅ Huge ecosystem

**Cons**:
- ⚠️ Heavy (full Nextcloud stack)
- ⚠️ Overkill if you only need email
- ⚠️ More resources required

**Setup complexity**: ⭐⭐⭐⭐ High (4-6 hours for full Nextcloud)

**Use case**: If you want to offer file storage, calendar, contacts, etc. too

---

### 4. Cypht (Privacy-Focused)

**Official site**: https://cypht.org/

**Pros**:
- ✅ Privacy-focused
- ✅ Supports multiple accounts
- ✅ OAuth support via plugins
- ✅ Lightweight

**Cons**:
- ⚠️ Less mature OAuth implementation
- ⚠️ Smaller community
- ⚠️ Less polished UI

**Setup complexity**: ⭐⭐⭐ Medium (2-3 hours)

---

## 🏆 Recommendation: Roundcube or SnappyMail

### Choose Roundcube if:
- ✅ You want proven, mature solution
- ✅ Large plugin ecosystem important
- ✅ Traditional webmail interface preferred
- ✅ Stable and well-documented

### Choose SnappyMail if:
- ✅ You want modern, sleek interface
- ✅ Speed is important
- ✅ Mobile experience priority
- ✅ Simpler configuration

**Both are excellent choices with native OAuth/OIDC support!**

---

## 🔧 Implementation Plan: Roundcube + Authentik

### Phase 1: Deploy Roundcube (30 min)

**Step 1: Add to compose.yml**

```yaml
services:
  # ... existing services ...

  # Roundcube webmail with OAuth support
  roundcube-dickinson:
    image: roundcube/roundcubemail:latest-apache
    container_name: roundcube-dickinson
    restart: unless-stopped
    networks: [proxy]
    depends_on:
      - roundcube-db
    environment:
      ROUNDCUBEMAIL_DB_TYPE: pgsql
      ROUNDCUBEMAIL_DB_HOST: roundcube-db
      ROUNDCUBEMAIL_DB_NAME: roundcube_dickinson
      ROUNDCUBEMAIL_DB_USER: roundcube
      ROUNDCUBEMAIL_DB_PASSWORD_FILE: /run/secrets/roundcube_db_password

      # Mailcow IMAP/SMTP settings
      ROUNDCUBEMAIL_DEFAULT_HOST: ssl://mail.securenexus.net
      ROUNDCUBEMAIL_DEFAULT_PORT: 993
      ROUNDCUBEMAIL_SMTP_SERVER: tls://mail.securenexus.net
      ROUNDCUBEMAIL_SMTP_PORT: 587
      ROUNDCUBEMAIL_SMTP_AUTH_TYPE: LOGIN

      # Enable OAuth plugin
      ROUNDCUBEMAIL_PLUGINS: oauth2,archive,zipdownload

      # Site config
      ROUNDCUBEMAIL_SUPPORT_URL: https://erp.byrne-accounts.org/support
      ROUNDCUBEMAIL_PRODUCT_NAME: Dickinson Email
    secrets:
      - roundcube_db_password
    volumes:
      - ./roundcube/config:/var/roundcube/config:ro
      - roundcube-dickinson-data:/var/www/html
    labels:
      - traefik.enable=true
      - traefik.http.routers.roundcube-dickinson.rule=Host(`webmail.dickinson.byrne-accounts.org`)
      - traefik.http.routers.roundcube-dickinson.entrypoints=websecure
      - traefik.http.routers.roundcube-dickinson.tls.certresolver=le
      - traefik.http.services.roundcube-dickinson.loadbalancer.server.port=80

  # Database for Roundcube
  roundcube-db:
    image: postgres:15-alpine
    container_name: roundcube-db
    restart: unless-stopped
    networks: [proxy]
    environment:
      POSTGRES_DB: roundcube_dickinson
      POSTGRES_USER: roundcube
      POSTGRES_PASSWORD_FILE: /run/secrets/roundcube_db_password
    secrets:
      - roundcube_db_password
    volumes:
      - roundcube-db-data:/var/lib/postgresql/data

volumes:
  roundcube-dickinson-data:
  roundcube-db-data:

secrets:
  roundcube_db_password:
    file: ./secrets/roundcube_db_password.txt
```

**Step 2: Generate secrets**

```bash
openssl rand -base64 32 > secrets/roundcube_db_password.txt
chmod 600 secrets/roundcube_db_password.txt
```

**Step 3: Start Roundcube**

```bash
docker compose up -d roundcube-dickinson roundcube-db
```

---

### Phase 2: Configure OAuth2 Plugin (30 min)

**Step 1: Create OAuth config**

```bash
mkdir -p roundcube/config
cat > roundcube/config/oauth2.inc.php <<'EOF'
<?php
$config['oauth_provider'] = 'authentik';
$config['oauth_provider_name'] = 'Authentik';
$config['oauth_client_id'] = 'roundcube-dickinson';
$config['oauth_client_secret'] = 'YOUR_CLIENT_SECRET';
$config['oauth_auth_uri'] = 'https://sso.securenexus.net/application/o/authorize/';
$config['oauth_token_uri'] = 'https://sso.securenexus.net/application/o/token/';
$config['oauth_identity_uri'] = 'https://sso.securenexus.net/application/o/userinfo/';
$config['oauth_scope'] = 'openid email profile';
$config['oauth_identity_fields'] = array('email');
$config['oauth_login_redirect'] = true;
?>
EOF
```

---

### Phase 3: Configure Authentik (30 min)

**Step 1: Create OAuth2 Provider in Authentik**

1. Login to Authentik: https://sso.securenexus.net
2. Applications → Providers → Create
3. Select: OAuth2/OpenID Provider
4. Fill in:
   ```
   Name: Roundcube Dickinson
   Authorization flow: default-authentication-flow
   Client type: Confidential
   Client ID: roundcube-dickinson
   Client Secret: [Generate and save]
   Redirect URIs:
     https://webmail.dickinson.byrne-accounts.org/index.php/login/oauth
   Scopes: openid, email, profile
   ```
5. Save

**Step 2: Create Application**

1. Applications → Applications → Create
2. Fill in:
   ```
   Name: Dickinson Webmail
   Slug: dickinson-webmail
   Provider: Roundcube Dickinson (from above)
   Policy engine mode: ANY
   ```
3. Save

**Step 3: Assign to Users/Groups**

1. Go to application → Policy Bindings
2. Add binding to "Dickinson Users" group
3. Save

---

### Phase 4: User Mapping (30 min)

**Challenge**: Roundcube needs to know the IMAP password

**Solution 1: Store in Authentik User Attributes** (Recommended)

1. In Authentik user profile, add custom attribute:
   ```json
   {
     "email_password": "user_email_password_here"
   }
   ```

2. Roundcube OAuth plugin retrieves this and uses for IMAP login

**Solution 2: Use Master Password** (If Mailcow supports it)

Configure Mailcow with master password feature, Roundcube uses that

**Solution 3: Password Sync** (Advanced)

When user changes Authentik password, webhook updates Mailcow password

---

### Phase 5: Test & Deploy (30 min)

**Test login flow**:

1. Visit: https://webmail.dickinson.byrne-accounts.org
2. Should redirect to Authentik
3. Login with Authentik credentials
4. Should redirect back to Roundcube
5. Should see email inbox

**Troubleshooting**:
- Check Roundcube logs: `docker compose logs roundcube-dickinson`
- Check Authentik logs: Authentik UI → System → Logs
- Verify OAuth config: `cat roundcube/config/oauth2.inc.php`

---

## 📊 Comparison: SOGo vs Roundcube vs SnappyMail

| Feature | SOGo (Current) | Roundcube | SnappyMail |
|---------|----------------|-----------|------------|
| **Native OAuth/OIDC** | ❌ No | ✅ Via plugin | ✅ Built-in |
| **SSO Complexity** | ⭐⭐⭐⭐⭐ High | ⭐⭐ Low | ⭐⭐ Low |
| **Setup Time** | Proxy: 3hrs | 1-2 hours | 1-2 hours |
| **Maintenance** | Medium | Low | Low |
| **Interface** | Traditional | Traditional | Modern |
| **Mobile** | Good | Good | Excellent |
| **Speed** | Fast | Fast | Very Fast |
| **Resources** | Medium | Low | Very Low |
| **Calendar Integration** | ✅ Excellent | ⚠️ Plugin | ⚠️ Plugin |
| **Contacts Integration** | ✅ Excellent | ⚠️ Plugin | ⚠️ Plugin |
| **Active Development** | Slowing | Active | Very Active |

---

## 🎯 Migration Strategy

### Option A: Replace SOGo Completely

**Pros**:
- Clean, single webmail client
- Simpler architecture
- Lower resource usage

**Cons**:
- Need to migrate existing users
- Lose calendar/contacts integration

**Steps**:
1. Deploy Roundcube alongside SOGo
2. Test with pilot users
3. Migrate all users
4. Disable SOGo in Mailcow

### Option B: Offer Both (Recommended for Testing)

**Pros**:
- Zero disruption
- Users can choose
- Easy rollback

**Cons**:
- Slight resource overhead

**Setup**:
- SOGo: `mail.securenexus.net` (existing)
- Roundcube: `webmail.dickinson.byrne-accounts.org` (new)

Test Roundcube, then migrate when confident.

---

## 🚀 Quick Start: SnappyMail (Simpler)

If you want the absolute simplest SSO webmail:

```bash
# 1. Add to compose.yml
cat >> compose.yml <<EOF
  snappymail-dickinson:
    image: djmaze/snappymail:latest
    container_name: snappymail-dickinson
    restart: unless-stopped
    networks: [proxy]
    volumes:
      - snappymail-data:/var/lib/snappymail
    labels:
      - traefik.enable=true
      - traefik.http.routers.snappymail.rule=Host(\`webmail.dickinson.byrne-accounts.org\`)
      - traefik.http.routers.snappymail.entrypoints=websecure
      - traefik.http.routers.snappymail.tls.certresolver=le
      - traefik.http.services.snappymail.loadbalancer.server.port=8888

volumes:
  snappymail-data:
EOF

# 2. Start it
docker compose up -d snappymail-dickinson

# 3. Access admin: https://webmail.dickinson.byrne-accounts.org/?admin
# 4. Configure OIDC in admin panel
# 5. Done!
```

SnappyMail has OIDC settings built into the admin panel UI.

---

## 💡 Recommendation

**For your use case**:

1. **Deploy Roundcube or SnappyMail** (1-2 hours)
   - Clean, simple solution
   - Native OAuth support
   - Keep Mailcow (just replace webmail client)

2. **Skip SOGo proxy workaround** (saves 2-3 hours)
   - More complex
   - More to maintain
   - Not worth it when alternatives exist

3. **Test alongside SOGo** (no disruption)
   - Deploy new webmail for Dickinson
   - Test with your account first
   - Migrate when satisfied

**Total time**: 1-2 hours vs 3-4 hours for SOGo proxy
**Result**: Better solution, less complexity, easier maintenance

---

## 📝 Next Steps

**Choose your webmail**:
- [ ] **Roundcube** - Mature, proven, traditional UI
- [ ] **SnappyMail** - Modern, fast, sleek UI

**Then I'll help you**:
1. Add to docker compose
2. Configure OAuth with Authentik
3. Set up for Dickinson site
4. Test login flow
5. Deploy!

**Which one appeals to you more?** 🎯
