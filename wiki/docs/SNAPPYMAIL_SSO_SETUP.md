# SnappyMail SSO Setup Guide

## 🎯 What We're Building

**Goal**: Deploy SnappyMail webmail with Authentik SSO integration

**Architecture**:
```
User → Authentik (SSO) → SnappyMail → Mailcow IMAP
```

**Result**:
- Login once to Authentik
- Access webmail automatically
- Read/send email via Mailcow

---

## 🚀 Step-by-Step Implementation

### Step 1: Add SnappyMail to Docker Compose (5 min)

We'll add SnappyMail to your existing stack. It will be available at `webmail.dickinson.byrne-accounts.org`.

**Configuration added to compose.yml**:
- SnappyMail container
- Traefik routing
- SSL certificate automation

---

### Step 2: Start SnappyMail (2 min)

```bash
docker compose up -d snappymail-dickinson
```

**Initial access**:
- **User interface**: https://webmail.dickinson.byrne-accounts.org
- **Admin interface**: https://webmail.dickinson.byrne-accounts.org/?admin

**Default admin credentials**: `admin` / `12345` (change immediately!)

---

### Step 3: Configure SnappyMail Admin (10 min)

#### 3.1: Login to Admin Panel

1. Visit: https://webmail.dickinson.byrne-accounts.org/?admin
2. Login: `admin` / `12345`
3. **Immediately change password**: Security → Admin Password → Set new secure password

#### 3.2: Configure Mailcow IMAP Connection

1. **Go to**: Domains → Add Domain
2. **Fill in**:
   ```
   IMAP Server: mail.securenexus.net
   IMAP Port: 993
   IMAP Security: SSL/TLS
   IMAP Short Login: No

   SMTP Server: mail.securenexus.net
   SMTP Port: 587
   SMTP Security: STARTTLS
   SMTP Authentication: Yes
   SMTP Short Login: No
   ```
3. **Test connection**: Click "Test" button
4. **Save**

#### 3.3: Set Domain as Default

1. Check "Use this domain by default"
2. Save

---

### Step 4: Configure Authentik OIDC Provider (15 min)

#### 4.1: Create OAuth2 Provider in Authentik

1. **Login to**: https://sso.securenexus.net
2. **Go to**: Applications → Providers
3. **Click**: Create
4. **Select**: OAuth2/OpenID Provider
5. **Fill in**:
   ```
   Name: SnappyMail Dickinson
   Authentication flow: default-authentication-flow (implicit)
   Authorization flow: default-provider-authorization-implicit-consent (implicit)

   Client type: Confidential
   Client ID: snappymail-dickinson
   Client Secret: [Click Generate - SAVE THIS!]

   Redirect URIs/Origins (RegEx):
   https://webmail\.dickinson\.byrne-accounts\.org/.*

   Signing Key: authentik Self-signed Certificate

   Scopes:
   - openid
   - email
   - profile

   Subject mode: Based on the User's Email
   ```
6. **Click**: Create

#### 4.2: Create Application

1. **Go to**: Applications → Applications
2. **Click**: Create
3. **Fill in**:
   ```
   Name: Dickinson Webmail
   Slug: dickinson-webmail
   Provider: SnappyMail Dickinson (from above)
   Launch URL: https://webmail.dickinson.byrne-accounts.org
   ```
4. **Click**: Create

#### 4.3: Assign to Users/Group

1. **Go to**: Application → Policy / Group / User Bindings
2. **Click**: Bind existing policy
3. **Select**: "Dickinson Users" group (or specific users)
4. **Order**: 0
5. **Click**: Create

---

### Step 5: Configure SnappyMail OIDC (10 min)

#### 5.1: Enable OpenID Connect in SnappyMail

1. **Go to**: SnappyMail Admin → Security
2. **Find**: "OpenID Connect" section
3. **Enable**: "Allow OpenID Connect authentication"

#### 5.2: Configure OIDC Settings

1. **In SnappyMail Admin → Security → OpenID Connect**:
   ```
   Provider Name: Authentik

   Provider URL (Discovery):
   https://sso.securenexus.net/application/o/snappymail-dickinson/.well-known/openid-configuration

   Client ID: snappymail-dickinson
   Client Secret: [Your secret from Step 4.1]

   Scopes: openid email profile

   Force OpenID Connect login: No (allows fallback to password)
   ```

2. **Click**: Save

#### 5.3: Test OIDC Connection

