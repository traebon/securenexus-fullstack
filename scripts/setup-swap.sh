#!/usr/bin/env bash
# Setup 4GB Swap Space for SecureNexus
set -euo pipefail

echo "=== SecureNexus Swap Setup ==="
echo ""

# Check if swap already exists
if [ -f /swapfile ]; then
    echo "⚠️  Swap file already exists at /swapfile"
    echo "Current swap status:"
    swapon --show
    free -h
    exit 0
fi

echo "[1/5] Creating 4GB swap file..."
fallocate -l 4G /swapfile
echo "✓ Swap file created (4GB)"

echo "[2/5] Setting secure permissions..."
chmod 600 /swapfile
ls -lh /swapfile
echo "✓ Permissions set to 600"

echo "[3/5] Setting up swap area..."
mkswap /swapfile
echo "✓ Swap area configured"

echo "[4/5] Enabling swap..."
swapon /swapfile
echo "✓ Swap enabled"

echo "[5/5] Making swap persistent (adding to /etc/fstab)..."
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
    echo "✓ Added to /etc/fstab"
else
    echo "ℹ️  Already in /etc/fstab"
fi

echo ""
echo "=== Swap Configuration Complete ==="
echo ""
echo "Current swap status:"
swapon --show
echo ""
echo "Memory status:"
free -h
echo ""
echo "✅ 4GB swap space is now active and will persist after reboot"
