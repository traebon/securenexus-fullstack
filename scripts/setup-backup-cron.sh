#!/usr/bin/env bash
# Setup Daily Backup Cron Job for SecureNexus
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup.sh"

echo "=== SecureNexus Backup Cron Setup ==="
echo ""

# Check if backup script exists
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "❌ Backup script not found at: $BACKUP_SCRIPT"
    exit 1
fi

echo "Backup script: $BACKUP_SCRIPT"
echo ""

# Ensure backup script is executable
chmod +x "$BACKUP_SCRIPT"
echo "✓ Backup script is executable"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT"; then
    echo ""
    echo "⚠️  Backup cron job already exists:"
    crontab -l | grep "$BACKUP_SCRIPT"
    echo ""
    echo "To remove and recreate, run: crontab -e"
    exit 0
fi

# Create temporary crontab file
TEMP_CRON=$(mktemp)
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# Add daily backup job at 2 AM
echo "# SecureNexus Daily Backup - Runs at 2 AM" >> "$TEMP_CRON"
echo "0 2 * * * $BACKUP_SCRIPT >> /var/log/securenexus-backup.log 2>&1" >> "$TEMP_CRON"

# Install new crontab
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

echo ""
echo "=== Cron Job Installed ==="
echo ""
echo "Schedule: Daily at 2:00 AM"
echo "Command: $BACKUP_SCRIPT"
echo "Log: /var/log/securenexus-backup.log"
echo ""
echo "Current crontab:"
crontab -l | tail -2
echo ""
echo "✅ Automated backups are now configured"
echo ""
echo "To view backup logs: tail -f /var/log/securenexus-backup.log"
echo "To list cron jobs: crontab -l"
echo "To edit cron jobs: crontab -e"
