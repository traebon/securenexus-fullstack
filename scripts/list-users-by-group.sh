#!/bin/bash
# List Users by Group
# Shows all users organized by their group membership

set -euo pipefail

echo "==============================================================================="
echo "AUTHENTIK USERS BY GROUP"
echo "==============================================================================="
echo ""

docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import User, Group

# Get all groups
groups = Group.objects.all().order_by('name')

for group in groups:
    print(f"\n{'='*80}")
    print(f"Group: {group.name}")
    print(f"Superuser: {'Yes' if group.is_superuser else 'No'}")
    print(f"{'='*80}")

    users = User.objects.filter(ak_groups=group, type='internal').exclude(username='AnonymousUser')

    if users.exists():
        print(f"\n{'Username':<20} | {'Email':<35} | {'Name':<20}")
        print(f"{'-'*80}")
        for user in users:
            email = user.email or "(no email)"
            name = user.name or "(no name)"
            print(f"{user.username:<20} | {email:<35} | {name:<20}")
        print(f"\nTotal users in {group.name}: {users.count()}")
    else:
        print("  (no users in this group)")

# List users not in any group
print(f"\n{'='*80}")
print(f"Users without groups")
print(f"{'='*80}")

ungrouped = User.objects.filter(ak_groups__isnull=True, type='internal').exclude(username='AnonymousUser')
if ungrouped.exists():
    print(f"\n{'Username':<20} | {'Email':<35} | {'Name':<20}")
    print(f"{'-'*80}")
    for user in ungrouped:
        email = user.email or "(no email)"
        name = user.name or "(no name)"
        print(f"{user.username:<20} | {email:<35} | {name:<20}")
else:
    print("  (all users are assigned to groups)")

print(f"\n{'='*80}")
EOF

echo ""
echo "==============================================================================="
echo "To manage users:"
echo "  - Create sysadmin: ./scripts/create-sysadmin-user.sh"
echo "  - Create Dickinson user: ./scripts/create-dickinson-user.sh"
echo "  - Web UI: https://sso.securenexus.net"
echo "==============================================================================="
