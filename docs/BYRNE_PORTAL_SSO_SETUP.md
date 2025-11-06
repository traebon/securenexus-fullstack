# Byrne Accounting Client Portal - SSO Setup Guide

Complete guide for setting up Authentik OAuth integration with the Byrne Accounting client portal.

## Overview

The client portal (`portal.byrne-accounts.org`) uses Authentik for SSO authentication, allowing clients to securely access their applications (ERPNext, POS Awesome, Webmail) through a unified dashboard.

## Prerequisites

- Authentik instance running at `auth.byrne-accounts.org`
- Admin access to Authentik
- Portal files deployed in `byrne-website/` directory
- Traefik configured and running

---

## Part 1: Create OAuth Provider in Authentik

### Step 1: Login to Authentik Admin

1. Navigate to `https://auth.byrne-accounts.org`
2. Login with admin credentials
3. Go to **Admin Interface** (top right)

### Step 2: Create Provider

1. Navigate to **Applications** → **Providers**
2. Click **Create** button
3. Select **OAuth2/OpenID Provider**

### Step 3: Configure Provider Settings

**Basic Settings**:
- **Name**: `Byrne Portal OAuth Provider`
- **Authentication flow**: `default-authentication-flow` (or your custom flow)
- **Authorization flow**: `default-provider-authorization-explicit-consent`

**Protocol Settings**:
- **Client type**: `Confidential`
- **Client ID**: `byrne-portal` (must match `portal.js` CONFIG.authentik.clientId)
- **Client Secret**: Auto-generated (copy this for later, though not needed for authorization code flow)
- **Redirect URIs/Origins (CORS)**:
  ```
  https://portal.byrne-accounts.org/portal.html
  https://byrne-accounts.org/portal.html
  http://localhost:8080/portal.html
  ```
  (Add one per line, include localhost for testing)

**Scopes**:
Select the following scopes:
- ✅ `openid`
- ✅ `profile`
- ✅ `email`
- ✅ `groups` (required for app access control)

**Advanced Settings**:
- **Token validity**: `hours=1` (access token expiry)
- **Include claims in ID token**: ✅ Enabled
- **Issuer mode**: `Per Provider` (recommended)

### Step 4: Save Provider

Click **Create** to save the provider.

---

## Part 2: Create Application in Authentik

### Step 1: Create Application

1. Navigate to **Applications** → **Applications**
2. Click **Create** button

### Step 2: Configure Application

**Basic Settings**:
- **Name**: `Byrne Client Portal`
- **Slug**: `byrne-portal` (must match provider configuration)
- **Group**: Leave blank or create "Byrne Services" group
- **Provider**: Select `Byrne Portal OAuth Provider` (created in Part 1)

**UI Settings**:
- **Launch URL**: `https://portal.byrne-accounts.org/portal.html`
- **Icon**: Upload custom icon or leave blank
- **Description**: "Secure client portal for accessing ERPNext, POS Awesome, and Webmail"

**Advanced Settings**:
- **Open in new tab**: ✅ Enabled (recommended)

### Step 3: Save Application

Click **Create** to save the application.

---

## Part 3: Configure User Groups for App Access

The portal shows apps based on user group membership. Create these groups in Authentik:

### Required Groups

1. **erp-users**
   - Purpose: Access to ERPNext
   - Members: All clients who need accounting system access

2. **pos-users**
   - Purpose: Access to POS Awesome
   - Members: Clients with point-of-sale needs

3. **mail-users**
   - Purpose: Access to Webmail (SOGo)
   - Members: All clients who need email access

4. **company-[clientname]** (optional)
   - Purpose: Identify user's company
   - Example: `company-dickinson-supplies`
   - Used to display company name in portal

5. **admin** (optional)
   - Purpose: Mark administrators
   - Displays "Administrator" access level in portal

6. **manager** (optional)
   - Purpose: Mark managers
   - Displays "Manager" access level in portal

### Creating Groups

1. Navigate to **Directory** → **Groups**
2. Click **Create** button
3. For each group:
   - **Name**: Use exact names above (e.g., `erp-users`)
   - **Parent**: Leave blank
   - **Members**: Add users who should have access
   - **Attributes**: Leave default

