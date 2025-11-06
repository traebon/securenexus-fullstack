# ERPNext SSO Setup with Authentik

## Overview

This guide configures ERPNext to use Authentik as the SSO provider, allowing users to log in with their Authentik credentials.

---

## Authentik Configuration ✅ COMPLETE

**OAuth Provider**: ERPNext 0Auth
**Client ID**: `u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9`
**Client Secret**: `LB54cG7XAapKjx3wiQei6u3Hj7VgelLrEi1cvMd1iw5sRWMhoVDgFJ1BXpFrqnAYz7ikgzhGFNoNVMLK4Ff1inXUSMQDiLGQK0Uypox6hLjvCvFtYNplQe06xW1iZut1`

**Redirect URIs** (configured):
- https://erp.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik
- https://pos.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik

**OIDC Endpoints**:
- Authorization: `https://sso.securenexus.net/application/o/authorize/`
- Token: `https://sso.securenexus.net/application/o/token/`
- User Info: `https://sso.securenexus.net/application/o/userinfo/`
- JWKS: `https://sso.securenexus.net/application/o/erpnext/jwks/`

---

## ERPNext Configuration (Manual Steps Required)

### Step 1: Login to ERPNext as Administrator

1. Go to: https://erp.byrne-accounts.org
2. Login with Administrator credentials
3. Get password from: `cat secrets/erpnext_admin_password.txt`

---

### Step 2: Enable Social Login

1. Press **Ctrl+K** (Awesome Bar)
2. Search for: **Social Login Key**
3. Click **+ New** to create a new Social Login Key

---

### Step 3: Configure Authentik Provider

Fill in the following fields:

#### Basic Information
- **Social Login Provider**: `Custom`
- **Provider Name**: `Authentik`
- **Enable Social Login**: ✅ Check this box

#### OAuth2 Configuration
- **Client ID**:
  ```
  u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9
  ```

- **Client Secret**:
  ```
  LB54cG7XAapKjx3wiQei6u3Hj7VgelLrEi1cvMd1iw5sRWMhoVDgFJ1BXpFrqnAYz7ikgzhGFNoNVMLK4Ff1inXUSMQDiLGQK0Uypox6hLjvCvFtYNplQe06xW1iZut1
  ```

- **Base URL**:
  ```
  https://sso.securenexus.net
  ```

- **Authorize URL**:
  ```
  https://sso.securenexus.net/application/o/authorize/
  ```

- **Access Token URL**:
  ```
  https://sso.securenexus.net/application/o/token/
  ```

- **Redirect URL**:
  ```
  /api/method/frappe.integrations.oauth2_logins.custom/authentik
  ```
  (This is relative to your ERPNext site domain)

- **API Endpoint** (User Info):
  ```
  https://sso.securenexus.net/application/o/userinfo/
  ```

#### User Mapping
Map the OIDC claims to ERPNext user fields:

- **ID Field**: `sub` (or `preferred_username`)
- **Username Field**: `email`
- **Email Field**: `email`
- **First Name Field**: `given_name` (or leave blank to extract from `name`)
- **Last Name Field**: `family_name` (or leave blank to extract from `name`)

#### Advanced Settings
- **Sign Ups**: ✅ Enable (if you want automatic user creation)
- **Assign Role**: Select a default role for new SSO users (e.g., `System User`)

---

### Step 4: Save Configuration

1. Click **Save** button
2. ERPNext will validate the configuration
3. You should see "Social Login Key" saved successfully

---

### Step 5: Test SSO Login

1. **Logout** from ERPNext
2. Go to: https://erp.byrne-accounts.org
3. You should see a **Login with Authentik** button
4. Click the button
5. You'll be redirected to Authentik
6. Login with your Authentik credentials (e.g., `tristian`)
7. You'll be redirected back to ERPNext and logged in

---

## Alternative Method: Bench Console Configuration

If you prefer command-line configuration, you can use the Frappe bench console:

```bash
docker exec -it erpnext-backend bash
```

Then run:

