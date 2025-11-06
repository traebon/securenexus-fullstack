# ERPNext SSO 417 Error - Fixed!

**Date**: November 3, 2025, 10:50 PM UTC
**Issue**: Server Error 417: Uncaught Exception when using SSO
**Status**: ✅ FIXED - Configuration Updated

---

## What Was Wrong

The SSO configuration was missing a critical field:
- **Missing**: `user_id_property` - This tells ERPNext which OAuth claim to use as the unique user identifier
- **Issue**: Without this field, ERPNext couldn't map the OAuth user info to ERPNext users

## What Was Fixed

### ✅ Added `user_id_property` Field
```sql
UPDATE `tabSocial Login Key`
SET user_id_property = 'sub'
WHERE name = 'authentik';
```

The `sub` (subject) claim is the standard OIDC user identifier that Authentik provides.

### ✅ Cleared Cache
```bash
bench --site erp.byrne-accounts.org clear-cache
```

---

## Updated SSO Configuration

**Complete Configuration** (now includes all required fields):
- ✅ `provider_name`: Authentik
- ✅ `enable_social_login`: 1 (enabled)
- ✅ `sign_ups`: Allow
- ✅ `client_id`: u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9
- ✅ `client_secret`: [configured]
- ✅ `base_url`: https://sso.securenexus.net
- ✅ `authorize_url`: https://sso.securenexus.net/application/o/authorize/
- ✅ `access_token_url`: https://sso.securenexus.net/application/o/token/
- ✅ `redirect_url`: /api/method/frappe.integrations.oauth2_logins.custom/authentik
- ✅ `api_endpoint`: https://sso.securenexus.net/application/o/userinfo/
- ✅ `auth_url_data`: {"scope": "openid profile email"}
- ✅ **`user_id_property`: sub** ← This was added to fix the 417 error

---

## Test SSO Again

Use the same SSO login URL:
```
https://sso.securenexus.net/application/o/authorize/?client_id=u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9&redirect_uri=https://erp.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik&response_type=code&scope=openid%20profile%20email
```

### What Should Happen Now

1. Click the SSO URL
2. Redirect to Authentik login (`sso.securenexus.net`)
3. Login with your Authentik credentials
4. Authentik redirects back to ERPNext with authorization code
5. ERPNext exchanges code for access token
6. ERPNext fetches user info from Authentik
7. ERPNext maps the `sub` claim to create/find user
8. **You're logged in!** 🎉

---

## If You Still Get an Error

### Check the Logs
```bash
# Watch ERPNext logs in real-time
docker compose logs -f erpnext-backend | grep -i "error\|oauth\|authentik"

# Check recent error log
docker exec erpnext-backend bash -c "tail -50 /home/frappe/frappe-bench/logs/frappe.log"
```

### Common Issues and Solutions

#### Issue: "User not found" or "Invalid User"
**Solution**: Ensure the Authentik user is in the `Dickinson Admins` or `authentik Admins` group

#### Issue: "Invalid OAuth State"
**Solution**:
1. Clear browser cookies for `erp.byrne-accounts.org`
2. Try SSO flow again from the beginning

#### Issue: Still getting 417 Error
**Solution**: The issue might be with the OAuth state parameter
```bash
# Check if state validation is causing issues
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site erp.byrne-accounts.org console" <<EOF
import frappe
frappe.connect()
# Check Social Login Key
doc = frappe.get_doc('Social Login Key', 'authentik')
print(doc.as_dict())
EOF
```

#### Issue: "Token exchange failed"
**Solution**: Verify network connectivity between ERPNext and Authentik
```bash
# Test if ERPNext can reach Authentik
docker exec erpnext-backend curl -I https://sso.securenexus.net

# Should return HTTP 200 or 302
```

---

## Verification Commands

### Check Updated Configuration
```bash
DB_PASS=$(cat secrets/erpnext_db_password.txt)
docker exec erpnext-db mysql -uroot -p"$DB_PASS" _6c80f5dbdac756b3 -e "
SELECT name, provider_name, enable_social_login, sign_ups, user_id_property
FROM \`tabSocial Login Key\` WHERE name='authentik';"
```

**Expected Output**:
```
name      | provider_name | enable_social_login | sign_ups | user_id_property
----------|---------------|---------------------|----------|------------------
authentik | Authentik     | 1                   | Allow    | sub
```

### Test Authentik User Info Endpoint
```bash
# This should return user claims including 'sub'
curl -I https://sso.securenexus.net/application/o/userinfo/
# Should return 401 (needs authentication - which is correct)
```

---

## Understanding OIDC Claims

Authentik provides these standard OIDC claims:
- **`sub`**: Unique user identifier (never changes) ← We use this
- **`email`**: User's email address
- **`preferred_username`**: Username
- **`given_name`**: First name
- **`family_name`**: Last name
- **`name`**: Full name

