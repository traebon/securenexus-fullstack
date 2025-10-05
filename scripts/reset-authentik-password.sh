#!/bin/bash
set -euo pipefail

echo "==============================================================================="
echo "AUTHENTIK PASSWORD RESET"
echo "==============================================================================="
echo ""

# Get username
echo "Enter username to reset password for (default: akadmin):"
read -r USERNAME
USERNAME=${USERNAME:-akadmin}

# Get new password
echo "Enter new password:"
read -s NEW_PASSWORD
echo ""
echo "Confirm new password:"
read -s CONFIRM_PASSWORD
echo ""

# Check passwords match
if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo "❌ Passwords do not match!"
    exit 1
fi

# Reset password
echo "Resetting password for user: $USERNAME"
docker compose exec -T authentik_server python -m manage shell << EOF
from authentik.core.models import User

try:
    user = User.objects.get(username="$USERNAME")
    user.set_password("$NEW_PASSWORD")
    user.save()
    print("✅ Password reset successfully for user: $USERNAME")
    print("")
    print("You can now login at: https://sso.securenexus.net")
    print("Username: $USERNAME")
except User.DoesNotExist:
    print("❌ User '$USERNAME' not found!")
    print("")
    print("Available users:")
    for u in User.objects.all():
        if u.username not in ['AnonymousUser'] and not u.username.startswith('ak-outpost'):
            print(f"  - {u.username} ({u.email or 'no email'})")
EOF

echo ""
echo "==============================================================================="
