#!/bin/bash
# Configure Application Access for Groups
# Sets up proper group-based access control for all Authentik applications

set -euo pipefail

echo "==============================================================================="
echo "CONFIGURE APPLICATION ACCESS"
echo "==============================================================================="
echo ""

echo "Configuring group-based access for applications..."
echo ""

docker compose exec -T authentik_server python -m manage shell << 'EOF'
from authentik.core.models import Application, Group
from authentik.policies.models import PolicyBinding
from authentik.policies.expression.models import ExpressionPolicy

# Get all groups
dickinson_users = Group.objects.get(name="Dickinson Users")
dickinson_admins = Group.objects.get(name="Dickinson Admins")
authentik_admins = Group.objects.get(name="authentik Admins")
grafana_admins = Group.objects.get(name="Grafana Admins")

# Get all applications
app_catalog = Application.objects.get(slug="app-catalog")
dickinson_webmail = Application.objects.get(slug="dickinson-webmail")
erpnext = Application.objects.get(slug="erpnext")
grafana = Application.objects.get(slug="grafana")
tailscale = Application.objects.get(slug="tailscale")

print("=== Configuring Application Access ===\n")

# Clear existing bindings first
PolicyBinding.objects.filter(target=app_catalog).delete()
PolicyBinding.objects.filter(target=dickinson_webmail).delete()
PolicyBinding.objects.filter(target=erpnext).delete()
PolicyBinding.objects.filter(target=grafana).delete()
PolicyBinding.objects.filter(target=tailscale).delete()

print("✅ Cleared existing access bindings\n")

# 1. App Catalog - All authenticated users (no restrictions)
print("📱 App Catalog: Open to all authenticated users")

# 2. Dickinson Webmail - Dickinson Users + Dickinson Admins
PolicyBinding.objects.create(
    target=dickinson_webmail,
    group=dickinson_users,
    order=10,
    enabled=True,
    negate=False,
    timeout=30
)
PolicyBinding.objects.create(
    target=dickinson_webmail,
    group=dickinson_admins,
    order=20,
    enabled=True,
    negate=False,
    timeout=30
)
print("✉️  Dickinson Webmail: Dickinson Users, Dickinson Admins")

# 3. ERPNext - authentik Admins + Dickinson Admins
PolicyBinding.objects.create(
    target=erpnext,
    group=authentik_admins,
    order=10,
    enabled=True,
    negate=False,
    timeout=30
)
PolicyBinding.objects.create(
    target=erpnext,
    group=dickinson_admins,
    order=20,
    enabled=True,
    negate=False,
    timeout=30
)
print("📊 ERPNext: authentik Admins, Dickinson Admins")

# 4. Grafana - Grafana Admins + authentik Admins
PolicyBinding.objects.create(
    target=grafana,
    group=grafana_admins,
    order=10,
    enabled=True,
    negate=False,
    timeout=30
)
PolicyBinding.objects.create(
    target=grafana,
    group=authentik_admins,
    order=20,
    enabled=True,
    negate=False,
    timeout=30
)
print("📈 Grafana: Grafana Admins, authentik Admins")

# 5. Tailscale - authentik Admins only (VPN access)
PolicyBinding.objects.create(
    target=tailscale,
    group=authentik_admins,
    order=10,
    enabled=True,
    negate=False,
    timeout=30
)
print("🔒 Tailscale: authentik Admins")

print("\n=== Access Configuration Summary ===\n")

apps = Application.objects.all().order_by('name')
for app in apps:
    bindings = PolicyBinding.objects.filter(target=app, group__isnull=False)
    print(f"{app.name}:")
    if bindings.exists():
        for binding in bindings.order_by('order'):
            print(f"  ✓ {binding.group.name}")
    else:
        print(f"  ✓ All authenticated users (no restrictions)")
    print()

EOF

echo ""
echo "==============================================================================="
echo "✅ APPLICATION ACCESS CONFIGURED"
echo "==============================================================================="
echo ""
echo "Access summary:"
echo "  - App Catalog: All authenticated users"
echo "  - Dickinson Webmail: Dickinson Users, Dickinson Admins"
echo "  - ERPNext: authentik Admins, Dickinson Admins"
echo "  - Grafana: Grafana Admins, authentik Admins (VPN-only)"
echo "  - Tailscale: authentik Admins"
echo ""
echo "Users will only see applications they have access to in their portal."
echo "==============================================================================="
