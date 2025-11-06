# Keycloak OAuth/SSO Setup Guide

This guide provides complete configuration details for setting up OAuth/SSO with Keycloak for Portainer and Homarr.

## Prerequisites

- ✅ Keycloak running at: https://keycloak.securenexus.net
- ✅ Keycloak realm `securenexus` created
- ✅ OAuth clients created: `portainer` and `homarr`
- ✅ Portainer accessible at: https://portainer.securenexus.net
- ✅ Homarr accessible at: https://portal.securenexus.net

## Keycloak Admin Access

**URL**: https://keycloak.securenexus.net
**Admin Username**: `admin`
**Admin Password**: Located in `secrets/keycloak_admin_password.txt`

To view the password:
```bash
cat secrets/keycloak_admin_password.txt
```

---

## 1. Portainer OAuth Configuration

### Step 1: Complete Initial Portainer Setup

1. Navigate to https://portainer.securenexus.net
2. Create the initial admin account:
   - Username: `admin` (or your preference)
   - Password: (choose a secure password)

### Step 2: Configure OAuth in Portainer

1. Log into Portainer
2. Navigate to: **Settings → Authentication**
3. Click on **OAuth** tab
4. Select **Custom** as the provider
5. Enable **Automatic user provision**
6. Use the following configuration:

**OAuth Settings:**
```
Authentication Provider: Custom
Client ID: portainer
Client Secret: 6275c5adcba10b2755f109f5d4caca4892732fa47a1437dd6f2576d1d5344033

Authorization URL: https://keycloak.securenexus.net/realms/securenexus/protocol/openid-connect/auth
Access Token URL: https://keycloak.securenexus.net/realms/securenexus/protocol/openid-connect/token
Resource URL: https://keycloak.securenexus.net/realms/securenexus/protocol/openid-connect/userinfo
Redirect URL: https://portainer.securenexus.net
Logout URL: https://keycloak.securenexus.net/realms/securenexus/protocol/openid-connect/logout

User Identifier: preferred_username
Scopes: openid profile email
```

**Optional Settings:**
- Default Team ID: (leave empty unless you have specific teams)
- Hide internal authentication: ❌ (Keep disabled for backup access)

7. Click **Save settings**

---

## 2. Homarr OAuth Configuration

Homarr is already configured via environment variables in `compose.yml`:

**Current Configuration:**
```yaml
AUTH_PROVIDER: oidc
AUTH_OIDC_URI: https://keycloak.securenexus.net/realms/securenexus
AUTH_OIDC_CLIENT_ID: homarr
AUTH_OIDC_CLIENT_SECRET: fdfb1d840aa9a1f2cafcce8c8de7c38403ca885efa22105955f87677adb5fe7e
AUTH_OIDC_CLIENT_NAME: Keycloak
```

**Status**: ✅ Already configured (no manual setup needed)

---

## 3. Verify Keycloak Client Configuration

### Access Keycloak Admin Console

1. Navigate to https://keycloak.securenexus.net
2. Click **Administration Console**
3. Login with admin credentials
4. Select the **securenexus** realm (dropdown in top-left)

### Verify Portainer Client

1. Go to **Clients** in left sidebar
2. Click on **portainer** client
3. Verify configuration:
   - **Client ID**: `portainer`
   - **Client authentication**: ON
   - **Valid redirect URIs**: `https://portainer.securenexus.net/*`
   - **Web origins**: `https://portainer.securenexus.net`

4. Go to **Credentials** tab to get/regenerate the client secret if needed

### Verify Homarr Client

1. Click on **homarr** client
2. Verify configuration:
   - **Client ID**: `homarr`
   - **Client authentication**: ON
   - **Valid redirect URIs**: `https://portal.securenexus.net/*`
   - **Web origins**: `https://portal.securenexus.net`

---

## 4. Testing OAuth Login

### Test Portainer SSO

1. Log out of Portainer (if logged in)
2. Navigate to https://portainer.securenexus.net
3. Click **OAuth** login button
4. Should redirect to Keycloak login page
5. Login with Keycloak user credentials
6. Should redirect back to Portainer, logged in

**Troubleshooting:**
- If OAuth button doesn't appear, verify OAuth is enabled in Settings
- Check that all URLs are correct (especially redirect URL)
- Verify client secret matches between Portainer and Keycloak

### Test Homarr SSO

1. Navigate to https://portal.securenexus.net
2. Click **Sign in with Keycloak**
3. Should redirect to Keycloak login
4. Login with Keycloak credentials
5. Should redirect back to Homarr, logged in

---

## 5. Create Keycloak Test User

If you don't have a test user yet:

1. In Keycloak Admin Console, go to **Users**
2. Click **Add user**
3. Fill in:
   - Username: `testuser`
   - Email: `test@securenexus.net`
   - First name: `Test`
   - Last name: `User`
4. Click **Create**
5. Go to **Credentials** tab
6. Click **Set password**
7. Enter password (uncheck "Temporary")
8. Click **Save**

---

## 6. Keycloak URLs Reference

All URLs use the realm: `securenexus`

**OpenID Connect Endpoints:**
```
Base URL: https://keycloak.securenexus.net/realms/securenexus

Authorization: /protocol/openid-connect/auth
Token: /protocol/openid-connect/token
Userinfo: /protocol/openid-connect/userinfo
Logout: /protocol/openid-connect/logout
JWKS: /protocol/openid-connect/certs

Discovery Document: /.well-known/openid-configuration
```

**Admin Console**: https://keycloak.securenexus.net/admin

---

## 7. Client Secrets Reference

