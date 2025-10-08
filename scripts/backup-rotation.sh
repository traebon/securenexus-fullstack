#!/bin/bash
# Advanced Backup Rotation Script for SecureNexus
# Implements 7-daily, 4-weekly, 12-monthly retention policy

set -e

# Configuration
BACKUP_ROOT="/backup/securenexus"
DAILY_DIR="${BACKUP_ROOT}/daily"
WEEKLY_DIR="${BACKUP_ROOT}/weekly"
MONTHLY_DIR="${BACKUP_ROOT}/monthly"

# Retention policies
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 SecureNexus Backup Rotation System${NC}"
echo "======================================"

# Create rotation directories
mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR"

# Current date info
DAY_OF_WEEK=$(date +%u)  # 1-7 (Monday-Sunday)
DAY_OF_MONTH=$(date +%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Determine backup type
if [ "$DAY_OF_MONTH" = "01" ]; then
    BACKUP_TYPE="monthly"
    TARGET_DIR="$MONTHLY_DIR"
    echo -e "${YELLOW}📅 Monthly backup (1st of month)${NC}"
elif [ "$DAY_OF_WEEK" = "7" ]; then
    BACKUP_TYPE="weekly"
    TARGET_DIR="$WEEKLY_DIR"
    echo -e "${YELLOW}📅 Weekly backup (Sunday)${NC}"
else
    BACKUP_TYPE="daily"
    TARGET_DIR="$DAILY_DIR"
    echo -e "${YELLOW}📅 Daily backup${NC}"
fi

# Run the main backup script
echo -e "${GREEN}▶️  Running backup script...${NC}"
BACKUP_DIR="${TARGET_DIR}/${TIMESTAMP}"
export BACKUP_ROOT="$TARGET_DIR"
/home/tristian/securenexus-fullstack/scripts/backup-all.sh

# Rotation: Clean up old backups
echo ""
echo -e "${BLUE}🧹 Applying rotation policy...${NC}"

# Daily backups: keep last 7
echo -e "${YELLOW}   Daily: Keeping last ${KEEP_DAILY} backups${NC}"
OLD_DAILY=$(find "$DAILY_DIR" -maxdepth 1 -type d ! -path "$DAILY_DIR" | sort -r | tail -n +$((KEEP_DAILY + 1)))
if [ -n "$OLD_DAILY" ]; then
    echo "$OLD_DAILY" | while read dir; do
        echo "   ❌ Removing: $(basename "$dir")"
        rm -rf "$dir"
    done
else
    echo "   ✅ No old daily backups to remove"
fi

# Weekly backups: keep last 4
echo -e "${YELLOW}   Weekly: Keeping last ${KEEP_WEEKLY} backups${NC}"
OLD_WEEKLY=$(find "$WEEKLY_DIR" -maxdepth 1 -type d ! -path "$WEEKLY_DIR" | sort -r | tail -n +$((KEEP_WEEKLY + 1)))
if [ -n "$OLD_WEEKLY" ]; then
    echo "$OLD_WEEKLY" | while read dir; do
        echo "   ❌ Removing: $(basename "$dir")"
        rm -rf "$dir"
    done
else
    echo "   ✅ No old weekly backups to remove"
fi

# Monthly backups: keep last 12
echo -e "${YELLOW}   Monthly: Keeping last ${KEEP_MONTHLY} backups${NC}"
OLD_MONTHLY=$(find "$MONTHLY_DIR" -maxdepth 1 -type d ! -path "$MONTHLY_DIR" | sort -r | tail -n +$((KEEP_MONTHLY + 1)))
if [ -n "$OLD_MONTHLY" ]; then
    echo "$OLD_MONTHLY" | while read dir; do
        echo "   ❌ Removing: $(basename "$dir")"
        rm -rf "$dir"
    done
else
    echo "   ✅ No old monthly backups to remove"
fi

# Summary
echo ""
echo -e "${GREEN}✅ Backup rotation complete!${NC}"
echo ""
echo "Current backup inventory:"
echo "  Daily:   $(find "$DAILY_DIR" -maxdepth 1 -type d ! -path "$DAILY_DIR" | wc -l) backups (max: $KEEP_DAILY)"
echo "  Weekly:  $(find "$WEEKLY_DIR" -maxdepth 1 -type d ! -path "$WEEKLY_DIR" | wc -l) backups (max: $KEEP_WEEKLY)"
echo "  Monthly: $(find "$MONTHLY_DIR" -maxdepth 1 -type d ! -path "$MONTHLY_DIR" | wc -l) backups (max: $KEEP_MONTHLY)"
echo ""
echo "Total backup space used: $(du -sh "$BACKUP_ROOT" | cut -f1)"
echo ""
echo "Latest backup: ${BACKUP_TYPE} - ${TIMESTAMP}"
echo "Location: ${TARGET_DIR}/${TIMESTAMP}"
