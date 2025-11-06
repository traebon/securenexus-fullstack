# Why Webmail SSO Is More Complex

## TL;DR

**ERPNext SSO**: Built-in OIDC support ✅ Easy
**Mailcow/SOGo SSO**: No native OIDC support ❌ Requires workarounds

---

## 🔍 The Technical Differences

### ERPNext (Easy SSO)

**How it works**:
```
1. User clicks "Login with Authentik"
2. ERPNext redirects to Authentik (OIDC standard flow)
3. User logs in to Authentik
4. Authentik sends token back to ERPNext
5. ERPNext validates token and creates session
6. User is logged in
```

**Why it's easy**:
- ✅ ERPNext has built-in OIDC support (native feature)
- ✅ Just configure OAuth provider in settings
- ✅ Standard OAuth2/OIDC protocol
- ✅ 15-minute configuration

---

### Mailcow/SOGo (Complex SSO)

**The problem**:
SOGo (the webmail component) **does NOT have native OIDC/OAuth2 support**.

**How SOGo normally authenticates**:
```
1. User enters: username@domain.com + password
2. SOGo checks password against:
   - Dovecot IMAP server
   - Or MySQL database
   - Or LDAP directory
3. If correct, creates session
4. User is logged in
```

Notice: **No OAuth/OIDC flow** - it expects a username/password directly.

---

## 🛠️ The Workarounds (3 Options)

### Option 1: Authentik Proxy (Medium Complexity)

**How it works**:
```
                    ┌─────────────────┐
User visits    →    │ Traefik         │
webmail.domain      │ (checks auth)   │
                    └─────────────────┘
                           ↓
                    ┌─────────────────┐
Not logged in  →    │ Authentik       │
                    │ (login page)    │
                    └─────────────────┘
                           ↓
                    ┌─────────────────┐
Logged in      →    │ Authentik Proxy │
                    │ (adds headers)  │
                    └─────────────────┘
                           ↓
                    ┌─────────────────┐
Access granted →    │ SOGo Webmail    │
                    │ (trusts proxy)  │
                    └─────────────────┘
```

**What you need to do**:
1. Deploy Authentik Forward Auth addon
2. Configure Traefik middleware to check auth
3. Configure SOGo to trust the proxy headers
4. Map Authentik user to email account

**Complexity**: Medium
- Requires additional component (forward auth)
- Need to configure SOGo to trust proxy
- Session management between systems
- **Estimated time**: 2-3 hours

**Pros**:
- ✅ True SSO - login to Authentik = access webmail
- ✅ No password stored in webmail
- ✅ Centralized user management

**Cons**:
- ⚠️ Adds complexity (proxy layer)
- ⚠️ If proxy fails, webmail inaccessible
- ⚠️ Need to map Authentik users to email accounts

---

### Option 2: LDAP Backend (High Complexity)

**How it works**:
```
1. Enable Authentik LDAP outpost
2. Configure Dovecot to authenticate against Authentik LDAP
3. SOGo uses Dovecot for auth
4. Authentik becomes source of truth for passwords
```

**What changes**:
- Email passwords = Authentik passwords
- User changes password in Authentik → Email password changes
- Single source of truth

**Complexity**: High
- Requires LDAP setup in Authentik
- Configure Dovecot LDAP auth
- Configure SOGo LDAP lookup
- Password sync mechanisms
- **Estimated time**: 4-6 hours

**Pros**:
- ✅ Single password for everything
- ✅ Centralized user database
- ✅ Password policies enforced

**Cons**:
- ⚠️ Still not true SSO (need to enter password)
- ⚠️ Complex LDAP configuration
- ⚠️ More moving parts
- ⚠️ Dovecot/SOGo need restart if Authentik down

---

### Option 3: Keep Separate (Low Complexity)

**How it works**:
```
1. User logs into ERPNext via Authentik SSO ✅
2. User logs into POS (same session) ✅
3. User logs into Webmail with separate password ⚠️
```

**What this means**:
- ERPNext = SSO
- Webmail = Traditional username/password
- Browser auto-fills password anyway

**Complexity**: None (current state)
- No additional configuration needed
- **Estimated time**: 0 hours

**Pros**:
- ✅ Zero complexity
- ✅ Nothing to break
- ✅ Browser remembers webmail password
- ✅ Can upgrade to SSO later

**Cons**:
- ⚠️ User needs 2 passwords (Authentik + Email)
- ⚠️ Not true single sign-on
- ⚠️ Password reset in 2 places

---

## 🤔 Why The Complexity?

### Technical Reason

**ERPNext** is a modern web application built with SSO in mind:
- Framework: Python/Frappe (2010s)
- Auth: OAuth2/OIDC native support
- Architecture: Stateless token-based auth

**SOGo** is a traditional groupware server:
- Framework: Objective-C (2000s)
- Auth: Username/password + IMAP/LDAP
- Architecture: Session-based auth expecting direct credentials

### Historical Context

When SOGo was designed (early 2000s):
- OAuth didn't exist yet
- OIDC didn't exist yet
- Standard was: username/password against mail server
- Or: LDAP directory for enterprises

