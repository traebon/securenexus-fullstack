# SSO User Management Guide

## Overview

SecureNexus uses **Authentik** as the central SSO (Single Sign-On) identity provider. All applications (Grafana, Dickinson Webmail, ERPNext, etc.) authenticate through Authentik for unified user management.

**Authentik URL**: https://sso.securenexus.net

---

## User Group Structure

### System Groups

| Group Name | Superuser | Purpose |
|------------|-----------|---------|
| **authentik Admins** | Yes | Full system administrators - can manage all Authentik settings |
| **Grafana Admins** | Yes | Grafana administrators with full access |
| **authentik Read-only** | No | Read-only access to Authentik |

### Dickinson Accounts Groups

| Group Name | Superuser | Purpose |
|------------|-----------|---------|
| **Dickinson Admins** | No | Administrators for Dickinson accounts system (can manage users) |
| **Dickinson Users** | No | Regular users for Dickinson accounts (webmail, portal access) |

---

## Current Users

| Username | Email | Name | Groups |
|----------|-------|------|--------|
| admin | tristian@securenexus.net | Administrator | authentik Admins |
| akadmin | tristian@securenexus.net | authentik Default Admin | authentik Admins |

---

## User Management Scripts

All user management scripts are located in `scripts/`:

### 1. Create Sysadmin Account

Creates a system administrator with full access to all systems.

```bash
./scripts/create-sysadmin-user.sh
```

**Interactive prompts:**
- Username
- Email address
- Full name
- Password

**Group membership:**
- authentik Admins (full system access)
- Dickinson Admins (Dickinson organization)

---

### 2. Create Dickinson User

Creates either an admin or regular user for the Dickinson accounts system.

```bash
./scripts/create-dickinson-user.sh
```

**Interactive prompts:**
- Username
- Email address
- Full name
- Password
- User type (Admin or Regular User)

**Group membership:**
- **Admin**: Dickinson Admins
- **User**: Dickinson Users

---

### 3. List Users by Group

View all users organized by their group membership.

```bash
./scripts/list-users-by-group.sh
```

Shows:
- All groups with their members
- Users not assigned to any group
- User counts per group

---

### 4. List All Users

Quick list of all users in the system.

```bash
./scripts/list-authentik-users.sh
```

---

### 5. Reset User Password

Reset a user's password (for password recovery).

```bash
./scripts/reset-authentik-password.sh
```

---

## Application Access

### Dickinson Webmail

**URL**: Configured in Authentik application settings
**Access**: Dickinson Users, Dickinson Admins
**Type**: OIDC/SAML SSO

### ERPNext

**URL**: https://erp.byrne-accounts.org
**Access**: Configured per user
**Type**: OIDC SSO

### Grafana

**URL**: https://grafana.securenexus.net (VPN-only)
**Access**: Grafana Admins, authentik Admins
**Type**: OAuth2 SSO

### Application Portal (Homarr)

**URL**: https://portal.securenexus.net
**Access**: All authenticated users
**Type**: Public dashboard with optional SSO

---

## Managing Users via Web UI

### Access Authentik Admin Interface

1. Navigate to https://sso.securenexus.net/if/admin/
2. Login with admin credentials
3. Navigate to **Directory** > **Users** or **Groups**

### Create User via Web UI

1. Go to **Directory** > **Users**
2. Click **Create**
3. Fill in:
   - Username
   - Email
   - Name
   - Password
4. Assign to groups:
   - Click user → **Groups** tab → **Add to existing group**
5. Save

### Modify User Groups

1. Go to **Directory** > **Users**
2. Click on username
3. Go to **Groups** tab
4. Add or remove groups
5. Save

### Disable/Enable User

1. Go to **Directory** > **Users**
2. Click on username
3. Go to **Settings** tab
4. Toggle **Is active** checkbox
5. Save

---

## Group Permissions

### authentik Admins

- Full access to Authentik admin interface
- Can create/modify/delete users and groups
- Can configure applications and flows
- Can view audit logs and events

### Dickinson Admins

- Access to Dickinson applications with admin privileges
- Can manage Dickinson users (via application-specific interfaces)
- Cannot modify Authentik system settings
- View-only access to Authentik admin (if granted)

### Dickinson Users

- Access to Dickinson Webmail
- Access to Dickinson applications
- Can modify own profile
- Cannot access admin interfaces

---

## SSO Application Integration

### Applications Already Integrated

1. **Dickinson Webmail** (SnappyMail)
   - Provider: OIDC
   - Access: Dickinson Users, Dickinson Admins

2. **ERPNext**
   - Provider: OIDC
   - Access: Configured per user

3. **Grafana**
   - Provider: OAuth2
   - Access: Grafana Admins, authentik Admins