---

## Part 4: Assign Users to Groups

### Step 1: Create or Edit Users

1. Navigate to **Directory** → **Users**
2. Select a user or click **Create** for new user

### Step 2: Assign Groups

In the user edit screen:
1. Scroll to **Groups** section
2. Select appropriate groups:
   - Add to `erp-users` if they need ERPNext access
   - Add to `pos-users` if they need POS access
   - Add to `mail-users` if they need email access
   - Add to `company-[name]` to set their company name
   - Add to `admin` or `manager` for elevated access level display

### Example User Configuration

**User**: John Smith (Dickinson Supplies)
- **Groups**:
  - `erp-users` ✅
  - `pos-users` ✅
  - `mail-users` ✅
  - `company-dickinson-supplies` ✅

**Result**: John will see ERPNext, POS Awesome, Webmail, and Service Portal in his dashboard.

---

## Part 5: Update Portal JavaScript Configuration

If you used a different domain or client ID, update `byrne-website/assets/js/portal.js`:

```javascript
const CONFIG = {
    authentik: {
        baseUrl: 'https://auth.byrne-accounts.org',  // Your Authentik URL
        clientId: 'byrne-portal',                     // Must match Provider Client ID
        redirectUri: `${window.location.origin}/portal.html`,
        scope: 'openid profile email groups'
    },
    // ... rest of config
};
```

---

## Part 6: Configure Traefik Routing

### Step 1: Add Portal Route to Traefik

Edit `compose.yml` and add labels to the `landing` service (or create new service for portal):

```yaml
services:
  landing:
    image: nginx:alpine
    labels:
      # ... existing labels ...

      # Client Portal
      - traefik.http.routers.portal.rule=Host(`portal.byrne-accounts.org`)
      - traefik.http.routers.portal.entrypoints=websecure
      - traefik.http.routers.portal.tls=true
      - traefik.http.routers.portal.tls.certresolver=letsencrypt
      - traefik.http.routers.portal.service=portal
      - traefik.http.services.portal.loadbalancer.server.port=80
```

### Step 2: Update DNS

Add A record for `portal.byrne-accounts.org` pointing to your server IP.

### Step 3: Deploy Changes

```bash
cd /home/tristian/securenexus-fullstack
docker compose up -d landing
```

---

## Part 7: Testing the SSO Flow

### Step 1: Test Login Flow

1. Navigate to `https://portal.byrne-accounts.org/portal.html`
2. Should see loading screen, then login screen
3. Click **Sign In with SecureNexus**
4. Should redirect to Authentik login page
5. Enter credentials
6. Should redirect back to portal dashboard

### Step 2: Verify Dashboard

Check that the dashboard displays:
- ✅ Your name and email
- ✅ Company name (from `company-*` group)
- ✅ Access level (User/Manager/Administrator)
- ✅ App cards for groups you're a member of
- ✅ App count matches visible apps

### Step 3: Test App Launch

1. Click **Launch App** on any app card
2. Should open app in new tab
3. If app also uses Authentik SSO, should auto-login (no password prompt)

### Step 4: Test Logout

1. Click **Logout** button in portal
2. Should redirect to Authentik logout page
3. Should clear session
4. Going back to portal should show login screen again

---

## Part 8: Troubleshooting

### Issue: "Invalid OAuth callback" error

**Cause**: Redirect URI mismatch or state validation failure

**Fix**:
1. Check that redirect URI in Authentik matches exactly: `https://portal.byrne-accounts.org/portal.html`
2. Ensure no trailing slashes
3. Check browser console for state mismatch errors
4. Clear sessionStorage and try again

### Issue: No apps showing in dashboard

**Cause**: User not in any app groups

**Fix**:
1. Go to Authentik → Directory → Users
2. Select the user
3. Add them to appropriate groups (erp-users, pos-users, mail-users)
4. Logout and login again to refresh groups

### Issue: Token expired immediately

**Cause**: Clock skew between server and client

