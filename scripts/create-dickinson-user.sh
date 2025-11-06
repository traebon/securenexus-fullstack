#!/bin/bash
# Create Dickinson User Account
# Interactive script to create Dickinson admin or regular users

set -euo pipefail

echo "==============================================================================="
echo "CREATE DICKINSON USER ACCOUNT"
echo "==============================================================================="
echo ""

# Prompt for user details
read -p "Enter username: " USERNAME
read -p "Enter email address: " EMAIL
read -p "Enter full name: " FULLNAME
read -sp "Enter password: " PASSWORD
echo ""
read -sp "Confirm password: " PASSWORD2
echo ""

if [ "$PASSWORD" != "$PASSWORD2" ]; then
    echo "❌ Passwords do not match!"
    exit 1
fi

echo ""
echo "Select user type:"
echo "1) Dickinson Admin (can manage users and accounts)"
echo "2) Dickinson User (regular user access)"
read -p "Enter choice [1-2]: " USER_TYPE

case $USER_TYPE in
    1)
        GROUP_NAME="Dickinson Admins"
        ROLE="admin"
        ;;
    2)
        GROUP_NAME="Dickinson Users"
        ROLE="user"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Creating $ROLE user: $USERNAME"
echo ""

docker compose exec -T authentik_server python -m manage shell << EOF
from authentik.core.models import User, Group

# Create the user
try:
    user, created = User.objects.get_or_create(
        username="${USERNAME}",
        defaults={
            "email": "${EMAIL}",
            "name": "${FULLNAME}",
            "is_active": True,
            "type": "internal",
        }
    )

    # Set password
    user.set_password("${PASSWORD}")
    user.attributes = {
        "role": "${ROLE}",
        "organization": "Dickinson Accounts"
    }
    user.save()

    # Add to appropriate group
    group = Group.objects.get(name="${GROUP_NAME}")
    user.ak_groups.add(group)

    # Also add regular users to base group for webmail access
    if "${ROLE}" == "user":
        # Ensure user can access applications
        pass

    if created:
        print(f"✅ Created ${ROLE} user: ${USERNAME}")
    else:
        print(f"ℹ️  Updated existing user: ${USERNAME}")

    print(f"   Email: ${EMAIL}")
    print(f"   Name: ${FULLNAME}")
    print(f"   Group: ${GROUP_NAME}")
    print(f"   Applications: Dickinson Webmail, ERPNext (if applicable)")

except Exception as e:
    print(f"❌ Error creating user: {e}")
    import traceback
    traceback.print_exc()
    exit(1)

EOF

echo ""
echo "==============================================================================="
echo "✅ DICKINSON USER CREATED"
echo "==============================================================================="
echo ""
echo "Login details:"
echo "  SSO URL: https://sso.securenexus.net"
echo "  Username: $USERNAME"
echo "  Email: $EMAIL"
echo "  Role: $ROLE"
echo "  Group: $GROUP_NAME"
echo ""
echo "User can now access:"
echo "  - Dickinson Webmail: https://mail.dickinson-accounts.org (or configured domain)"
echo "  - Application Portal: https://portal.securenexus.net"
echo ""
echo "==============================================================================="