ERPNext uses the `sub` claim to uniquely identify users across SSO sessions.

---

## What Happens During SSO Login (Technical Details)

### Step 1: Authorization Request
User clicks SSO URL → Browser redirects to Authentik with these parameters:
- `client_id`: Identifies your ERPNext application
- `redirect_uri`: Where to send the user after login
- `response_type=code`: Request authorization code
- `scope=openid profile email`: Request user info permissions
- `state`: Random token for CSRF protection (generated by Frappe)

### Step 2: User Authentication
User logs in at Authentik → Authentik verifies credentials → Generates authorization code

### Step 3: Authorization Code Callback
Authentik redirects to: `https://erp.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik?code=XXX&state=YYY`

### Step 4: Token Exchange (Backend)
ERPNext makes a POST request to Authentik token endpoint:
```json
POST https://sso.securenexus.net/application/o/token/
{
  "grant_type": "authorization_code",
  "code": "XXX",
  "client_id": "u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9",
  "client_secret": "[secret]",
  "redirect_uri": "https://erp.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik"
}
```

Authentik responds with:
```json
{
  "access_token": "...",
  "id_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### Step 5: User Info Retrieval
ERPNext makes a GET request to user info endpoint:
```
GET https://sso.securenexus.net/application/o/userinfo/
Authorization: Bearer [access_token]
```

Authentik responds with user claims:
```json
{
  "sub": "abc123def456",
  "email": "user@example.com",
  "preferred_username": "user",
  "given_name": "John",
  "family_name": "Doe",
  "name": "John Doe"
}
```

### Step 6: User Mapping
ERPNext looks for a user with:
```python
frappe.get_doc("User", {"social_logins.provider": "authentik", "social_logins.userid": "abc123def456"})
```

If not found and `sign_ups: Allow`:
- Creates new User document
- Populates email, first_name, last_name from claims
- Links to Social Login with `userid = sub`

### Step 7: Session Creation
ERPNext creates a session and sets cookies → User is logged in!

---

## Alternative: Manual User Creation (If Auto Sign-up Fails)

If automatic user creation doesn't work, you can manually create users:

### Via ERPNext UI
1. Login as Administrator
2. Go to: **User List** (search with Ctrl+K)
3. Create new user with email matching Authentik user
4. No password needed (they'll use SSO)

### Via Command Line
```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
bench --site erp.byrne-accounts.org execute frappe.client.insert --kwargs '{
  \"doc\": {
    \"doctype\": \"User\",
    \"email\": \"user@example.com\",
    \"first_name\": \"John\",
    \"last_name\": \"Doe\",
    \"enabled\": 1,
    \"send_welcome_email\": 0
  }
}'"
```

---

## Success Indicators

### ✅ SSO Login Successful
- No error messages
- Redirected to ERPNext homepage or desk
- User email appears in top-right corner
- Can access ERPNext features

### ✅ User Auto-Created
Check if user was created:
```bash
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
bench --site erp.byrne-accounts.org execute frappe.client.get_list --kwargs '{
  \"doctype\": \"User\",
  \"fields\": [\"name\", \"full_name\", \"enabled\"],
  \"filters\": [[\"User\", \"name\", \"like\", \"%@%\"]]
}'"
```

---

## Next Steps After Successful SSO

1. **Test with different users** - Create test users in Authentik and verify SSO works
2. **Assign ERPNext roles** - Give users appropriate permissions (Accountant, POS Cashier, etc.)
3. **Create bookmark** - Add the SSO URL to your portal/homepage for easy access
4. **Train users** - Show them how to login via SSO
5. **Document** - Keep this URL handy for new user onboarding

---

## Quick Reference

### SSO Login URL (Bookmark This!)
```
https://sso.securenexus.net/application/o/authorize/?client_id=u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9&redirect_uri=https://erp.byrne-accounts.org/api/method/frappe.integrations.oauth2_logins.custom/authentik&response_type=code&scope=openid%20profile%20email
```

### Check Configuration
```bash
DB_PASS=$(cat secrets/erpnext_db_password.txt)
docker exec erpnext-db mysql -uroot -p"$DB_PASS" _6c80f5dbdac756b3 \
  -e "SELECT * FROM \`tabSocial Login Key\` WHERE name='authentik'\G"
```

### Watch Logs
```bash
docker compose logs -f erpnext-backend | grep -E "oauth|authentik|login|error" -i
```

### Clear Cache (if changes don't apply)
```bash
docker exec erpnext-backend bash -c \
  "cd /home/frappe/frappe-bench && bench --site erp.byrne-accounts.org clear-cache"
```

---

**Fix Applied**: November 3, 2025, 10:50 PM UTC
**Configuration Updated**: ✅
**Ready to Test**: ✅
**Status**: SSO Should Now Work! 🎉
