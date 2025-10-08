#!/bin/bash
# Setup Automated Backups with Rotation
# Configures cron job to run daily at 2 AM

set -e

SCRIPT_DIR="/home/tristian/securenexus-fullstack/scripts"
CRON_TIME="0 2 * * *"  # 2 AM daily
BACKUP_SCRIPT="$SCRIPT_DIR/backup-rotation.sh"
LOG_FILE="/var/log/securenexus-backup.log"

echo "🔧 Setting up automated backups for SecureNexus"
echo "================================================"
echo ""

# Check if backup script exists
if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo "❌ Error: Backup script not found at $BACKUP_SCRIPT"
    exit 1
fi

# Make sure script is executable
chmod +x "$BACKUP_SCRIPT"
echo "✅ Backup script is executable"

# Create log file
sudo touch "$LOG_FILE"
sudo chown tristian:tristian "$LOG_FILE"
echo "✅ Log file created: $LOG_FILE"

# Backup existing crontab
echo "📦 Backing up existing crontab..."
crontab -l > /tmp/crontab.backup.$(date +%Y%m%d) 2>/dev/null || echo "No existing crontab"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT"; then
    echo "⚠️  Backup cron job already exists. Updating..."
    crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT" | crontab -
fi

# Add new cron job
echo "➕ Adding cron job..."
(crontab -l 2>/dev/null; echo "$CRON_TIME $BACKUP_SCRIPT >> $LOG_FILE 2>&1") | crontab -

echo ""
echo "✅ Automated backups configured successfully!"
echo ""
echo "Configuration:"
echo "  Schedule: Daily at 2:00 AM"
echo "  Script: $BACKUP_SCRIPT"
echo "  Log: $LOG_FILE"
echo ""
echo "Retention policy:"
echo "  Daily backups: 7 days"
echo "  Weekly backups: 4 weeks"
echo "  Monthly backups: 12 months"
echo ""
echo "Current crontab:"
crontab -l | grep "$BACKUP_SCRIPT"
echo ""
echo "Commands:"
echo "  View logs: tail -f $LOG_FILE"
echo "  Run manual backup: $BACKUP_SCRIPT"
echo "  Edit schedule: crontab -e"
echo "  View crontab: crontab -l"
echo ""
echo "⚠️  IMPORTANT:"
echo "  - Ensure /backup/securenexus has enough space"
echo "  - Consider off-site backup replication"
echo "  - Test restoration periodically"
echo "  - Encrypt secrets before off-site storage"
