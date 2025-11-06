# ERPNext SSO Access - "Not Permitted" Error Fix

**Date**: November 3, 2025
**Issue**: "Not Permitted - You are not permitted to access this page"
**Status**: ✅ Easy Fix - Add User to Authorized Group

---

## 🎉 Good News: SSO is Working!

The OAuth integration is fully configured and working. The "Not Permitted" error means:
- ✅ ERPNext SSO configuration is correct
- ✅ Authentik OAuth provider is working
- ✅ SSL certificates are valid
- ✅ All OAuth parameters are correct

**The only issue**: Your user account needs to be added to an authorized group in Authentik.

---

## 🔐 Authorization Requirement

To access ERPNext via SSO, users must be members of:
- **`authentik Admins`** group (full system administrators), OR
- **`Dickinson Admins`** group (Dickinson organization administrators)

Currently, these groups control who can access ERPNext.

---

## 🛠️ Solution: Add User to Authorized Group

### Method 1: Via Authentik Web UI (Recommended)

**Step-by-Step:**

1. **Login to Authentik Admin**
   - URL: https://sso.securenexus.net/if/admin/
   - Use your Authentik admin credentials

2. **Navigate to Users**
   - Click **Directory** in the left sidebar
   - Click **Users**

3. **Find Your User**
   - Search for your username in the list
   - Click on your username

4. **Add to Group**
   - Click the **Groups** tab
   - Click **Add to existing group**
   - Select either:
     - **`authentik Admins`** (for full system access), OR
     - **`Dickinson Admins`** (for Dickinson organization access)
   - Click **Add**

5. **Save & Test**
   - The change is immediate (no restart needed)
   - Try the SSO login URL again

---

### Method 2: Create New Sysadmin User (Alternative)

If you don't have access to the Authentik admin panel, create a new sysadmin account:

```bash
cd /home/tristian/securenexus-fullstack
./scripts/create-sysadmin-user.sh
```

**Interactive prompts:**
- **Username**: Your desired username
- **Email**: Your email address
- **Full name**: Your full name
- **Password**: Your secure password

**This script automatically:**
- Creates the user in Authentik
- Adds to `authentik Admins` group (full access)
- Adds to `Dickinson Admins` group (organization access)
- Grants ERPNext access

Then use the new credentials with the SSO URL.

---

### Method 3: Via Command Line (Advanced)

If you have shell access:

```bash
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group

# Replace with your username
username = "YOUR_USERNAME_HERE"

# Get the user
user = User.objects.get(username=username)

# Get the Dickinson Admins group
group = Group.objects.get(name="Dickinson Admins")

# Add user to group
user.ak_groups.add(group)

print(f"✅ Added {user.username} to {group.name}")
print(f"✅ {user.username} can now access ERPNext via SSO")
EOF
```

---

## 🧪 Test SSO Access Again

After adding your user to an authorized group:

### Fresh SSO URL:
```bash
# Generate a fresh SSO URL (state tokens are single-use)
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
from frappe.utils.oauth import get_oauth2_authorize_url
print(get_oauth2_authorize_url('authentik', redirect_to='/app'))
EOF
"
```

Or use this URL (valid for a short time):
```
https://sso.securenexus.net/application/o/authorize/?redirect_uri=https%3A%2F%2Ferp.byrne-accounts.org%2Fapi%2Fmethod%2Ffrappe.integrations.oauth2_logins.custom%2Fauthentik&state=eyJzaXRlIjogImh0dHBzOi8vZXJwLmJ5cm5lLWFjY291bnRzLm9yZyIsICJ0b2tlbiI6ICJmY2QwN2M1NjNmMzNhZWI1ZjdlZTg0ZGQzNWYyZDE5OGY0MmE0NzA2OTQ4N2MzN2U4YTg0ZTIwOCIsICJyZWRpcmVjdF90byI6ICIvYXBwIn0%3D&scope=openid+profile+email&response_type=code&client_id=u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9
```

### Expected Result:
1. Click SSO URL
2. Redirected to Authentik login
3. Login with credentials
4. **Authentik approves access** (no "Not Permitted" error)
5. Redirected back to ERPNext with authorization code
6. **You're logged into ERPNext!** 🎉

---

## 📋 Verify Group Membership

### Via Web UI:
1. Login to Authentik: https://sso.securenexus.net/if/admin/
2. Directory → Users → [Your Username]
3. Click **Groups** tab
4. Verify you're in `Dickinson Admins` or `authentik Admins`

### Via Command Line:
```bash
docker compose exec -T authentik_db psql -U authentik -d authentik -c "
SELECT u.username, g.name as group_name
FROM authentik_core_user u
JOIN authentik_core_user_ak_groups ug ON u.uuid::text = ug.user_id::text
JOIN authentik_core_group g ON ug.group_id::text = g.uuid::text
WHERE u.username = 'YOUR_USERNAME'
ORDER BY g.name;
"
```

