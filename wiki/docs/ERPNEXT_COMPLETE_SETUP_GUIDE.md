# ERPNext & POS Awesome Complete Setup Guide

This guide walks you through the complete setup of ERPNext with POS Awesome and custom branding for Byrne Accounting.

## Table of Contents
1. [Initial ERPNext Setup Wizard](#initial-erpnext-setup-wizard)
2. [POS Awesome Configuration](#pos-awesome-configuration)
3. [Custom Branding](#custom-branding)
4. [User Management](#user-management)
5. [Final Testing](#final-testing)

---

## Initial ERPNext Setup Wizard

### Step 1: Access ERPNext

1. Open your browser and navigate to: **https://erp.byrne-accounts.org**
2. You'll be redirected to the login page

### Step 2: First Login

**Default Credentials:**
- Username: `Administrator`
- Password: Run `cat /home/tristian/securenexus-fullstack/secrets/erpnext_admin_password.txt` to get the password

3. Click **Login**

### Step 3: Setup Wizard

After logging in for the first time, you'll see the Setup Wizard. Follow these steps:

#### Language & Region
1. **Language**: Select `English (United Kingdom)`
2. **Country**: Select `United Kingdom`
3. **Timezone**: Select your timezone (e.g., `Europe/London`)
4. Click **Next**

#### Company Information
1. **Company Name**: `Byrne Accounting` (or your company name)
2. **Company Abbreviation**: `BA` (used for naming series)
3. **Default Currency**: `GBP` (British Pound)
4. **Fiscal Year Start Date**: `04-01` (April 1st - UK tax year)
5. **Fiscal Year End Date**: `03-31` (March 31st)
6. **Company Domain**: Select `Services` or relevant domain
7. Click **Next**

#### Add Your Products
1. **What do you sell?**:
   - If you're providing accounting services, select "Services"
   - Or add custom product/service categories
2. Click **Next**

#### Goals
1. Select modules you want to use:
   - ✅ **Accounting** (essential)
   - ✅ **Selling** (for POS)
   - ✅ **Buying** (if purchasing supplies)
   - ✅ **Stock** (for inventory)
   - ✅ **HR** (if managing employees)
   - ✅ **CRM** (customer relationship management)
2. Click **Next**

#### Add Users
1. **Skip for now** - We'll add users later
2. Click **Next**

#### Brand & Logo
1. **Upload Company Logo**: Upload your logo (we'll customize this later)
2. **Brand Color**: Choose your primary color
3. Click **Next**

#### Complete Setup
1. Review your settings
2. Click **Complete Setup**
3. Wait for ERPNext to initialize (this takes 2-3 minutes)

### Step 4: Explore the Desk

After setup completes, you'll see the ERPNext Desk (home screen) with various modules.

---

## POS Awesome Configuration

### Step 1: Install POS Awesome App

The app is already installed! Verify by:

1. Go to **Desk** (home icon)
2. Click **Awesome icon search** (top right)
3. Type "POS Awesome" - you should see it listed

### Step 2: Create a POS Profile

1. From the **Desk**, use the search bar (Ctrl+K or Cmd+K)
2. Search for **POS Profile**
3. Click **+ New**

#### Basic Settings
- **Profile Name**: `Main Store POS`
- **Enabled**: ✅ Checked
- **Company**: Select your company
- **Currency**: `GBP`

#### Accounting Settings
- **Income Account**: `Sales - BA` (auto-created)
- **Cost Center**: `Main - BA` (auto-created)
- **Expense Account**: `Cost of Goods Sold - BA`

#### Stock Settings
- **Warehouse**: Create a new warehouse or use default
  - To create: Click **+** next to Warehouse field
  - Name: `Main Store`
  - Parent Warehouse: Leave blank or select "All Warehouses"
  - Click **Save**

#### Payment Methods
Add payment methods your store accepts:

1. In the **Payments** table, click **Add Row**
2. **Mode of Payment**: `Cash`
3. **Default**: ✅ Checked
4. **Account**: `Cash - BA`

5. Click **Add Row** again
6. **Mode of Payment**: `Credit Card`
7. **Account**: `Debit To - BA` or create new account

8. Add more payment methods as needed (Mobile Payment, Check, etc.)

#### POS Settings
- **Update Stock**: ✅ Checked (updates inventory in real-time)
- **Ignore Pricing Rule**: ☐ Unchecked
- **Allow User to Edit Rate**: ☐ Unchecked (for better control)
- **Allow User to Edit Discount**: ☐ Unchecked
- **Allow Write Off**: ✅ Checked
- **Write Off Account**: `Write Off - BA`
- **Write Off Cost Center**: `Main - BA`

#### Print Settings
- **Print Format**: `POS Invoice`
- **Letter Head**: Select or create company letterhead

#### Customer Settings
- **Customer**: Leave blank (allows any customer)
- **Customer Group**: `All Customer Groups`
- **Territory**: `All Territories`

Click **Save**

### Step 3: Assign POS Profile to User

1. Search for **User** in the search bar
2. Click on **Administrator** (or the user who will use POS)
3. Scroll down to **POS Settings** section
4. In **POS Profiles** table, click **Add Row**
5. Select the POS Profile you created: `Main Store POS`
6. Click **Save**

### Step 4: Create Sample Items

Before testing POS, create some sample items:

1. Search for **Item** in search bar
2. Click **+ New**

#### Sample Item 1: Service
- **Item Code**: `ACC-CONSULTATION`
- **Item Name**: `Accounting Consultation`
- **Item Group**: `Services`
- **Stock UOM**: `Hour`
- **Standard Selling Rate**: `120.00` (£120 per hour)
- **Valuation Rate**: `0` (for services)
- **Maintain Stock**: ☐ Unchecked
- Click **Save**

#### Sample Item 2: Product
- **Item Code**: `CALC-001`
- **Item Name**: `Desktop Calculator`
- **Item Group**: `Products`
- **Stock UOM**: `Nos`
- **Standard Selling Rate**: `19.99` (£19.99)
- **Valuation Rate**: `12.00` (£12.00)
- **Maintain Stock**: ✅ Checked
- **Opening Stock**:
  - Click **Edit Opening Stock** button
  - Warehouse: `Main Store`
  - Qty: `50`
  - Valuation Rate: `15.00`
  - Click **Update**
- Click **Save**

Create a few more items for testing purposes.

### Step 5: Test POS Awesome

1. Navigate to: **https://pos.byrne-accounts.org**
2. Or from ERPNext Desk, search for **POS** and click **POS Awesome**
3. Login with your ERPNext credentials
4. You should see the POS interface with:
   - Item list on the left
   - Shopping cart on the right
   - Payment options at bottom

#### Test Transaction:
1. Click on an item to add to cart
2. Adjust quantity if needed
3. Click **Checkout**
4. Select payment method (Cash/Credit Card)
5. Enter amount received
6. Click **Complete Order**
7. You'll see a success message and can print receipt

---

## Custom Branding

Now let's apply SecureNexus branding to ERPNext.

### Step 1: Apply Custom Branding

Run this command from your terminal:

```bash
docker exec -it erpnext-backend /custom-branding/install-branding.sh
```

This will:
- Add SecureNexus logo to login page
- Customize colors (blue: #3b82f6, green: #10b981)
- Add custom CSS styling
- Set up company branding

### Step 2: Upload Company Logo

1. In ERPNext, search for **Company**
2. Click on your company name
3. Scroll to **Default Settings** section
4. **Company Logo**: Upload your logo
   - Recommended size: 200x80 pixels
   - Format: PNG with transparent background
5. Click **Save**

### Step 3: Create Letterhead

1. Search for **Letter Head**
2. Click **+ New**
3. **Letter Head Name**: `Byrne Accounting Letterhead`
4. **Is Default**: ✅ Checked
5. **Header**: Upload header image or use HTML:

```html
<div style="text-align: center;">
    <h2 style="color: #3b82f6;">Byrne Accounting</h2>
    <p>Professional Accounting Services</p>
    <p>123 High Street | City, County, AB12 3CD | 020 1234 5678</p>
    <p>info@byrne-accounts.org | www.byrne-accounts.org</p>
</div>
```

6. **Footer**: Add footer text (optional)
7. Click **Save**

### Step 4: Customize Print Formats

1. Search for **Print Format**
2. Find **POS Invoice**
3. Click **Duplicate**
4. **Print Format Name**: `Byrne POS Invoice`
5. Click **Edit Format**
6. Customize as needed:
   - Add/remove fields
   - Change layout
   - Add branding elements
7. Click **Save**

### Step 5: Update POS Profile with Branding

1. Go back to **POS Profile** → `Main Store POS`
2. **Letter Head**: Select `Byrne Accounting Letterhead`
3. **Print Format**: Select `Byrne POS Invoice`
4. Click **Save**

### Step 6: Customize Desk Theme

1. Click on your profile icon (top right)
2. Go to **My Settings**
3. Scroll to **Theme** section
4. **Desk Theme**: Choose `Light` or `Dark`
5. Click **Save**

### Step 7: Test Branding

1. Logout of ERPNext
2. Check the login page - should show custom branding
3. Login again
4. Navigate to POS
5. Make a test transaction and print - should show custom letterhead

---

## User Management

### Create POS User (Cashier)

1. Search for **User**
2. Click **+ New**
3. **Email**: `cashier@byrne-accounts.org` (or actual email)
4. **First Name**: `Store`
5. **Last Name**: `Cashier`
6. **Send Welcome Email**: ☐ Unchecked (set password manually)
7. **Language**: `en`
8. **Timezone**: Your timezone

#### Roles
In the **Roles** table, add these roles:
- `Sales User`
- `Stock User`
- `Accounts User`
- `Sales Manager` (if they need advanced permissions)

#### POS Settings
- **POS Profiles**: Add `Main Store POS`

#### Set Password
1. Scroll to **Change Password** section
2. **New Password**: Create a secure password
3. **Confirm Password**: Repeat password
4. Click **Save**

### Create Manager User

1. Create another user for management
2. Assign roles:
   - `Sales Manager`
   - `Stock Manager`
   - `Accounts Manager`
   - `System Manager`

---

## Final Testing

### Test Checklist

#### ✅ ERPNext Core
- [ ] Login with Administrator works
- [ ] All modules are visible
- [ ] Company settings are correct
- [ ] Logo displays properly
- [ ] Letterhead is set up

#### ✅ POS Awesome
- [ ] POS interface loads at pos.byrne-accounts.org
- [ ] Items display in POS
- [ ] Can add items to cart
- [ ] Can process payment
- [ ] Receipt prints with branding
- [ ] Stock updates after sale

#### ✅ Branding
- [ ] Login page shows custom branding
- [ ] Company logo appears in desk
- [ ] Print formats use letterhead
- [ ] Colors match brand guidelines
- [ ] Footer shows company info

#### ✅ User Access
- [ ] Cashier can login
- [ ] Cashier has access to POS only
- [ ] Manager has full access
- [ ] Permissions are correct

### Common Test Transactions

#### Test 1: Cash Sale
1. Login to POS
2. Add 2 items to cart
3. Click Checkout
4. Select Cash payment
5. Enter exact amount
6. Complete order
7. Verify receipt prints
8. Check stock updated in ERPNext

#### Test 2: Credit Card Sale
1. Add items to cart
2. Click Checkout
3. Select Credit Card
4. Enter amount
5. Complete order
6. Verify transaction in Accounts

#### Test 3: Mixed Payment
1. Add items totaling £100
2. Click Checkout
3. Pay £50 Cash
4. Pay £50 Credit Card
5. Complete order
6. Verify split payment recorded

---

## Troubleshooting

### POS Not Loading
```bash
# Check if services are running
docker compose ps | grep erpnext

# Restart POS-related services
docker compose restart erpnext-backend erpnext-socketio
```

### Items Not Showing in POS
1. Check POS Profile has correct Item Groups
2. Verify items are enabled
3. Check warehouse has stock (if Maintain Stock is checked)

### Branding Not Applying
```bash
# Reapply branding
docker exec -it erpnext-backend /custom-branding/install-branding.sh

# Clear cache
docker exec -it erpnext-backend bench --site erp.byrne-accounts.org clear-cache
```

### Permission Issues
1. Check User Roles in User master
2. Verify POS Profile is assigned to user
3. Check Role Permission Manager for specific permissions

---

## Next Steps

After completing this setup:

1. **Configure Additional Settings**
   - Tax rates (Settings > Tax Rate) - Add UK VAT rates (20% standard, 5% reduced, 0% zero-rated)
   - Price lists (Selling > Price List)
   - Customer groups
   - Supplier master

2. **Import Data** (if migrating)
   - Items
   - Customers
   - Suppliers
   - Opening balances

3. **Set Up Integrations**
   - Email (SMTP settings)
   - Payment gateways
   - Shipping providers

4. **Configure Reports**
   - Sales reports
   - Inventory reports
   - Financial reports

5. **Training**
   - Train cashiers on POS
   - Train managers on reporting
   - Document procedures

---

## Support Resources

- **ERPNext Documentation**: https://docs.erpnext.com
- **POS Awesome GitHub**: https://github.com/yrestom/POS-Awesome
- **ERPNext Forum**: https://discuss.erpnext.com
- **Video Tutorials**: https://www.youtube.com/c/ERPNextOrg

---

## Backup & Maintenance

### Daily Backups
Backups are automated at 2:00 AM daily. Check backup status:

```bash
ls -lh /backup/securenexus/daily/
```

### Manual Backup
```bash
docker exec -it erpnext-backend bench --site erp.byrne-accounts.org backup
```

### Update ERPNext
```bash
# Pull latest image
docker pull frappe/erpnext:latest

# Rebuild custom image
docker build -f Dockerfile.erpnext-posawesome -t erpnext-posawesome:latest .

# Restart services
docker compose up -d erpnext-backend erpnext-worker erpnext-scheduler
```

---

**Setup Complete!** 🎉

Your ERPNext system with POS Awesome is now fully configured and branded.