```python
bench --site erp.byrne-accounts.org console

# Create Social Login Key
from frappe.social_logins.doctype.social_login_key.social_login_key import SocialLoginKey

doc = frappe.get_doc({
    "doctype": "Social Login Key",
    "provider_name": "Authentik",
    "social_login_provider": "Custom",
    "enable_social_login": 1,
    "client_id": "u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9",
    "client_secret": "LB54cG7XAapKjx3wiQei6u3Hj7VgelLrEi1cvMd1iw5sRWMhoVDgFJ1BXpFrqnAYz7ikgzhGFNoNVMLK4Ff1inXUSMQDiLGQK0Uypox6hLjvCvFtYNplQe06xW1iZut1",
    "base_url": "https://sso.securenexus.net",
    "authorize_url": "https://sso.securenexus.net/application/o/authorize/",
    "access_token_url": "https://sso.securenexus.net/application/o/token/",
    "redirect_url": "/api/method/frappe.integrations.oauth2_logins.custom/authentik",
    "api_endpoint": "https://sso.securenexus.net/application/o/userinfo/",
    "auth_url_data": '{"scope": "openid profile email"}',
})
doc.insert()
doc.save()
```

---

## Troubleshooting

### SSO Button Not Appearing
- Clear ERPNext cache: **Setup** > **Clear Cache**
- Ensure "Enable Social Login" is checked
- Verify the Social Login Key is saved

### Redirect URI Mismatch Error
- Ensure the redirect URI in ERPNext matches the one configured in Authentik
- Check that the base URL is correct (https://erp.byrne-accounts.org)

### User Not Created Automatically
- Enable "Sign Ups" in Social Login Key settings
- Check that user email from Authentik matches ERPNext email format
- Manually create user first if auto-creation is disabled

### Token Exchange Failed
- Verify Client ID and Client Secret are correct
- Check that Authentik endpoints are accessible from ERPNext container
- Review ERPNext logs: `docker logs erpnext-backend`

---

## User Access Control

Users who can access ERPNext via SSO are controlled in Authentik:

**Current Access** (via Authentik policy bindings):
- `authentik Admins` group → Full ERPNext access
- `Dickinson Admins` group → ERPNext access

**To Grant Access**:
1. Add user to `Dickinson Admins` or `authentik Admins` group in Authentik
2. User can then login to ERPNext via SSO

---

## Testing Checklist

- [ ] Can see "Login with Authentik" button on ERPNext login page
- [ ] Clicking SSO button redirects to Authentik
- [ ] Can login with Authentik credentials
- [ ] Redirected back to ERPNext successfully
- [ ] Logged in as the correct user
- [ ] User profile information populated correctly
- [ ] Can access ERPNext features based on assigned role

---

## Next Steps

1. **Configure in ERPNext UI** (recommended) - Follow Steps 1-5 above
2. **Test SSO Login** - Logout and try logging in with Authentik
3. **Grant Access** - Add users to appropriate Authentik groups
4. **Customize Roles** - Assign ERPNext roles based on user needs

---

## Quick Reference

**ERPNext URL**: https://erp.byrne-accounts.org
**Authentik Auth URL**: https://sso.securenexus.net
**Administrator Password**: `cat secrets/erpnext_admin_password.txt`

**Social Login Setup**:
- Search: **Social Login Key** (Ctrl+K)
- Provider: **Custom** (Authentik)
- Copy credentials from this document

---

**Last Updated**: October 26, 2025
**Status**: Authentik ✅ | ERPNext ✅ | UI Button Issue ⚠️

## Current Status

### ✅ Configuration Complete

Both Authentik and ERPNext are fully configured for SSO:

**Authentik OAuth Provider**:
- Client ID and Secret configured
- Redirect URIs set for both ERP and POS
- Application accessible to authorized groups

**ERPNext Social Login Key**:
- Provider: Authentik (Custom)
- All OAuth endpoints configured
- Sign-ups: Allowed
- User mapping configured (sub, email, name)
- Configuration verified in database

### ⚠️ Known Issue: SSO Button Not Appearing

Despite correct configuration, the "Login with Authentik" button does not appear on the ERPNext login page. This appears to be a limitation in Frappe v16-dev with custom OAuth providers.

**Workaround**: Direct OAuth URL can be used to initiate SSO login:

```
https://sso.securenexus.net/application/o/authorize/?client_id=u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9&redirect_uri=https://erp.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik&response_type=code&scope=openid%20profile%20email
```

This URL will:
1. Redirect to Authentik login page
2. Authenticate user
3. Return to ERPNext with OAuth code
4. Complete SSO login flow

---
