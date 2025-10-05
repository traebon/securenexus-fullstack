#!/bin/bash
set -euo pipefail

echo "==============================================================================="
echo "AUTHENTIK USERS"
echo "==============================================================================="
echo ""

docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User

users = User.objects.all()
if users.exists():
    print("Current Authentik Users:")
    print("-" * 80)
    print(f"{'Username':<20} | {'Email':<35} | {'Name':<20} | {'Status':<10}")
    print("-" * 80)
    for user in users:
        status = "Active" if user.is_active else "Inactive"
        email = user.email or "(no email)"
        name = user.name or "(no name)"
        print(f"{user.username:<20} | {email:<35} | {name:<20} | {status:<10}")
    print("-" * 80)
    print(f"\nTotal users: {users.count()}")
else:
    print("No users found.")
EOF

echo ""
echo "==============================================================================="
echo "To create a new admin user, run: ./create-authentik-admin.sh"
echo "To access Authentik: https://sso.securenexus.net"
echo "==============================================================================="
