#!/bin/bash
# Verify Keycloak X-Frame-Options header

echo "Testing X-Frame-Options header on Keycloak..."
echo ""

HEADER=$(curl -k -s -I https://keycloak.securenexus.net/realms/securenexus/.well-known/openid-configuration 2>&1 | grep -i "x-frame-options")

echo "$HEADER"
echo ""

if echo "$HEADER" | grep -q "SAMEORIGIN"; then
    echo "✅ SUCCESS: X-Frame-Options is set to SAMEORIGIN"
    echo "Keycloak can now be embedded in iframes from the same origin"
elif echo "$HEADER" | grep -q "DENY"; then
    echo "❌ ISSUE: X-Frame-Options is still DENY"
    echo "Please update the setting in Keycloak Admin Console:"
    echo "  Realm Settings → Security defenses → X-Frame-Options → SAMEORIGIN"
else
    echo "⚠️  WARNING: X-Frame-Options header not found"
fi