**Fix**:
1. Sync server time: `sudo ntpdate pool.ntp.org`
2. Check timezone settings
3. Verify token expiry in Authentik provider settings

### Issue: CORS errors in browser console

**Cause**: Redirect URI not in allowed origins

**Fix**:
1. Go to Authentik → Applications → Providers → Byrne Portal OAuth Provider
2. Add portal URL to **Redirect URIs/Origins (CORS)** section
3. Save changes

### Issue: Apps launch but require login again

**Cause**: Apps not configured to use same Authentik SSO

**Fix**:
1. Configure each app (ERPNext, Webmail) to use Authentik as OAuth provider
2. See separate guides:
   - `docs/ERPNEXT_SSO_SETUP.md`
   - `docs/SNAPPYMAIL_SSO_SETUP.md`

---

## Part 9: Security Best Practices

### 1. Enable MFA for All Users

1. Navigate to **Flows & Stages**
2. Edit default authentication flow
3. Add MFA stage (TOTP or WebAuthn)
4. Require for all portal users

### 2. Configure Session Timeout

1. Navigate to **Applications** → **Providers** → Byrne Portal OAuth Provider
2. Set **Token validity** to reasonable timeframe (1 hour recommended)
3. Portal will auto-refresh tokens when needed

### 3. Monitor Failed Login Attempts

1. Navigate to **Events** → **Logs**
2. Filter by failed login attempts
3. Configure alerts for suspicious activity

### 4. Use Strong Password Policy

1. Navigate to **Flows & Stages** → **Policies**
2. Create password policy:
   - Minimum 12 characters
   - Require uppercase, lowercase, numbers, symbols
   - Check against HaveIBeenPwned database

### 5. Regular Group Audits

1. Review user group memberships quarterly
2. Remove access for terminated employees
3. Ensure principle of least privilege

---

## Part 10: Adding New Client Applications

To add a new app to the portal:

### Step 1: Update portal.js Configuration

Edit `byrne-website/assets/js/portal.js`:

```javascript
const CONFIG = {
    // ... existing config ...
    apps: {
        // ... existing apps ...

        // New app
        customapp: {
            name: 'Custom Application',
            description: 'Your custom app description',
            icon: '🚀',
            url: 'https://app.byrne-accounts.org',
            requiredGroup: 'customapp-users',  // or null for all users
            color: '#8b5cf6'
        }
    }
};
```

### Step 2: Create Group in Authentik

1. Navigate to **Directory** → **Groups**
2. Create group: `customapp-users`
3. Add members who should see this app

### Step 3: Assign Users

1. Edit users in Authentik
2. Add them to `customapp-users` group
3. They'll see the app on next login

---

## Summary

✅ **What We've Built**:
- OAuth provider in Authentik for portal authentication
- Group-based access control for applications
- Automatic token refresh
- Secure session management
- Professional client portal UI

✅ **What Works**:
- Single sign-on across all applications
- Dynamic app visibility based on user groups
- Secure OAuth 2.0 / OpenID Connect flow
- Mobile-responsive portal design

✅ **Next Steps**:
1. Configure ERPNext to use Authentik SSO
2. Configure Mailcow/SOGo to use Authentik SSO
3. Test with real client accounts
4. Deploy to production

---

## Quick Reference

**Authentik URLs**:
- Admin: `https://auth.byrne-accounts.org/if/admin/`
- User: `https://auth.byrne-accounts.org/if/user/`

**Portal URLs**:
- Production: `https://portal.byrne-accounts.org/portal.html`
- Main site: `https://byrne-accounts.org`

**Required Groups**:
- `erp-users` - ERPNext access
- `pos-users` - POS Awesome access
- `mail-users` - Webmail access
- `company-[name]` - Company identification

**Configuration Files**:
- Portal HTML: `byrne-website/portal.html`
- Portal CSS: `byrne-website/assets/css/portal.css`
- Portal JS: `byrne-website/assets/js/portal.js`
- Traefik: `compose.yml` (landing service labels)

---

**Last Updated**: 2025-11-02
**Version**: 1.0
**Maintainer**: Byrne Accounting IT Team