**Portainer Client Secret:**
```
6275c5adcba10b2755f109f5d4caca4892732fa47a1437dd6f2576d1d5344033
```

**Homarr Client Secret:**
```
fdfb1d840aa9a1f2cafcce8c8de7c38403ca885efa22105955f87677adb5fe7e
```

**Note**: Keep these secrets secure. They are also stored in:
- Portainer: Manual configuration (entered via web UI)
- Homarr: `compose.yml` environment variables

---

## 8. Troubleshooting

### OAuth Login Fails

1. **Check Keycloak is accessible**: Visit https://keycloak.securenexus.net
2. **Verify client configuration** in Keycloak Admin Console
3. **Check redirect URIs** match exactly (including trailing slashes)
4. **View browser console** for JavaScript errors
5. **Check Keycloak logs**: `docker compose logs keycloak`

### "Invalid Client" Error

- Verify client secret matches in both Portainer and Keycloak
- Check client ID is exactly `portainer` (case-sensitive)
- Ensure client authentication is enabled in Keycloak

### "Redirect URI Mismatch" Error

- In Keycloak, verify redirect URI includes wildcard: `https://portainer.securenexus.net/*`
- Check the actual redirect URL in browser (should match configured URI)

### Keycloak Admin Console Issues

If you see JavaScript errors in admin console:
- This is a known issue with Keycloak hostname configuration
- Use CLI for client management: `docker compose exec keycloak /opt/keycloak/bin/kcadm.sh`
- Or access via internal network if needed

---

## 9. Security Considerations

### Current Security Status

✅ **Already Configured**:
- KC_PROXY_HEADERS: xforwarded - Properly configured for Traefik
- KC_HTTP_ENABLED: true - Required for edge TLS termination
- KC_HEALTH_ENABLED: true - Health endpoints enabled
- KC_METRICS_ENABLED: true - Metrics endpoints enabled
- PostgreSQL database backend
- SSL via Traefik Let's Encrypt

### Security Best Practices

1. **Keep client secrets secure**: Never commit to version control
2. **Use HTTPS only**: All OAuth URLs must use HTTPS
3. **Limit redirect URIs**: Only add trusted redirect URIs
4. **Regular secret rotation**: Rotate client secrets periodically
5. **Monitor Keycloak logs**: Watch for unauthorized access attempts

### Recommended Security Enhancements

Based on official Keycloak reverse proxy documentation:

#### 1. Restrict Exposed Paths (High Priority)

**Current State**: All Keycloak paths are publicly accessible
**Recommendation**: Limit Traefik routing to only required paths:

**Should be exposed**:
- `/realms/` - Required for OIDC endpoints
- `/resources/` - Required for assets (CSS, JS, images)
- `/.well-known/` - Required for OAuth discovery (RFC8414)

**Should NOT be exposed**:
- `/admin/` - Admin console (security risk)
- `/metrics` - Operational metrics (information disclosure)
- `/health` - Health checks (information disclosure)

**Implementation**: Add path-based middleware in Traefik dynamic configuration to block admin paths while allowing realm endpoints.

#### 2. Configure Trusted Proxy Addresses (Medium Priority)

**Current State**: Keycloak trusts proxy headers from any source
**Recommendation**: Add `KC_PROXY_TRUSTED_ADDRESSES` to restrict trust to Traefik container only

```yaml
environment:
  KC_PROXY_TRUSTED_ADDRESSES: "172.18.0.0/16"  # Adjust to your Docker network CIDR
```

This prevents malicious actors from spoofing X-Forwarded-* headers.

**To get your Docker network CIDR**:
```bash
docker network inspect securenexus-fullstack_proxy | grep Subnet
```

#### 3. Separate Admin Hostname (Optional)

**Current State**: Admin console accessible on same hostname as user endpoints
**Recommendation**: Use different hostname for admin access:

```yaml
environment:
  KC_HOSTNAME: keycloak.securenexus.net          # User-facing
  KC_HOSTNAME_ADMIN: admin.keycloak.securenexus.net  # Admin-only
```

Then apply VPN-only middleware to admin hostname route.

#### 4. Enable Sticky Sessions (Performance)

**Current State**: No session affinity configured
**Recommendation**: Configure Traefik sticky sessions for better performance

```yaml
labels:
  - traefik.http.services.keycloak.loadbalancer.sticky.cookie=true
  - traefik.http.services.keycloak.loadbalancer.sticky.cookie.name=AUTH_SESSION_ID
```

This reduces cross-node session lookups in clustered deployments.

### Documentation Reference

For complete Keycloak reverse proxy configuration details, see:
- `docs/keycloak=traefik.txt` - Official Keycloak reverse proxy guide
- Lines 273-523: Reverse proxy configuration
- Lines 345-407: Exposed path recommendations
- Lines 408-413: Trusted proxy addresses

---

## 10. Next Steps

After configuring OAuth:

1. ✅ Test Portainer OAuth login
2. ✅ Test Homarr OAuth login
3. ⬜ Create additional Keycloak users as needed
4. ⬜ Configure role mappings (optional)
5. ⬜ Set up team assignments in Portainer (optional)
6. ⬜ Document user onboarding process

---

## Additional Resources

- [Portainer OAuth Documentation](https://docs.portainer.io/advanced/authentication/oauth)
- [Keycloak OpenID Connect Documentation](https://www.keycloak.org/docs/latest/securing_apps/#_oidc)
- [Homarr Authentication Guide](https://homarr.dev/docs/authentication)

---

**Last Updated**: 2025-10-20
**Keycloak Version**: 26.0.7
**Portainer Version**: 2.33.2-EE
**Homarr Version**: 1.0 (latest)