4. **App Catalog**
   - Provider: Proxy
   - Access: All authenticated users

5. **Tailscale**
   - Provider: OIDC
   - Access: VPN users

---

## User Workflow Examples

### Example 1: Onboard New Dickinson User

```bash
# 1. Create user account
./scripts/create-dickinson-user.sh
# Select: "2) Dickinson User"
# Enter: username, email, name, password

# 2. Verify user creation
./scripts/list-users-by-group.sh

# 3. User can now login at:
# https://sso.securenexus.net
```

### Example 2: Promote User to Admin

```bash
# Option 1: Via Web UI
# 1. Login to https://sso.securenexus.net/if/admin/
# 2. Directory > Users > [username]
# 3. Groups tab > Add to "Dickinson Admins"

# Option 2: Via Database (advanced)
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group
user = User.objects.get(username="username")
group = Group.objects.get(name="Dickinson Admins")
user.ak_groups.add(group)
print(f"✅ Added {user.username} to {group.name}")
EOF
```

### Example 3: Create Sysadmin for Yourself

```bash
./scripts/create-sysadmin-user.sh
# Enter your details:
# Username: tristian
# Email: tristian@securenexus.net
# Full name: Tristian (Sysadmin)
# Password: [secure password]
```

---

## Security Best Practices

### Password Policy

- Minimum length: 12 characters (recommended)
- Require uppercase, lowercase, numbers, symbols
- Enable MFA/2FA for admin accounts
- Rotate passwords every 90 days

### User Lifecycle

1. **Creation**: Use scripts or web UI
2. **Activation**: Ensure user is set to "active"
3. **Group Assignment**: Assign to appropriate groups
4. **Access Review**: Quarterly review of user access
5. **Deactivation**: Set "is_active" to false (don't delete)
6. **Deletion**: Only delete after 90-day retention period

### Admin Account Protection

- Enable TOTP (Time-based One-Time Password) for all admin accounts
- Use strong, unique passwords
- Monitor admin login attempts via Events log
- Restrict admin access to VPN network when possible

---

## Troubleshooting

### User Cannot Login

1. Verify user is **active**: Authentik Admin > Directory > Users > [user] > Settings > Is active
2. Check password: Reset via `./scripts/reset-authentik-password.sh`
3. Verify group membership: User should be in at least one group
4. Check application access: Ensure application allows user's group

### User Not Seeing Application

1. Verify group membership includes application access
2. Check application bindings: Authentik Admin > Applications > [app] > Policy / Group / User Bindings
3. Clear browser cache/cookies
4. Try incognito/private browsing

### SSO Redirect Loop

1. Check application configuration (redirect URIs)
2. Verify OIDC/OAuth2 credentials match
3. Clear Authentik session: Logout and re-login
4. Check browser console for errors

---

## Maintenance Commands

### View All Users

```bash
./scripts/list-authentik-users.sh
```

### View Users by Group

```bash
./scripts/list-users-by-group.sh
```

### View Users in Database

```bash
docker compose exec -T authentik_db psql -U authentik -d authentik \
  -c "SELECT username, email, name, is_active FROM authentik_core_user ORDER BY username;"
```

### View Groups in Database

```bash
docker compose exec -T authentik_db psql -U authentik -d authentik \
  -c "SELECT name, is_superuser FROM authentik_core_group ORDER BY name;"
```

### View Applications

```bash
docker compose exec -T authentik_db psql -U authentik -d authentik \
  -c "SELECT name, slug FROM authentik_core_application ORDER BY name;"
```

---

## Next Steps

1. **Create your sysadmin account**:
   ```bash
   ./scripts/create-sysadmin-user.sh
   ```

2. **Create Dickinson admin users**:
   ```bash
   ./scripts/create-dickinson-user.sh
   # Choose option 1: Dickinson Admin
   ```

3. **Create regular Dickinson users**:
   ```bash
   ./scripts/create-dickinson-user.sh
   # Choose option 2: Dickinson User
   ```

4. **Configure application access policies**:
   - Login to https://sso.securenexus.net/if/admin/
   - Go to Applications > [app] > Policy / Group / User Bindings
   - Add groups (e.g., "Dickinson Users" to "Dickinson Webmail")

5. **Test SSO login**:
   - Logout of all applications
   - Visit application URL
   - Login with new user credentials
   - Verify redirect to Authentik SSO
   - Verify successful login and application access

---

## Additional Resources

- **Authentik Documentation**: https://docs.goauthentik.io/
- **SSO Integration Guide**: `docs/SSO_INTEGRATION_PLAN.md`
- **System Status**: Run `make ps` to verify all services running
- **Logs**: `docker compose logs authentik_server -f`

---

**Last Updated**: October 26, 2025
**Maintainer**: System Administrator
