#!/bin/bash
# Create System Administrator Account
# Interactive script to create a dedicated sysadmin user

set -euo pipefail

echo "==============================================================================="
echo "CREATE SYSTEM ADMINISTRATOR ACCOUNT"
echo "==============================================================================="
echo ""

# Prompt for user details
read -p "Enter username for sysadmin: " USERNAME
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
echo "Creating sysadmin user: $USERNAME"
echo ""

docker compose exec -T authentik_server python -m manage shell << EOF
from authentik.core.models import User, Group
from django.contrib.auth.hashers import make_password

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
        "role": "sysadmin",
        "description": "System Administrator"
    }
    user.save()

    # Add to authentik Admins group (full system access)
    admin_group = Group.objects.get(name="authentik Admins")
    user.ak_groups.add(admin_group)

    # Add to Dickinson Admins as well (for organization)
    try:
        dickinson_admin_group = Group.objects.get(name="Dickinson Admins")
        user.ak_groups.add(dickinson_admin_group)
    except Group.DoesNotExist:
        pass

    if created:
        print(f"✅ Created sysadmin user: ${USERNAME}")
    else:
        print(f"ℹ️  Updated existing user: ${USERNAME}")

    print(f"   Email: ${EMAIL}")
    print(f"   Name: ${FULLNAME}")
    print(f"   Groups: {', '.join([g.name for g in user.ak_groups.all()])}")

except Exception as e:
    print(f"❌ Error creating user: {e}")
    exit(1)

EOF

echo ""
echo "==============================================================================="
echo "✅ SYSADMIN USER CREATED"
echo "==============================================================================="
echo ""
echo "Login details:"
echo "  URL: https://sso.securenexus.net"
echo "  Username: $USERNAME"
echo "  Email: $EMAIL"
echo ""
echo "This user has full system administrator access."
echo "==============================================================================="
