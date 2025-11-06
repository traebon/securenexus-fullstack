#!/bin/bash
# Setup Dickinson Accounts SSO Structure
# Creates groups and organizational structure for Dickinson accounts system

set -euo pipefail

echo "==============================================================================="
echo "DICKINSON ACCOUNTS SSO SETUP"
echo "==============================================================================="
echo ""

# Create Dickinson Admins group
echo "Creating Dickinson Admins group..."
docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import Group

# Create Dickinson Admins group
dickinson_admins, created = Group.objects.get_or_create(
    name="Dickinson Admins",
    defaults={
        "is_superuser": False,  # Not full system superuser, just Dickinson admin
    }
)

if created:
    print("✅ Created 'Dickinson Admins' group")
    # Set attributes for the group
    dickinson_admins.attributes = {
        "description": "Administrative users for Dickinson accounts system",
        "permissions": ["manage_users", "manage_accounts", "view_reports"]
    }
    dickinson_admins.save()
else:
    print("ℹ️  'Dickinson Admins' group already exists")

# Verify Dickinson Users group exists
dickinson_users, created = Group.objects.get_or_create(
    name="Dickinson Users",
    defaults={
        "is_superuser": False,
    }
)

if created:
    print("✅ Created 'Dickinson Users' group")
    dickinson_users.attributes = {
        "description": "Regular users for Dickinson accounts system",
        "permissions": ["access_webmail", "access_portal"]
    }
    dickinson_users.save()
else:
    print("ℹ️  'Dickinson Users' group already exists")

print(f"\n📊 Group Summary:")
print(f"   - Dickinson Admins: {dickinson_admins.users.count()} users")
print(f"   - Dickinson Users: {dickinson_users.users.count()} users")

EOF

echo ""
echo "==============================================================================="
echo "✅ SSO STRUCTURE CREATED"
echo "==============================================================================="
echo ""
echo "Next steps:"
echo "1. Create sysadmin account: ./scripts/create-sysadmin-user.sh"
echo "2. Add users to groups via Authentik web UI: https://sso.securenexus.net"
echo "3. Configure application access policies"
echo ""
echo "Group structure:"
echo "  - authentik Admins: System administrators (full access)"
echo "  - Dickinson Admins: Dickinson account administrators"
echo "  - Dickinson Users: Regular Dickinson users"
echo "==============================================================================="
