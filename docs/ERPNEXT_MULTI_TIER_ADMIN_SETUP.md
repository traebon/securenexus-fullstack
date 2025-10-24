# ERPNext Multi-Tier Admin Setup Guide

## 🎯 Overview

This guide shows how to set up a **hierarchical admin structure** where you maintain super-admin control over all client sites while giving clients limited administrative access.

**Your Role**: System Administrator (full control, can fix anything)
**Client Role**: Client Administrator (restricted, can't break critical settings)

---

## 🏗️ Admin Hierarchy Structure

```
┌─────────────────────────────────────────────┐
│  YOU (System Administrator)                 │
│  - Username: sysadmin@byrne-accounts.org    │
│  - Full system access                       │
│  - Can modify: System Settings, Users,      │
│    Roles, Permissions, Customizations       │
│  - Can reset client passwords               │
│  - Can fix broken configurations            │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│  CLIENT (Client Administrator)              │
│  - Username: admin@dickinson.byrne-acc...   │
│  - Limited admin access                     │
│  - Can: Create users, manage data,          │
│    run reports, customize forms             │
│  - Cannot: Modify system settings,          │
│    install apps, run scripts, change roles  │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│  CLIENT USERS (Standard Users)              │
│  - Employees, managers, POS operators       │
│  - Role-based access (Sales, Accounts, etc) │
│  - Limited to their department/functions    │
└─────────────────────────────────────────────┘
```

---

## 🚀 Step-by-Step Setup

### Part 1: Initial Setup (First Login)

When you first create a client site (like dickinson), you login as `Administrator` to set everything up.

#### Step 1: Change Administrator Password

1. **Login**: https://dickinson.byrne-accounts.org
   - Username: `Administrator`
   - Password: From `client-credentials/dickinson.byrne-accounts.org.txt`

2. **Go to**: User menu (top right) → My Settings

3. **Change Password**: Set a strong password only YOU know

4. **Save credentials securely**:
   ```bash
   # On your server
   cat >> client-credentials/dickinson.byrne-accounts.org.txt <<EOF

   SUPER ADMIN ACCESS (Tristian Only):
   Username: Administrator
   Password: YOUR_NEW_STRONG_PASSWORD
   Purpose: System recovery, major fixes, super-admin tasks
   EOF
   ```

---

### Part 2: Create Your Super-Admin User

Instead of using `Administrator` for daily tasks, create your own user:

#### Step 1: Create Your System Admin User

1. **Search**: "User" (Ctrl+K)

2. **Click**: "+ New"

3. **Fill in**:
   ```
   Email: sysadmin@byrne-accounts.org
   First Name: Tristian
   Last Name: (Your name)

   Send Welcome Email: ☐ Unchecked

   ===== Roles =====
   ☑ System Manager (full admin access)
   ☑ Administrator
   ☑ All (optional - gives access to all modules)
   ```

4. **Set Password**:
   - Click "Set New Password"
   - Enter your password
   - Send: No (don't email it)

5. **User Type**: System User

6. **Save**

**Result**: You now have `sysadmin@byrne-accounts.org` with full control

---

### Part 3: Create "Client Administrator" Role

This is the restricted admin role you'll give to clients.

#### Step 1: Create Custom Role

1. **Search**: "Role" (Ctrl+K)

2. **Click**: "+ New"

3. **Fill in**:
   ```
   Role Name: Client Administrator
   Desk Access: ☑ Checked

   ===== Permissions =====
   (These are set in the next step via "Role Permission Manager")
   ```

4. **Save**

#### Step 2: Configure Role Permissions

1. **Search**: "Role Permission Manager"

2. **Select Role**: "Client Administrator"

3. **Grant permissions for these DocTypes**:

   **✅ ALLOW (Client needs these)**:
   - Company (Read only)
   - Customer (All permissions)
   - Supplier (All permissions)
   - Item (All permissions)
   - Sales Invoice (All permissions)
   - Purchase Invoice (All permissions)
   - Payment Entry (All permissions)
   - Stock Entry (All permissions)
   - POS Profile (Read, Write, Create - not Delete)
   - User (Read, Write, Create - NOT Delete, NOT "Set User Permissions")
   - Report (All)
   - Dashboard (All)
   - Email Account (Read only)
   - Print Format (All)

   **❌ DENY (System-critical - keep control)**:
   - System Settings (No access)
   - Role (No access)
   - Role Permission for Page and Report (No access)
   - DocType (No access)
   - Custom Field (No access)
   - Server Script (No access)
   - Client Script (No access)
   - Workflow (No access)
   - Email Domain (No access)
   - Installed Applications (No access)

4. **Save permissions**

---

### Part 4: Create Client Admin User

Now create the actual user account you'll hand over to the client:

#### Step 1: Create Client User

1. **Search**: "User" (Ctrl+K)

2. **Click**: "+ New"

3. **Fill in**:
   ```
   Email: admin@dickinson.byrne-accounts.org
   First Name: Dickinson
   Last Name: Admin

   ===== Roles =====
   ☑ Client Administrator (your custom role)
   ☑ Accounts Manager
   ☑ Accounts User
   ☑ Sales Manager
   ☑ Purchase Manager
   ☑ Stock Manager
   ☑ HR Manager
   (Select roles based on what client needs)

   ☐ System Manager (DO NOT CHECK - this is super-admin)
   ☐ Administrator (DO NOT CHECK)
   ```

4. **Set Password**: Strong password for client

5. **User Type**: System User

6. **Language**: English (or client preference)

7. **Save**

#### Step 2: Save Client Credentials

```bash
cat >> client-credentials/dickinson.byrne-accounts.org.txt <<EOF

CLIENT ADMIN ACCESS (For Dickinson):
Username: admin@dickinson.byrne-accounts.org
Password: CLIENT_PASSWORD_HERE
Role: Client Administrator (restricted)
Can: Manage users, data, reports, customizations
Cannot: Modify system settings, roles, install apps
EOF
```

---

### Part 5: Testing the Hierarchy

#### Test 1: Login as Client Admin

1. **Logout** from current session

2. **Login** as `admin@dickinson.byrne-accounts.org`

3. **Try to access**: Settings → System Settings
   - **Expected**: "Insufficient permissions" or not visible

4. **Try to access**: Users → Role List
   - **Expected**: "Insufficient permissions" or not visible

5. **Try to create**: A new user
   - **Expected**: Should work! ✅

6. **Try to create**: A new customer
   - **Expected**: Should work! ✅

#### Test 2: Client Admin CANNOT Break Things

Try these as client admin (should all FAIL):

1. **Install App**: Home → Apps → Install
   - **Expected**: Not visible or permission denied ✅

2. **Modify Roles**: Users → Role
   - **Expected**: Not visible or read-only ✅

3. **System Settings**: Settings → System Settings
   - **Expected**: Not accessible ✅

4. **Run Server Script**: Developer → Server Script
   - **Expected**: Not visible ✅

#### Test 3: You CAN Fix Everything

1. **Logout** and login as `sysadmin@byrne-accounts.org`

2. **Access**: Settings → System Settings
   - **Expected**: Full access ✅

3. **Access**: Users → Role List
   - **Expected**: Can modify ✅

4. **Reset client password**: Users → User → admin@dickinson...
   - **Expected**: Can change password ✅

---

## 🔒 Additional Security Layers

### 1. Restrict Dangerous Operations

Even for Client Administrator, restrict these:

#### Via "Customize Form" Tool

1. **Search**: "Customize Form"

2. **Select**: "User"

3. **Find field**: "Roles"

4. **Set**: Read Only = Yes (for Client Administrator role)

5. **Save** and **Update**

**Result**: Client admins can create users but can't assign dangerous roles

### 2. Hide Sensitive Modules

1. **Search**: "Module Def"

2. **For each sensitive module** (Setup, Customize, Developer Tools):
   - Open the module
   - Under "Restrict to Domain", set domain
   - Or create a custom permission rule

### 3. User Permission Restrictions

For extra isolation (optional for multi-company):

1. **Search**: "User Permissions"

2. **Create rule** for client admin:
   - User: admin@dickinson.byrne-accounts.org
   - Allow: Company
   - For Value: Dickinson's Company Name
   - **Result**: Client can only see their company's data

---

## 🛠️ Common Admin Tasks

### When Client Needs Help

**Scenario 1**: Client forgot password

```bash
# Login as sysadmin@byrne-accounts.org
# Or use Administrator account

# Reset their password via UI:
# Users → User → admin@dickinson... → Set New Password
```

**Scenario 2**: Client broke a form customization

```bash
# Login as sysadmin@byrne-accounts.org

# Remove customization:
# Customize Form → Select DocType → Clear Customizations
```

**Scenario 3**: Client needs new permission

```bash
# Login as sysadmin@byrne-accounts.org

# Update Client Administrator role:
# Role Permission Manager → Client Administrator → Add permission
```

### When You Need to Prevent Access

**Temporarily lock client admin**:

1. **Search**: "User" → admin@dickinson...
2. **Check**: "Disabled"
3. **Save**

Client cannot login until you uncheck this.

---

## 📋 Role Permission Checklist

Use this when setting up new client sites:

### ✅ Client Administrator CAN:
- [ ] Create/edit customers, suppliers, items
- [ ] Create/edit invoices, payments, stock entries
- [ ] Generate reports and dashboards
- [ ] Create/edit users (with role restrictions)
- [ ] Customize print formats
- [ ] Create/edit POS profiles
- [ ] Manage email templates
- [ ] View and respond to emails

### ❌ Client Administrator CANNOT:
- [ ] Access System Settings
- [ ] Create/modify roles
- [ ] Grant/revoke permissions
- [ ] Install/uninstall apps
- [ ] Write server scripts
- [ ] Modify DocType structures
- [ ] Access database directly
- [ ] Change system-level email settings
- [ ] Disable system users (like your account)

---

## 🔐 Super-Admin Access Across All Sites

For each client site you create, follow this pattern:

### Site 1: dickinson.byrne-accounts.org
```
Super Admin: Administrator (emergency only)
Your Account: sysadmin@byrne-accounts.org (daily use)
Client Admin: admin@dickinson.byrne-accounts.org
```

### Site 2: client2.byrne-accounts.org
```
Super Admin: Administrator (emergency only)
Your Account: sysadmin@byrne-accounts.org (daily use)
Client Admin: admin@client2.byrne-accounts.org
```

### Site 3: Your own site (erp.byrne-accounts.org)
```
Super Admin: Administrator (emergency only)
Your Account: sysadmin@byrne-accounts.org (daily use)
Staff Users: Various roles
```

**Key Pattern**:
- `sysadmin@byrne-accounts.org` exists on ALL sites with System Manager role
- Each client gets their own `admin@clientsite.byrne-accounts.org`
- Keep `Administrator` password safe as last resort

---

## 🚨 Emergency Access

If you ever get locked out:

### Option 1: Use Administrator Account

The built-in `Administrator` account always has full access.

### Option 2: Reset Password via Command Line

```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site dickinson.byrne-accounts.org set-admin-password NEW_PASSWORD"
```

This resets the `Administrator` password.

### Option 3: Create New User via Console

```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site dickinson.byrne-accounts.org add-system-manager \
  recovery@byrne-accounts.org SECURE_PASSWORD"
```

---

## 📊 Monitoring Client Actions

### View User Activity

1. **Search**: "Activity Log"
2. **Filter**: User = admin@dickinson.byrne-accounts.org
3. **See**: What they created, edited, deleted

### Email Alerts for Critical Actions

Set up email alerts for:
- User creation/deletion
- Role changes
- System setting modifications
- Data export/import

**Setup**: Search "Email Alert" → Create rules

---

## 🎓 Training the Client Admin

When handing over access, explain:

### ✅ What They CAN Do:
- "You can manage all daily operations"
- "Create users for your team"
- "Run reports and customize layouts"
- "Manage customers, items, invoices"
- "Configure POS profiles"

### ⚠️ What They CANNOT Do:
- "I maintain system-level settings for stability"
- "If you need roles changed, contact me"
- "Don't try to install apps - I handle that"
- "System maintenance is handled by me"

### 🆘 When to Contact You:
- "If you need a feature that's blocked"
- "If a user needs special permissions"
- "If something breaks"
- "Before making major changes"

---

## 🔄 Maintaining Multiple Client Sites

### Create a Master Checklist

```bash
# Create tracking file
cat > /home/tristian/securenexus-fullstack/client-admin-tracking.txt <<EOF
SITE: dickinson.byrne-accounts.org
Super Admin: Administrator / [password in client-credentials]
Your Access: sysadmin@byrne-accounts.org / [your password]
Client Admin: admin@dickinson.byrne-accounts.org / [in client-credentials]
Setup Date: $(date)
Client Administrator Role: Configured ✅
Email Domain: admin@dickinson.byrne-accounts.org ✅
Status: Active

---

SITE: client2.byrne-accounts.org
[Repeat for each client]

---
EOF
```

### Password Management

Use a password manager like:
- **Bitwarden** (self-hosted)
- **KeePass** (offline)
- **1Password** (commercial)

Store:
- Administrator passwords (per site)
- Your sysadmin password (same across sites)
- Client admin passwords (per site)

---

## 🎯 Quick Reference

### Login as Super Admin
```
Site: https://dickinson.byrne-accounts.org
User: sysadmin@byrne-accounts.org
Pass: [Your super-admin password]
Role: System Manager
```

### Login as Client Admin
```
Site: https://dickinson.byrne-accounts.org
User: admin@dickinson.byrne-accounts.org
Pass: [Client's password]
Role: Client Administrator (restricted)
```

### Reset Any Password
```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site SITENAME.byrne-accounts.org set-admin-password NEWPASS"
```

### Create System Manager on Any Site
```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site SITENAME.byrne-accounts.org add-system-manager \
  sysadmin@byrne-accounts.org PASSWORD"
```

---

## 📚 Next Steps

1. ✅ Set up Administrator password (strong, secure)
2. ✅ Create your sysadmin@byrne-accounts.org user
3. ✅ Create "Client Administrator" role with restrictions
4. ✅ Create client admin user (admin@dickinson.byrne-accounts.org)
5. ✅ Test both accounts
6. ✅ Document credentials securely
7. ✅ Set up email integration (see ERPNEXT_MAILCOW_INTEGRATION.md)
8. ✅ Train client on their access level

---

**You now have full control while clients have safe, limited access!** 🎉
