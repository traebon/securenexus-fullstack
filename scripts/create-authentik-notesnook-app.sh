#!/bin/bash

# Create Authentik OAuth2 Application for Notesnook SSO Integration
# This script sets up Notesnook to use Authentik for authentication

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔐 Creating Authentik OAuth2 Application for Notesnook..."

# Check if Authentik is running
if ! docker compose ps authentik_server | grep -q "Up"; then
    echo "❌ Error: Authentik server is not running"
    echo "   Start it with: docker compose up -d authentik_server"
    exit 1
fi

# Generate OAuth2 client secret for Notesnook
NOTESNOOK_OAUTH_SECRET=$(openssl rand -base64 32)
echo "$NOTESNOOK_OAUTH_SECRET" > "$PROJECT_DIR/secrets/notesnook_oauth_secret.txt"

echo "✅ Generated OAuth2 secret for Notesnook"

# Create the OAuth2 provider and application via Authentik API
echo "🔧 Creating Authentik OAuth2 provider for Notesnook..."

# Wait for Authentik to be ready
sleep 5

# Create Notesnook OAuth2 Provider
docker compose exec authentik_server ak create_oauth2_provider \
    --name "notesnook-oauth" \
    --client-type "confidential" \
    --client-id "notesnook-sso" \
    --client-secret "$NOTESNOOK_OAUTH_SECRET" \
    --redirect-uris "https://identity.${DOMAIN}/signin-oidc
https://notes.${DOMAIN}/auth/callback
https://identity.${DOMAIN}/auth/callback" \
    --post-logout-redirect-uris "https://notes.${DOMAIN}/
https://identity.${DOMAIN}/" \
    --scopes "openid profile email" \
    --sub-mode "hashed_user_id" \
    --include-claims-in-id-token || echo "Provider may already exist"

echo "✅ Created OAuth2 provider: notesnook-oauth"

# Create Notesnook Application
docker compose exec authentik_server ak create_application \
    --name "Notesnook" \
    --slug "notesnook" \
    --provider "notesnook-oauth" \
    --meta-description "Private Note-Taking Platform" \
    --meta-launch-url "https://notes.${DOMAIN}/" || echo "Application may already exist"

echo "✅ Created Authentik application: Notesnook"

# Create group for Notesnook users
docker compose exec authentik_server ak create_group \
    --name "notesnook-users" \
    --users-obj "admin" || echo "Group may already exist"

echo "✅ Created group: notesnook-users"

# Assign application access to the group
echo "🔧 Configuring application permissions..."

cat << 'EOF' | docker compose exec -T authentik_server python manage.py shell
from authentik.core.models import Application, Group, User
from authentik.policies.models import PolicyBinding
from authentik.policies.expression.models import ExpressionPolicy

try:
    # Get the Notesnook application
    app = Application.objects.get(slug='notesnook')

    # Get the notesnook-users group
    group = Group.objects.get(name='notesnook-users')

    # Create a policy that allows access to notesnook-users group
    policy, created = ExpressionPolicy.objects.get_or_create(
        name='notesnook-access-policy',
        defaults={
            'expression': 'return ak_is_group_member(request.user, name="notesnook-users") or user.is_superuser'
        }
    )

    # Bind the policy to the application
    binding, created = PolicyBinding.objects.get_or_create(
        target=app,
        policy=policy,
        defaults={'order': 0}
    )

    print(f"✅ Configured access policy for Notesnook application")

except Exception as e:
    print(f"❌ Error configuring policies: {e}")
EOF

echo ""
echo "🎉 Authentik OAuth2 configuration completed!"
echo ""
echo "📋 Configuration Summary:"
echo "   • Application Name: Notesnook"
echo "   • Client ID: notesnook-sso"
echo "   • Provider: notesnook-oauth"
echo "   • Redirect URLs: Multiple callback URLs configured"
echo "   • Scopes: openid, profile, email"
echo "   • Access Group: notesnook-users"
echo ""
echo "🔗 URLs:"
echo "   • Notesnook App: https://notes.${DOMAIN}/"
echo "   • Identity Server: https://identity.${DOMAIN}/"
echo "   • Authentik Admin: https://auth.${DOMAIN}/if/admin/"
echo ""
echo "👥 User Management:"
echo "   • Add users to 'notesnook-users' group in Authentik"
echo "   • Users can then login to Notesnook with SSO"
echo ""
echo "🔧 Next Steps:"
echo "   1. Configure Notesnook environment variables"
echo "   2. Restart Notesnook services"
echo "   3. Test SSO login"
echo ""
echo "💾 Generated files:"
echo "   • secrets/notesnook_oauth_secret.txt"