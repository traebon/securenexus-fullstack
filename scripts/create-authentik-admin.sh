#!/bin/bash
# Create Authentik admin user via Django shell
# Run with: bash create-authentik-admin.sh

set -e

echo "Creating Authentik admin user..."
echo ""
echo "Enter desired admin username (default: admin):"
read -r USERNAME
USERNAME=${USERNAME:-admin}

echo "Enter email address:"
read -r EMAIL

echo "Enter password:"
read -s PASSWORD
echo ""

# Create admin user via Django shell
docker compose exec -T authentik_server python -m manage shell << EOF
from authentik.core.models import User
from authentik.tenants.models import Tenant

# Get or create user
user, created = User.objects.get_or_create(
    username="${USERNAME}",
    defaults={
        "email": "${EMAIL}",
        "name": "Administrator",
        "is_staff": True,
        "is_superuser": True,
        "is_active": True,
    }
)

if created:
    user.set_password("${PASSWORD}")
    user.save()
    print(f"✅ Created admin user: ${USERNAME}")
else:
    user.set_password("${PASSWORD}")
    user.is_staff = True
    user.is_superuser = True
    user.is_active = True
    user.save()
    print(f"✅ Updated admin user: ${USERNAME}")

print(f"")
print(f"Login at: https://sso.securenexus.net")
print(f"Username: ${USERNAME}")
print(f"Email: ${EMAIL}")
EOF

echo ""
echo "✅ Admin user created successfully!"
echo ""
echo "Access Authentik at: https://sso.securenexus.net"
echo "Username: $USERNAME"
