#!/usr/bin/env bash
# Setup UFW firewall for SecureNexus
set -euo pipefail

echo "=== SecureNexus Firewall Setup ==="
echo ""
echo "This script will configure UFW firewall with the following rules:"
echo "  - Allow SSH (22)"
echo "  - Allow DNS (53 TCP/UDP, 853 TCP)"
echo "  - Allow HTTP/HTTPS (80, 443)"
echo "  - Allow Mail (25, 465, 587, 143, 993)"
echo "  - Default deny incoming"
echo "  - Default allow outgoing"
echo ""
echo "WARNING: Ensure you have an active SSH connection before proceeding!"
echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
sleep 10

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    echo "UFW not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y ufw
fi

echo ""
echo "[1/8] Setting default policies..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny forward

echo "[2/8] Allowing SSH (port 22)..."
sudo ufw allow 22/tcp comment 'SSH'

echo "[3/8] Allowing DNS (port 53 TCP/UDP)..."
sudo ufw allow 53/tcp comment 'DNS'
sudo ufw allow 53/udp comment 'DNS'

echo "[4/8] Allowing DNS-over-TLS (port 853)..."
sudo ufw allow 853/tcp comment 'DNS-over-TLS'

echo "[5/8] Allowing HTTP (port 80)..."
sudo ufw allow 80/tcp comment 'HTTP (Traefik)'

echo "[6/8] Allowing HTTPS (port 443)..."
sudo ufw allow 443/tcp comment 'HTTPS (Traefik)'

echo "[7/11] Allowing SMTP (port 25)..."
sudo ufw allow 25/tcp comment 'SMTP Inbound'

echo "[8/11] Allowing SMTPS (port 465)..."
sudo ufw allow 465/tcp comment 'SMTPS'

echo "[9/11] Allowing SMTP Submission (port 587)..."
sudo ufw allow 587/tcp comment 'SMTP Submission'

echo "[10/11] Allowing IMAP (port 143)..."
sudo ufw allow 143/tcp comment 'IMAP'

echo "[11/11] Allowing IMAPS (port 993)..."
sudo ufw allow 993/tcp comment 'IMAPS'

echo "[Finalizing] Enabling UFW..."
sudo ufw --force enable

echo ""
echo "=== Firewall Status ==="
sudo ufw status verbose

echo ""
echo "=== Setup Complete ==="
echo "UFW firewall is now active and protecting your server."
echo "All SecureNexus services should remain accessible."
echo ""
echo "To disable firewall: sudo ufw disable"
echo "To check status: sudo ufw status verbose"
