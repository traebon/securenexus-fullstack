# User, Role, and Group Management Guide

**Complete guide for managing users, roles, and groups in Authentik and ERPNext**

**Last Updated**: November 3, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Authentik Groups (Access Control)](#authentik-groups)
3. [ERPNext Roles (Permissions)](#erpnext-roles)
4. [Creating Users](#creating-users)
5. [Managing Groups](#managing-groups)
6. [Assigning ERPNext Roles](#assigning-erpnext-roles)
7. [Common Workflows](#common-workflows)
8. [Quick Reference](#quick-reference)

---

## Overview

### Two-Layer Authorization System

Your system uses a **two-layer authorization model**:

1. **Authentik Groups** → Control who can **access** ERPNext
2. **ERPNext Roles** → Control what users can **do** in ERPNext

```
User Login → Authentik (Group Check) → ERPNext Access → ERPNext (Role Check) → Feature Access
```

### Current Setup

**Authentik Groups** (Access Control):
- `authentik Admins` - Full system administrators
- `Dickinson Admins` - Organization administrators with ERPNext access
- `Dickinson Users` - Regular users (webmail, portal)

**ERPNext Roles** (Permissions):
- `System User` - Can access Desk
- `Accounts User` - Accounting features
- `POS Cashier` - Point of Sale
- `Sales User` - Sales features
- And many more...

---

## Authentik Groups

### Current Groups

| Group Name | Purpose | ERPNext Access |
|------------|---------|----------------|
| **authentik Admins** | Full system administrators | ✅ Yes |
| **Dickinson Admins** | Dickinson organization admins | ✅ Yes |
| **Dickinson Users** | Regular users (webmail, etc.) | ❌ No |

### View All Groups

```bash
docker compose exec -T authentik_db psql -U authentik -d authentik -c "
SELECT name, is_superuser, num_pk as member_count
FROM authentik_core_group
ORDER BY name;"
```

### Create New Group (via CLI)

```bash
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import Group

# Create a new group
group = Group.objects.create(
    name="ERPNext Accountants",
    is_superuser=False
)

print(f"✅ Created group: {group.name}")
EOF
```

### Create Group (via Web UI)

1. Go to https://sso.securenexus.net/if/admin/
2. **Directory** → **Groups**
3. Click **Create**
4. Fill in:
   - **Name**: Group name (e.g., "ERPNext Accountants")
   - **Superuser privileges**: Leave unchecked (unless admin group)
5. Click **Create**

---

## ERPNext Roles

### Common ERPNext Roles

| Role | Description | Typical Use |
|------|-------------|-------------|
| **System User** | Access to Desk (backend) | Required for all non-portal users |
| **Accounts User** | View and manage accounting | Accountants |
| **Accounts Manager** | Full accounting control | Senior accountants |
| **POS Cashier** | Access POS interface | Store cashiers |
| **Sales User** | Create/view sales transactions | Sales team |
| **Sales Manager** | Manage sales, discounts | Sales managers |
| **Purchase User** | Create purchase orders | Purchasing staff |
| **Stock User** | Manage inventory | Warehouse staff |
| **HR User** | View HR records | HR staff |
| **HR Manager** | Full HR management | HR managers |
| **Employee** | Self-service portal | All employees |

### View All ERPNext Roles

```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
import frappe
frappe.connect()

roles = frappe.get_all('Role',
    fields=['name', 'disabled'],
    filters={'disabled': 0},
    order_by='name'
)

print('\nAvailable ERPNext Roles:')
print('='*50)
for role in roles:
    print(f'  - {role.name}')
print('='*50 + '\n')
EOF
"
```

---

## Creating Users

### Method 1: Create Sysadmin (Full Access)

Creates a user with full system and ERPNext access:

```bash
./scripts/create-sysadmin-user.sh
```

**Prompts:**
- Username
- Email
- Full name
- Password

**Automatically adds to:**
- `authentik Admins` group
- `Dickinson Admins` group

### Method 2: Create Dickinson User

Creates either admin or regular user:

```bash
./scripts/create-dickinson-user.sh
```

**Options:**
1. **Dickinson Admin** → Gets ERPNext access
2. **Dickinson User** → Gets webmail/portal access only

### Method 3: Create via Authentik Web UI

**Step-by-Step:**

1. **Login to Authentik**
   - URL: https://sso.securenexus.net/if/admin/
   - Use admin credentials

2. **Go to Users**
   - Click **Directory** in sidebar
   - Click **Users**

3. **Create User**
   - Click **Create**
   - Fill in:
     - **Username**: `jsmith`
     - **Name**: `John Smith`
     - **Email**: `jsmith@example.com`
     - **Password**: (set secure password)
     - **Is active**: ✅ Checked
   - Click **Create**

4. **Add to Groups**
   - Click on the newly created user
   - Go to **Groups** tab
   - Click **Add to existing group**
   - Select **Dickinson Admins** (for ERPNext access)
   - Click **Add**

5. **Test Login**
   - Use SSO URL to test
   - User should be able to access ERPNext

### Method 4: Bulk User Creation (via script)

Save this as `create-multiple-users.sh`:

```bash
#!/bin/bash

# Create multiple users at once
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group

# Get the Dickinson Admins group
group = Group.objects.get(name="Dickinson Admins")

# Define users to create
users = [
    {"username": "jsmith", "email": "jsmith@example.com", "name": "John Smith"},
    {"username": "mjones", "email": "mjones@example.com", "name": "Mary Jones"},
    {"username": "bwilson", "email": "bwilson@example.com", "name": "Bob Wilson"},
]

for user_data in users:
    # Create user
    user = User.objects.create(
        username=user_data["username"],
        email=user_data["email"],
        name=user_data["name"],
        type="internal"
    )

    # Set password (change this!)
    user.set_password("ChangeMe123!")
    user.save()

    # Add to group
    user.ak_groups.add(group)

    print(f"✅ Created user: {user.username} ({user.email})")

print(f"\n✅ Created {len(users)} users")
print(f"✅ All users added to {group.name}")
print(f"⚠️  Remember to change their passwords!")
EOF
```

Then run:
```bash
chmod +x create-multiple-users.sh
./create-multiple-users.sh
```

---

## Managing Groups

### Add User to Group

**Via CLI:**
```bash
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group

# Specify username and group
username = "jsmith"
group_name = "Dickinson Admins"

user = User.objects.get(username=username)
group = Group.objects.get(name=group_name)
user.ak_groups.add(group)

print(f"✅ Added {user.username} to {group.name}")
EOF
```

**Via Web UI:**
1. Login to Authentik admin
2. **Directory** → **Users** → [Username]
3. **Groups** tab
4. **Add to existing group**
5. Select group → **Add**

### Remove User from Group

**Via CLI:**
```bash
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group

username = "jsmith"
group_name = "Dickinson Admins"

user = User.objects.get(username=username)
group = Group.objects.get(name=group_name)
user.ak_groups.remove(group)

print(f"✅ Removed {user.username} from {group.name}")
EOF
```

### List Users in a Group

```bash
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import Group

group_name = "Dickinson Admins"
group = Group.objects.get(name=group_name)
users = group.users.all()

print(f"\nUsers in group '{group.name}':")
print("="*50)
for user in users:
    print(f"  - {user.username} ({user.email})")
print("="*50 + "\n")
EOF
```

---

## Assigning ERPNext Roles

### After First SSO Login

When a user logs in via SSO for the first time:
1. ERPNext automatically creates the user account
2. User gets **minimal permissions** by default
3. **You must assign roles manually**

### Assign Roles via Web UI

1. **Login to ERPNext as Administrator**
   - URL: https://erp.byrne-accounts.org
   - Username: `Administrator`
   - Password: `cat secrets/erpnext_admin_password.txt`

2. **Find the User**
   - Press **Ctrl+K** (Awesome Bar)
   - Type: `User List`
   - Press Enter

3. **Open User**
   - Find the SSO user (by email)
   - Click on their name

4. **Assign Roles**
   - Scroll to **Roles** section
   - Check the boxes for roles you want to assign:
     - ✅ **System User** (required for Desk access)
     - ✅ **Accounts User** (if accountant)
     - ✅ **POS Cashier** (if cashier)
     - etc.
   - Click **Save**

5. **Test Access**
   - User logs out and back in
   - Verify they can access the features

### Assign Roles via CLI

```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
import frappe
frappe.connect()

# Specify user email and roles
user_email = "jsmith@example.com"
roles_to_add = ["System User", "Accounts User", "Sales User"]

# Get or create user
if not frappe.db.exists("User", user_email):
    print(f"❌ User {user_email} not found. They need to login via SSO first.")
else:
    user = frappe.get_doc("User", user_email)

    # Add roles
    for role in roles_to_add:
        user.add_roles(role)

    print(f"✅ Added roles to {user_email}:")
    for role in roles_to_add:
        print(f"   - {role}")

    frappe.db.commit()
EOF
"
```

### Common Role Combinations

**Accountant:**
```bash
- System User
- Accounts User
```

**Senior Accountant:**
```bash
- System User
- Accounts Manager
```

**Store Cashier:**
```bash
- System User
- POS Cashier
```

**Sales Person:**
```bash
- System User
- Sales User
- Stock User (if they need inventory access)
```

**Warehouse Manager:**
```bash
- System User
- Stock Manager
- Purchase User
```

**Office Admin:**
```bash
- System User
- Accounts User
- Sales User
- Purchase User
- HR User
```

---

## Common Workflows

### Workflow 1: Onboard New Accountant

**Step 1: Create user in Authentik**
```bash
./scripts/create-dickinson-user.sh
# Choose: 1) Dickinson Admin
# Enter: username, email, name, password
```

**Step 2: User logs in via SSO**
- Give them SSO URL: `<generate fresh URL>`
- They login with Authentik credentials
- ERPNext auto-creates their account

**Step 3: Assign ERPNext roles**
```bash
# Via CLI
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
import frappe
frappe.connect()
user = frappe.get_doc('User', 'newaccountant@example.com')
user.add_roles('System User', 'Accounts User')
frappe.db.commit()
print('✅ Roles assigned')
EOF
"
```

**Step 4: Test access**
- User logs in again
- Verify they can access accounting features

### Workflow 2: Create POS Cashier

**Step 1: Create in Authentik**
```bash
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group

user = User.objects.create(
    username="cashier1",
    email="cashier1@example.com",
    name="Cashier One",
    type="internal"
)
user.set_password("CashierPass123!")
user.save()

group = Group.objects.get(name="Dickinson Admins")
user.ak_groups.add(group)

print(f"✅ Created cashier user: {user.username}")
EOF
```

**Step 2: First SSO login** (creates ERPNext account)

**Step 3: Assign POS roles**
```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
import frappe
frappe.connect()
user = frappe.get_doc('User', 'cashier1@example.com')
user.add_roles('System User', 'POS Cashier')
frappe.db.commit()
print('✅ POS Cashier role assigned')
EOF
"
```

**Step 4: Configure POS Profile** (if needed)
- Login as Administrator
- Go to POS Profile
- Assign cashier to specific POS Profile

### Workflow 3: Bulk User Creation

```bash
# Create CSV file: users.csv
username,email,name,roles
jsmith,jsmith@example.com,John Smith,"System User,Accounts User"
mjones,mjones@example.com,Mary Jones,"System User,Sales User"
bwilson,bwilson@example.com,Bob Wilson,"System User,POS Cashier"

# Run script to process CSV
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group
import csv

group = Group.objects.get(name="Dickinson Admins")

with open('/path/to/users.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        user = User.objects.create(
            username=row['username'],
            email=row['email'],
            name=row['name'],
            type="internal"
        )
        user.set_password("ChangeMe123!")
        user.save()
        user.ak_groups.add(group)
        print(f"✅ Created: {user.username}")
EOF
```

### Workflow 4: Remove User Access

**Step 1: Remove from Authentik group**
```bash
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group

username = "olduser"
user = User.objects.get(username=username)
group = Group.objects.get(name="Dickinson Admins")
user.ak_groups.remove(group)

print(f"✅ Removed {username} from ERPNext access")
EOF
```

**Step 2: Disable in ERPNext** (optional)
```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
import frappe
frappe.connect()
user = frappe.get_doc('User', 'olduser@example.com')
user.enabled = 0
user.save()
frappe.db.commit()
print('✅ User disabled in ERPNext')
EOF
"
```

---

## Quick Reference

### Generate Fresh SSO URL

```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
from frappe.utils.oauth import get_oauth2_authorize_url
print(get_oauth2_authorize_url('authentik', redirect_to='/app'))
EOF
"
```

### List All Users with Groups

```bash
./scripts/list-users-by-group.sh
```

### List All Authentik Users

```bash
./scripts/list-authentik-users.sh
```

### Check User's ERPNext Roles

```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
import frappe
frappe.connect()

email = 'user@example.com'
user = frappe.get_doc('User', email)

print(f'\nRoles for {user.name} ({email}):')
print('='*50)
for role in user.roles:
    print(f'  - {role.role}')
print('='*50 + '\n')
EOF
"
```

### Reset User Password (Authentik)

```bash
./scripts/reset-authentik-password.sh
```

---

## Troubleshooting

### User Can't Access ERPNext

**Check 1: Is user in authorized group?**
```bash
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User
user = User.objects.get(username="username")
groups = user.ak_groups.all()
print(f"Groups for {user.username}:")
for g in groups:
    print(f"  - {g.name}")
EOF
```

**Check 2: Does user have ERPNext roles?**
- Login to ERPNext as Administrator
- User List → Find user → Check Roles section

**Check 3: Generate fresh SSO URL**
- State tokens expire
- Generate new URL with command above

### User Has Access But Can't Do Anything

**Issue**: User logged in but sees "Not Permitted" errors in ERPNext

**Fix**: Assign roles in ERPNext
```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && cat <<'EOF' | bench --site erp.byrne-accounts.org console
import frappe
frappe.connect()
user = frappe.get_doc('User', 'user@example.com')
user.add_roles('System User', 'Accounts User')  # Add appropriate roles
frappe.db.commit()
EOF
"
```

---

## Security Best Practices

1. **Principle of Least Privilege**
   - Only assign roles users actually need
   - Review access quarterly

2. **Group-Based Access**
   - Use Authentik groups for access control
   - Don't grant individual user access

3. **Strong Passwords**
   - Require 12+ characters
   - Enforce complexity
   - Enable 2FA for admins

4. **Regular Audits**
   - Review user list monthly
   - Remove inactive users
   - Check role assignments

5. **Separation of Duties**
   - Don't give one user all roles
   - Require approval workflows
   - Log all admin actions

---

## Summary

**✅ Current Status:**
- User `tristian` added to `Dickinson Admins` group
- Can now access ERPNext via SSO
- Fresh SSO URL generated and ready

**🎯 Next Steps:**
1. Test SSO login with the URL above
2. Assign ERPNext roles after first login
3. Create additional users as needed

**📚 Scripts Available:**
- `./scripts/create-sysadmin-user.sh` - Full access users
- `./scripts/create-dickinson-user.sh` - Organization users
- `./scripts/list-users-by-group.sh` - View user groups
- `./scripts/list-authentik-users.sh` - List all users

---

**For Support:**
- See `docs/SSO_USER_MANAGEMENT.md` for more details
- Check `docs/ERPNEXT_SSO_FINAL_WORKING.md` for SSO configuration