1. Click "Test OIDC Configuration" button
2. Should show: "✓ Successfully connected to Authentik"

---

### Step 6: Configure User Mapping (10 min)

**Challenge**: SnappyMail needs to know:
- Email address (from Authentik)
- IMAP password (to connect to Mailcow)

**Solutions**:

#### Option A: Master Password (Recommended for Testing)

SnappyMail can use a "master password" to connect to all mailboxes:

1. **In SnappyMail Admin → Security**:
   ```
   Master Password: [Strong password for IMAP access]
   ```

2. **In Mailcow**: Create a master/admin account that can access all mailboxes
   - OR: Use individual mailbox passwords

**For testing**: Use the mailbox password directly

#### Option B: Store Passwords in Authentik (Production)

Store IMAP password as user attribute in Authentik:

1. **In Authentik → Directory → Users**
2. **Select user** → Attributes
3. **Add**:
   ```json
   {
     "imap_password": "user_mailbox_password"
   }
   ```

4. **In SnappyMail**: Configure to read from OIDC claim

#### Option C: Synchronized Passwords (Advanced)

When user changes password in Authentik → Webhook updates Mailcow password

**For now**: Use **Option A** (simple, works immediately)

---

### Step 7: Test SSO Login (5 min)

#### 7.1: Logout of All Sessions

1. Logout of Authentik
2. Close all browser tabs

#### 7.2: Test Login Flow

1. **Visit**: https://webmail.dickinson.byrne-accounts.org

2. **Should see**: "Login with Authentik" button (or auto-redirect)

3. **Click**: Login with Authentik

4. **Redirected to**: https://sso.securenexus.net

5. **Login with**:
   - User: admin@dickinson.byrne-accounts.org
   - Password: [Authentik password]

6. **First time**: Accept permissions prompt

7. **Redirected back to**: SnappyMail

8. **Should see**: Email inbox! ✅

#### 7.3: Verify Email Access

1. Check you can read emails
2. Try composing and sending a test email
3. Verify sent mail appears

---

## 🔧 Configuration Files

### SnappyMail Admin Settings Export

After configuration, export settings:

```bash
# Backup SnappyMail configuration
docker compose exec snappymail-dickinson cat /var/lib/snappymail/data/_data_/_default_/configs/application.ini > snappymail-config-backup.ini
```

Store this securely for disaster recovery.

---

## 🎨 Customization (Optional)

### Branding

1. **In SnappyMail Admin → Branding**:
   ```
   Application Name: Dickinson Email
   Logo URL: https://dickinson.byrne-accounts.org/logo.png
   Support URL: https://erp.byrne-accounts.org/support
   ```

### Theme

1. **In SnappyMail Admin → Appearance**:
2. Select theme: Modern, Dark, or Custom

### Languages

1. **In SnappyMail Admin → General**:
2. Set default language for users

---

## 🔐 Security Hardening

### 1. Disable Password Login (After SSO Works)

Once SSO is working perfectly:

