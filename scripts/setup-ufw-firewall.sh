#!/bin/bash
# UFW Firewall Setup for SecureNexus
# This script configures UFW (Uncomplicated Firewall) for defense in depth

set -e

echo "🔥 Setting up UFW Firewall for SecureNexus..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo "❌ Please run as root (sudo)"
   exit 1
fi

# Reset UFW to defaults (optional - uncomment if needed)
# ufw --force reset

echo "📋 Allowing essential services..."

# SSH (CRITICAL - allow first to avoid lockout)
ufw allow 22/tcp comment 'SSH'

# Web services
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Mail services (SMTP, Submission, IMAPS, IMAP)
ufw allow 25/tcp comment 'SMTP'
ufw allow 587/tcp comment 'SMTP Submission'
ufw allow 465/tcp comment 'SMTPS'
ufw allow 993/tcp comment 'IMAPS'
ufw allow 143/tcp comment 'IMAP'

# DNS (Authoritative server)
ufw allow 53/tcp comment 'DNS TCP'
ufw allow 53/udp comment 'DNS UDP'

# Tailscale (UDP for WireGuard)
ufw allow 41641/udp comment 'Tailscale'

# Default policies
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

echo "🔍 Current UFW rules:"
ufw show added

echo ""
read -p "⚠️  Enable firewall now? This will activate the rules. (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ufw --force enable
    echo "✅ UFW Firewall enabled successfully!"
    echo ""
    ufw status verbose
else
    echo "ℹ️  Firewall configured but not enabled."
    echo "   To enable manually: sudo ufw enable"
fi

echo ""
echo "📝 To view status: sudo ufw status verbose"
echo "📝 To disable: sudo ufw disable"
echo "📝 To delete rule: sudo ufw delete allow 80/tcp"
