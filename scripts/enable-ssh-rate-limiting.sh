#!/bin/bash
# Enable SSH Rate Limiting via UFW
# Protects against brute force attacks

set -e

echo "🛡️  Enabling SSH Rate Limiting"
echo "=============================="
echo ""

# Check if UFW is active
if ! sudo ufw status | grep -q "Status: active"; then
    echo "❌ Error: UFW is not active"
    exit 1
fi

echo "Current SSH rules:"
sudo ufw status numbered | grep -E "22|SSH"
echo ""

# Backup current rules
echo "📦 Backing up current UFW rules..."
sudo cp /etc/ufw/user.rules /etc/ufw/user.rules.backup.$(date +%Y%m%d)
echo "✅ Backup created"
echo ""

# Remove existing SSH allow rules
echo "🗑️  Removing existing SSH rules..."
while sudo ufw status numbered | grep -qE "22/tcp|OpenSSH"; do
    # Get the first rule number for SSH
    RULE_NUM=$(sudo ufw status numbered | grep -E "22/tcp|OpenSSH" | head -1 | grep -oP '\[\s*\K[0-9]+')
    echo "   Removing rule #${RULE_NUM}"
    echo "y" | sudo ufw delete ${RULE_NUM}
done
echo "✅ Old SSH rules removed"
echo ""

# Add rate-limited SSH rule
echo "➕ Adding rate-limited SSH rule..."
sudo ufw limit 22/tcp comment "SSH with rate limiting (max 6 connections per 30s)"
echo "✅ Rate limiting enabled"
echo ""

# Reload UFW
echo "🔄 Reloading UFW..."
sudo ufw reload
echo "✅ UFW reloaded"
echo ""

# Show new rules
echo "📋 New SSH rules:"
sudo ufw status verbose | grep -A 2 "22/tcp"
echo ""

echo "✅ SSH rate limiting configured successfully!"
echo ""
echo "Rate limit details:"
echo "  - Maximum 6 connection attempts per 30 seconds"
echo "  - Additional attempts will be blocked temporarily"
echo "  - Protects against brute force attacks"
echo ""
echo "⚠️  IMPORTANT:"
echo "  - Test SSH connection from another terminal before closing this one"
echo "  - Make sure you can still connect"
echo "  - Consider using SSH keys instead of passwords"
echo ""
echo "To revert if needed:"
echo "  sudo cp /etc/ufw/user.rules.backup.$(date +%Y%m%d) /etc/ufw/user.rules"
echo "  sudo ufw reload"
