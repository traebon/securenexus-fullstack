#!/bin/bash
# Fix Keycloak X-Frame-Options to allow same-origin framing

echo "Configuring Keycloak realm security settings..."

docker compose exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password "$(cat secrets/keycloak_admin_password.txt)"

echo "Updating X-Frame-Options to SAMEORIGIN for securenexus realm..."

docker compose exec keycloak /opt/keycloak/bin/kcadm.sh update realms/securenexus \
  -s 'browserSecurityHeaders.xFrameOptions=SAMEORIGIN'

echo "✓ X-Frame-Options updated to SAMEORIGIN"
echo ""
echo "Verify by running:"
echo "  curl -I https://keycloak.securenexus.net/realms/securenexus/.well-known/openid-configuration | grep -i x-frame"