---

## 🔒 Understanding Authentik Authorization

### How It Works:
1. **Application**: ERPNext OAuth (configured in Authentik)
2. **Policy Bindings**: Define which users/groups can access the application
3. **Current Policy**: Only `authentik Admins` and `Dickinson Admins` can access ERPNext
4. **Authorization Check**: When you click the SSO URL, Authentik checks:
   - ✅ Are you logged in?
   - ✅ Do you have access to the ERPNext application?
   - ❌ If NOT in authorized group → "Not Permitted"

### Why This Is Good:
- **Security**: Only authorized users can access ERPNext
- **Centralized Control**: Manage access via Authentik groups
- **Audit Trail**: All access attempts logged in Authentik

---

## 🎯 Grant Access to More Users

### For Individual Users:
1. Login to Authentik admin
2. Directory → Users → [Username]
3. Groups tab → Add to `Dickinson Admins`

### For Multiple Users:
Create them with the script:
```bash
./scripts/create-dickinson-user.sh
# Choose "1) Dickinson Admin" for ERPNext access
```

### For All Users (Not Recommended):
You can modify the Authentik application policy to allow all authenticated users, but this reduces security:

1. Login to Authentik: https://sso.securenexus.net/if/admin/
2. Applications → Applications
3. Click **ERPNext OAuth**
4. Go to **Policy / Group / User Bindings** tab
5. Edit or remove group restrictions

**Warning**: This allows any Authentik user to access ERPNext!

---

## 📊 Check Current ERPNext Access

### Who Currently Has Access:
```bash
# Via database query
docker compose exec -T authentik_db psql -U authentik -d authentik -c "
SELECT u.username, u.email, STRING_AGG(g.name, ', ') as groups
FROM authentik_core_user u
JOIN authentik_core_user_ak_groups ug ON u.uuid::text = ug.user_id::text
JOIN authentik_core_group g ON ug.group_id::text = g.uuid::text
WHERE g.name IN ('authentik Admins', 'Dickinson Admins')
GROUP BY u.username, u.email
ORDER BY u.username;
"
```

### Application Policy Bindings:
1. Login to Authentik
2. Applications → Applications → ERPNext OAuth
3. Policy / Group / User Bindings tab
4. View which groups/users are bound

---

## 🛠️ Troubleshooting

### Still Getting "Not Permitted"?

**Check 1: User is in correct group**
```bash
# List user's groups
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User
user = User.objects.get(username="YOUR_USERNAME")
groups = user.ak_groups.all()
print(f"User {user.username} is in groups:")
for g in groups:
    print(f"  - {g.name}")
EOF
```

**Check 2: ERPNext application policy**
- Login to Authentik admin
- Applications → ERPNext OAuth
- Policy / Group / User Bindings
- Ensure `Dickinson Admins` or `authentik Admins` is bound

**Check 3: Generate fresh SSO URL**
- State tokens expire and are single-use
- Generate a new URL (see command above)

**Check 4: Clear browser cache**
- Logout of Authentik
- Clear cookies for `sso.securenexus.net` and `erp.byrne-accounts.org`
- Try SSO flow again

---

## ✅ Success Indicators

After adding your user to an authorized group, you should see:

1. **No "Not Permitted" error** from Authentik
2. **Redirect to ERPNext** with authorization code
3. **ERPNext processes OAuth callback** (fetches user info)
4. **User auto-created in ERPNext** (if first login)
5. **Logged into ERPNext** (redirected to `/app`)

Then in ERPNext:
- Your email appears in top-right corner
- You can access ERPNext features
- You may need to assign additional ERPNext roles for full access

---

## 📚 Related Documentation

- `docs/SSO_USER_MANAGEMENT.md` - Complete user management guide
- `docs/ERPNEXT_SSO_FINAL_WORKING.md` - SSO configuration details
- `scripts/create-sysadmin-user.sh` - Create sysadmin accounts
- `scripts/create-dickinson-user.sh` - Create Dickinson users

---

## 🎉 Quick Fix Summary

**The Problem**: "Not Permitted" means you're not in an authorized Authentik group

**The Solution**: Add yourself to `Dickinson Admins` or `authentik Admins` group

**Fastest Method**:
1. Login to Authentik admin: https://sso.securenexus.net/if/admin/
2. Directory → Users → [Your Username] → Groups tab
3. Add to existing group → Select `Dickinson Admins` → Add
4. Generate fresh SSO URL and try again

**Alternative**:
```bash
./scripts/create-sysadmin-user.sh
# Creates new user with full access
```

---

**Status**: Authorization issue (easy fix)
**Next Action**: Add your user to authorized group in Authentik
**Then**: Test SSO login again - it will work! 🚀
