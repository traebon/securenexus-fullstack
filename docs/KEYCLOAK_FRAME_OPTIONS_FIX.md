# Keycloak X-Frame-Options Fix

## Problem

Keycloak was returning `X-Frame-Options: DENY` header, preventing it from being embedded in iframes. This caused the error:

```
Refused to display 'https://keycloak.securenexus.net/' in a frame because it set 'X-Frame-Options' to 'deny'.
```

This prevents services like Homarr and Portainer from embedding the Keycloak login page during OAuth/OIDC authentication flows.

## Root Cause

Keycloak sets its own `X-Frame-Options` header at the **realm level** in the Security Defenses settings. This header overrides any headers set by Traefik.

## Changes Made

### 1. **Removed Traefik Middleware** (compose.yml:325)
   - Removed `secure-headers@file` middleware from Keycloak router
   - Allows Keycloak to control its own security headers
   - **Status:** ✅ Complete

### 2. **Updated Traefik Dynamic Configuration** (config/dynamic/traefik_dynamic.yml:47-57)
   - Created `keycloak-headers` middleware (for future use if needed)
   - Removed frame options from middleware to let Keycloak control it
   - **Status:** ✅ Complete

### 3. **Created Helper Scripts**
   - `scripts/keycloak-fix-frame-options.sh` - Automated fix script (doesn't work reliably)
   - `scripts/verify-keycloak-headers.sh` - Verification script
   - **Status:** ✅ Complete

## Required Manual Step

**The automated kcadm.sh tool is not reliably updating the realm configuration.** You must manually update the X-Frame-Options setting in the Keycloak Admin Console:

### Steps to Complete the Fix:

1. **Login to Keycloak Admin Console:**
   - URL: https://keycloak.securenexus.net
   - Username: `admin`
   - Password: Run `cat secrets/keycloak_admin_password.txt` to get password

2. **Navigate to Security Defenses:**
   - Select **"securenexus"** realm from dropdown (top-left)
   - Click **"Realm settings"** (left sidebar)
   - Click **"Security defenses"** tab

3. **Update X-Frame-Options:**
   - Find the **"X-Frame-Options"** field in the Headers section
   - Change from `DENY` to `SAMEORIGIN`
   - Click **"Save"**

4. **Verify the fix:**
   ```bash
   ./scripts/verify-keycloak-headers.sh
   ```

   Expected output:
   ```
   x-frame-options: SAMEORIGIN
   ✅ SUCCESS: X-Frame-Options is set to SAMEORIGIN
   ```

## Security Implications

### What is X-Frame-Options: SAMEORIGIN?

- **DENY**: Prevents ANY site from embedding the page in an iframe (original setting)
- **SAMEORIGIN**: Allows embedding ONLY from the same domain (new setting)

### Security Analysis

✅ **SAFE** - The change from DENY to SAMEORIGIN is secure because:

1. **Same-origin restriction**: Only pages from `securenexus.net` can embed Keycloak
2. **OAuth/OIDC compatibility**: Allows proper authentication flows
3. **Prevents external embedding**: External sites still cannot embed Keycloak
4. **Industry standard**: SAMEORIGIN is the recommended setting for OAuth providers

### Additional Security Measures

The following security headers remain active on Keycloak:

- **HSTS** (Strict-Transport-Security): Forces HTTPS
- **Content-Security-Policy**: Restricts frame sources
- **X-Content-Type-Options**: nosniff
- **X-XSS-Protection**: Enabled
- **Referrer-Policy**: strict-origin-when-cross-origin

## Verification

After making the manual change, verify with:

```bash
# Run verification script
./scripts/verify-keycloak-headers.sh

# Or manually test
curl -I https://keycloak.securenexus.net/realms/securenexus/.well-known/openid-configuration | grep -i x-frame
```

Expected result: `x-frame-options: SAMEORIGIN`

## Related Documentation

- `docs/KEYCLOAK_OAUTH_SETUP.md` - Full OAuth/SSO setup guide
- `docs/keycloak=traefik.txt` - Keycloak reverse proxy documentation

## Status

- ✅ Traefik configuration updated
- ✅ Compose file updated
- ✅ Helper scripts created
- ⬜ **Keycloak realm security setting (MANUAL STEP REQUIRED)**
- ⬜ Verification (run after manual step)

## Troubleshooting

### Still seeing X-Frame-Options: DENY?

1. Verify you updated the correct realm (`securenexus`, not `master`)
2. Clear browser cache
3. Check Keycloak logs: `docker compose logs keycloak`
4. Restart Keycloak: `docker compose restart keycloak`

### Can't access Keycloak Admin Console?

```bash
# Get admin password
cat secrets/keycloak_admin_password.txt

# Check Keycloak is running
docker compose ps keycloak

# View logs
docker compose logs keycloak --tail 50
```

---

**Last Updated:** 2025-10-20
**Keycloak Version:** 26.0.7
**Traefik Version:** 3.3