Modern SSO came later, but SOGo hasn't been updated to support it natively.

---

## 📊 Comparison Table

| Aspect | ERPNext SSO | Webmail SSO (Proxy) | Webmail SSO (LDAP) | Webmail Separate |
|--------|------------|---------------------|-------------------|------------------|
| Setup Time | 15 min | 2-3 hours | 4-6 hours | 0 min |
| Complexity | Low | Medium | High | None |
| True SSO | ✅ Yes | ✅ Yes | ⚠️ No* | ❌ No |
| Single Password | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| Additional Components | None | Forward Auth | LDAP Outpost | None |
| Failure Points | Low | Medium | High | Low |
| User Experience | Excellent | Excellent | Good | Good |
| Maintenance | Low | Medium | High | Low |

*LDAP = Single password but still need to enter it (not true SSO)

---

## 💡 Real-World Impact

### Scenario: Client Employee's Day

**With ERPNext SSO + Separate Webmail**:
```
8:00 AM - Arrive at work
8:01 AM - Visit dickinson.byrne-accounts.org
8:02 AM - Click "Login with Authentik"
8:03 AM - Enter: john@dickinson + password
8:04 AM - Access ERPNext ✅
8:05 AM - Click POS link
8:06 AM - Auto-logged into POS ✅
8:07 AM - Click Webmail link
8:08 AM - Enter: john@dickinson + email_password
8:09 AM - Access webmail ✅
         (Browser remembers for next time)
```

**Impact**: ONE extra password entry on first webmail access.

**With Full SSO (Proxy method)**:
```
8:00 AM - Arrive at work
8:01 AM - Visit dickinson.byrne-accounts.org
8:02 AM - Click "Login with Authentik"
8:03 AM - Enter: john@dickinson + password
8:04 AM - Access ERPNext ✅
8:05 AM - Click POS link
8:06 AM - Auto-logged into POS ✅
8:07 AM - Click Webmail link
8:08 AM - Auto-logged into webmail ✅
```

**Benefit**: Saves 2 seconds and one password to remember.

---

## 🎯 Recommendation

**For most deployments**: Start with **Option 3 (Separate)**

**Why**:
1. **Immediate deployment** - No SSO setup delays
2. **Still convenient** - Browser remembers webmail password
3. **Zero risk** - Nothing to break
4. **Upgrade path** - Can add SSO later if needed

**When to use Proxy (Option 1)**:
- Client specifically requests full SSO
- High-security environment (no stored passwords)
- Large team (50+ users)
- Worth the 2-3 hour setup

**When to use LDAP (Option 2)**:
- Client has existing LDAP/AD infrastructure
- Enterprise deployment
- Advanced use case

---

## 🔧 If You Want Full Webmail SSO

I can absolutely help you set it up! Here's what we'd do:

### Using Authentik Proxy (Recommended)

**Steps**:
1. Deploy Authentik Forward Auth (15 min)
2. Create Traefik middleware (10 min)
3. Configure SOGo trust headers (30 min)
4. Set up user mapping (30 min)
5. Test login flow (30 min)
6. **Total**: ~2 hours

**Result**:
- Click webmail → Check Authentik → Auto-login ✅

### Configuration Preview

**Traefik labels** (compose.yml):
```yaml
labels:
  - traefik.http.routers.dickinson-webmail.rule=Host(`webmail.dickinson.byrne-accounts.org`)
  - traefik.http.routers.dickinson-webmail.middlewares=authentik-dickinson@file
  - traefik.http.middlewares.authentik-dickinson.forwardauth.address=http://authentik-proxy:9000/outpost.goauthentik.io/auth/traefik
  - traefik.http.middlewares.authentik-dickinson.forwardauth.trustForwardHeader=true
```

**SOGo config** (mailcow):
```
SOGoTrustProxyAuthentication = YES;
SOGoProxyAuthHeader = "X-Authentik-Username";
```

**Authentik app**:
- Provider: Proxy Provider
- External host: webmail.dickinson.byrne-accounts.org
- Authorization flow: Dickinson Users only

---

## 📝 Decision Time

**Questions for you**:

1. **How important is webmail SSO?**
   - Critical (worth 2-3 hours)?
   - Nice to have (maybe later)?
   - Don't care (separate is fine)?

2. **How many users will use webmail?**
   - Just a few → Separate passwords fine
   - Dozens → SSO more valuable
   - Hundreds → SSO strongly recommended

3. **What's the priority?**
   - Get Dickinson site launched fast → Skip webmail SSO for now
   - Perfect SSO experience → Implement full SSO

**My recommendation**:
- **Phase 1**: Launch with separate webmail (this week)
- **Phase 2**: Add ERPNext SSO (next week)
- **Phase 3**: Add webmail SSO if needed (later)

This gets you 90% of the benefit with 10% of the complexity!

---

## 🚀 Next Steps

**If you want separate webmail** (simple):
→ Nothing to do! Already works. Move forward with ERPNext SSO.

**If you want full webmail SSO** (complex):
→ Tell me, and I'll guide you through the Authentik Proxy setup.

What do you prefer? 🤔