1. **In SnappyMail Admin → Security**:
2. **Enable**: "Force OpenID Connect login"
3. **Result**: Users MUST use Authentik (can't bypass with password)

### 2. Enable Admin 2FA

1. **In SnappyMail Admin → Security**:
2. **Enable**: Two-factor authentication for admin
3. Scan QR code with authenticator app

### 3. IP Allowlist for Admin (Optional)

1. **In SnappyMail Admin → Security**:
2. **Admin IP allowlist**: Add your VPN IP range
3. Only accessible from Tailscale VPN

### 4. Session Timeout

1. **In SnappyMail Admin → Security**:
2. **Session timeout**: 24 hours (matches Authentik)
3. **Idle timeout**: 4 hours

---

## 🧪 Testing Checklist

### Basic Functionality
- [ ] SnappyMail loads at webmail.dickinson.byrne-accounts.org
- [ ] SSL certificate valid (Let's Encrypt)
- [ ] Admin panel accessible at /?admin
- [ ] IMAP connection to Mailcow works
- [ ] SMTP connection to Mailcow works

### SSO Integration
- [ ] "Login with Authentik" button appears
- [ ] Redirect to Authentik works
- [ ] Login with Authentik credentials works
- [ ] Redirect back to SnappyMail works
- [ ] Email inbox loads after SSO login
- [ ] Can read emails
- [ ] Can send emails
- [ ] Logout from SnappyMail works
- [ ] Logout from Authentik logs out of SnappyMail

### Multi-User
- [ ] Create second test user in Authentik
- [ ] Assign to Dickinson group
- [ ] Test SSO login with second user
- [ ] Verify isolation (users see only their email)

---

## 🐛 Troubleshooting

### Issue: "Login with Authentik" button not showing

**Check**:
1. OIDC enabled in SnappyMail admin
2. Client ID and secret correct
3. Discovery URL correct
4. Check SnappyMail logs:
   ```bash
   docker compose logs snappymail-dickinson | grep -i oidc
   ```

### Issue: OIDC redirect fails

**Check**:
1. Redirect URI in Authentik matches:
   `https://webmail.dickinson.byrne-accounts.org/.*`
2. RegEx format (not plain URL)
3. Check Authentik system logs

### Issue: Login succeeds but no emails show

**Check**:
1. IMAP credentials correct in SnappyMail domain config
2. Test IMAP manually:
   ```bash
   openssl s_client -connect mail.securenexus.net:993 -crlf
   # Then: A1 LOGIN admin@dickinson.byrne-accounts.org password
   ```
3. Check Mailcow Dovecot logs:
   ```bash
   cd mail/mailcow-dockerized
   docker compose logs dovecot-mailcow | tail -50
   ```

### Issue: Can't send emails

**Check**:
1. SMTP settings in SnappyMail domain config
2. Port 587 open and accessible
3. Check Mailcow Postfix logs:
   ```bash
   cd mail/mailcow-dockerized
   docker compose logs postfix-mailcow | tail -50
   ```

### Issue: SSL certificate error

**Check**:
1. DNS resolves correctly: `dig webmail.dickinson.byrne-accounts.org +short`
2. Traefik logs: `docker compose logs traefik | grep webmail`
3. Wait 2 minutes for Let's Encrypt certificate issuance

---

## 🔄 Adding More Clients

For each new client, repeat:

### 1. Deploy SnappyMail Instance

```yaml
snappymail-client2:
  image: djmaze/snappymail:latest
  container_name: snappymail-client2
  # ... same config, different domain
  labels:
    - traefik.http.routers.snappymail-client2.rule=Host(`webmail.client2.byrne-accounts.org`)
```

### 2. Create Authentik Provider

- Provider: `snappymail-client2`
- Redirect: `https://webmail.client2.byrne-accounts.org/.*`

### 3. Configure OIDC in SnappyMail

Same process, different credentials

### Alternative: Multi-Tenant (Advanced)

One SnappyMail instance, multiple domains:

1. SnappyMail admin → Domains → Add each client domain
2. One Authentik provider with multiple redirect URIs
3. SnappyMail detects domain from URL

**Pro**: Less containers
**Con**: Shared admin, more complex

---

## 📊 Resource Usage

**SnappyMail per instance**:
- **Memory**: ~50-100MB
- **CPU**: Minimal (only during use)
- **Disk**: ~20MB + data
- **Network**: Minimal

**Scaling**:
- 10 clients = ~1GB RAM total
- 50 clients = ~5GB RAM total
- Lightweight compared to SOGo

---

## 🎯 Next Steps After Setup

### 1. Train Users

Create guide for clients:
- How to access webmail
- SSO login process
- Basic email functions

### 2. Monitor Usage

Check logs periodically:
```bash
docker compose logs snappymail-dickinson | tail -100
```

### 3. Backup Configuration

Regular backups:
```bash
# Backup SnappyMail data
docker run --rm -v snappymail-dickinson-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/snappymail-dickinson-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### 4. Update Regularly

```bash
docker compose pull snappymail-dickinson
docker compose up -d snappymail-dickinson
```

---

## 📚 Additional Resources

- **SnappyMail Docs**: https://snappymail.eu/
- **SnappyMail GitHub**: https://github.com/the-djmaze/snappymail
- **Authentik OIDC Docs**: https://docs.goauthentik.io/docs/providers/oauth2/
- **Mailcow Docs**: https://docs.mailcow.email/

---

## 🎉 Success Criteria

You'll know it's working when:

✅ Visit webmail.dickinson.byrne-accounts.org
✅ Click "Login with Authentik" (or auto-redirect)
✅ Login to Authentik once
✅ Automatically see email inbox
✅ Can read and send emails
✅ Logout from one = logout from all
✅ Users can't bypass SSO
✅ Multiple users work independently

---

**Ready to deploy! Let's add SnappyMail to your compose.yml now.** 🚀
