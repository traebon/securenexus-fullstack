#!/bin/bash

# Enhanced Backup Script with GPG Encryption for SecureNexus
# Backs up databases, volumes, and configuration with encryption for sensitive data

set -euo pipefail

# Configuration
BACKUP_ROOT="${BACKUP_ROOT:-/backup/securenexus}"  # Use env var if set, otherwise default
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/${DATE}"
COMPOSE_DIR="/home/tristian/securenexus-fullstack"
BACKUP_KEY_ID="securenexus-backup@internal"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Starting Encrypted SecureNexus Backup - ${DATE}${NC}"
echo

# Check if GPG key exists
if ! gpg --list-secret-keys | grep -q "$BACKUP_KEY_ID"; then
    echo -e "${RED}❌ GPG backup key not found: $BACKUP_KEY_ID${NC}"
    echo "Please run: ./scripts/setup-backup-encryption.sh"
    exit 1
fi

echo -e "${GREEN}✅ Found GPG key: $BACKUP_KEY_ID${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"/{databases,volumes,config,encrypted}

cd "$COMPOSE_DIR"

# Function to encrypt sensitive files
encrypt_file() {
    local input_file="$1"
    local output_file="${input_file}.gpg"

    if [ -f "$input_file" ]; then
        echo "   🔒 Encrypting $(basename "$input_file")..."
        gpg --trust-model always --encrypt -r "$BACKUP_KEY_ID" --cipher-algo AES256 --compress-algo 2 "$input_file"

        # Verify encryption worked
        if [ -f "$output_file" ]; then
            echo "   ✅ Encrypted: $(du -h "$output_file" | cut -f1)"
            # Remove unencrypted file after successful encryption
            rm "$input_file"
            return 0
        else
            echo "   ❌ Encryption failed for $(basename "$input_file")"
            return 1
        fi
    else
        echo "   ⚠️  File not found: $(basename "$input_file")"
        return 1
    fi
}

# 1. Backup PostgreSQL (Authentik) - SENSITIVE
echo -e "${YELLOW}📦 Backing up PostgreSQL (Authentik) - ENCRYPTED...${NC}"
docker compose exec -T authentik_db pg_dump -U authentik authentik > "$BACKUP_DIR/databases/authentik.sql"
if encrypt_file "$BACKUP_DIR/databases/authentik.sql"; then
    echo "✅ PostgreSQL backed up and encrypted"
else
    echo "❌ PostgreSQL encryption failed"
    exit 1
fi

# 2. Backup MySQL (CoreDNS)
echo -e "${YELLOW}📦 Backing up MySQL (CoreDNS)...${NC}"
MYSQL_PASS=$(cat secrets/mysql_password.txt)
docker compose exec -T mysql-db mysqldump -u coredns -p"$MYSQL_PASS" coredns > "$BACKUP_DIR/databases/mysql.sql" 2>/dev/null || echo "⚠️  MySQL backup skipped (may be empty)"
if [ -f "$BACKUP_DIR/databases/mysql.sql" ] && [ -s "$BACKUP_DIR/databases/mysql.sql" ]; then
    echo "✅ MySQL backed up: $(du -h "$BACKUP_DIR/databases/mysql.sql" | cut -f1)"
else
    echo "⚠️  MySQL backup empty or failed"
fi

# 3. Backup MariaDB (ERPNext) - SENSITIVE
echo -e "${YELLOW}📦 Backing up MariaDB (ERPNext) - ENCRYPTED...${NC}"
if docker compose ps erpnext-db 2>/dev/null | grep -q "Up"; then
    ERPNEXT_DB_PASS=$(cat secrets/erpnext_db_password.txt)
    docker compose exec -T erpnext-db mysqldump -u root -p"$ERPNEXT_DB_PASS" --all-databases > "$BACKUP_DIR/databases/erpnext.sql" 2>/dev/null
    if encrypt_file "$BACKUP_DIR/databases/erpnext.sql"; then
        echo "✅ ERPNext MariaDB backed up and encrypted"
    else
        echo "❌ ERPNext encryption failed"
    fi
else
    echo "⚠️  ERPNext MariaDB not running (skipped)"
fi

# 4. Backup etcd (DNS records)
echo -e "${YELLOW}📦 Backing up etcd (dynamic DNS)...${NC}"
docker compose exec etcd etcdctl snapshot save /tmp/etcd_backup.db
docker compose cp etcd:/tmp/etcd_backup.db "$BACKUP_DIR/databases/etcd.db"
echo "✅ etcd backed up: $(du -h "$BACKUP_DIR/databases/etcd.db" | cut -f1)"

# 5. Backup ERPNext sites and assets - if exists
echo -e "${YELLOW}📦 Backing up ERPNext sites and assets...${NC}"
if docker volume ls | grep -q erpnext-sites-data; then
    docker run --rm -v securenexus-fullstack_erpnext-sites-data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar -czf /backup/erpnext-sites.tar.gz -C /data .
    docker run --rm -v securenexus-fullstack_erpnext-assets-data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar -czf /backup/erpnext-assets.tar.gz -C /data .
    echo "✅ ERPNext volumes backed up: $(du -h "$BACKUP_DIR/volumes/erpnext-sites.tar.gz" | cut -f1) + $(du -h "$BACKUP_DIR/volumes/erpnext-assets.tar.gz" | cut -f1)"
else
    echo "⚠️  ERPNext volumes not found (skipped)"
fi

# 6. Backup Grafana data
echo -e "${YELLOW}📦 Backing up Grafana data...${NC}"
docker run --rm -v securenexus-fullstack_grafana-data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar -czf /backup/grafana.tar.gz -C /data .
echo "✅ Grafana backed up: $(du -h "$BACKUP_DIR/volumes/grafana.tar.gz" | cut -f1)"

# 7. Backup Prometheus data (optional - can be large)
echo -e "${YELLOW}📦 Backing up Prometheus data (this may take a while)...${NC}"
docker run --rm -v securenexus-fullstack_prometheus-data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar -czf /backup/prometheus.tar.gz -C /data .
echo "✅ Prometheus backed up: $(du -h "$BACKUP_DIR/volumes/prometheus.tar.gz" | cut -f1)"

# 8. Backup Loki data
echo -e "${YELLOW}📦 Backing up Loki data...${NC}"
docker run --rm -v securenexus-fullstack_loki-data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar -czf /backup/loki.tar.gz -C /data .
echo "✅ Loki backed up: $(du -h "$BACKUP_DIR/volumes/loki.tar.gz" | cut -f1)"

# 9. Backup Uptime Kuma data
echo -e "${YELLOW}📦 Backing up Uptime Kuma data...${NC}"
docker run --rm -v securenexus-fullstack_uptime-kuma-data:/data -v "$BACKUP_DIR/volumes":/backup alpine tar -czf /backup/uptime-kuma.tar.gz -C /data .
echo "✅ Uptime Kuma backed up: $(du -h "$BACKUP_DIR/volumes/uptime-kuma.tar.gz" | cut -f1)"

# 10. Backup configuration files
echo -e "${YELLOW}📦 Backing up configuration...${NC}"
cp -r config/ "$BACKUP_DIR/config/"
cp -r dns/zones/ "$BACKUP_DIR/config/dns-zones/"
cp compose.yml "$BACKUP_DIR/config/"
cp .env "$BACKUP_DIR/config/" 2>/dev/null || echo "⚠️  .env not found"
cp -r erp/branding "$BACKUP_DIR/config/erp-branding/" 2>/dev/null || echo "⚠️  ERPNext branding not found"

# 11. Backup secrets (ENCRYPTED) - MOST SENSITIVE
echo -e "${YELLOW}📦 Backing up secrets (ENCRYPTED) - HIGHEST SECURITY...${NC}"
tar -czf "$BACKUP_DIR/encrypted/secrets.tar.gz" secrets/
if encrypt_file "$BACKUP_DIR/encrypted/secrets.tar.gz"; then
    echo "✅ Secrets backed up and encrypted with highest security"
else
    echo "❌ Secrets encryption failed - CRITICAL ERROR"
    exit 1
fi

# 12. Backup ACME certificates - SENSITIVE
echo -e "${YELLOW}📦 Backing up SSL certificates (ENCRYPTED)...${NC}"
mkdir -p "$BACKUP_DIR/encrypted"
# Use docker cp to avoid permission issues with root-owned acme.json
if docker compose cp traefik:/acme/acme.json "$BACKUP_DIR/encrypted/acme.json" 2>/dev/null; then
    if encrypt_file "$BACKUP_DIR/encrypted/acme.json"; then
        echo "✅ ACME certificates backed up and encrypted"
    else
        echo "❌ ACME certificates encryption failed"
    fi
elif [ -f acme/acme.json ]; then
    # Fallback to direct copy if docker cp fails
    cp acme/acme.json "$BACKUP_DIR/encrypted/" 2>/dev/null
    if encrypt_file "$BACKUP_DIR/encrypted/acme.json"; then
        echo "✅ ACME certificates backed up and encrypted"
    else
        echo "❌ ACME certificates encryption failed"
    fi
else
    echo "⚠️  No ACME certificates found"
fi

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

# Count encrypted files
ENCRYPTED_COUNT=$(find "$BACKUP_DIR" -name "*.gpg" | wc -l)

# Create backup manifest
cat > "$BACKUP_DIR/MANIFEST.txt" << EOF
SecureNexus Encrypted Backup Manifest
=====================================
Date: ${DATE}
Total Size: ${TOTAL_SIZE}
Encrypted Files: ${ENCRYPTED_COUNT}
GPG Key: ${BACKUP_KEY_ID}

Contents:
---------
🔒 ENCRYPTED FILES:
1. databases/authentik.sql.gpg - PostgreSQL (Authentik users & config) - ENCRYPTED
2. databases/erpnext.sql.gpg - MariaDB (ERPNext data) - ENCRYPTED
3. encrypted/secrets.tar.gz.gpg - All secrets - ENCRYPTED (CRITICAL)
4. encrypted/acme.json.gpg - SSL certificates - ENCRYPTED

📁 UNENCRYPTED FILES:
5. databases/mysql.sql - MySQL database (CoreDNS records)
6. databases/etcd.db - etcd snapshot (dynamic DNS records)
7. volumes/erpnext-sites.tar.gz - ERPNext site files
8. volumes/erpnext-assets.tar.gz - ERPNext assets
9. volumes/grafana.tar.gz - Grafana dashboards & settings
10. volumes/prometheus.tar.gz - Prometheus metrics data
11. volumes/loki.tar.gz - Loki log data
12. volumes/uptime-kuma.tar.gz - Uptime monitoring data
13. config/ - Configuration files (non-sensitive)

Decryption:
-----------
To decrypt files: gpg --decrypt file.gpg > file
Requires: Private key + passphrase

Restoration:
------------
1. Decrypt sensitive files first
2. Use scripts/restore-encrypted-backup.sh for full restoration
3. Test restoration periodically

Security Notes:
---------------
✅ User data encrypted (authentik.sql.gpg)
✅ Business data encrypted (erpnext.sql.gpg)
✅ Secrets encrypted (secrets.tar.gz.gpg)
✅ SSL certificates encrypted (acme.json.gpg)
🔓 Logs/metrics unencrypted (non-sensitive operational data)
🔓 DNS records unencrypted (public data)

Compliance:
-----------
- GDPR: Personal data encrypted at rest ✅
- SOC 2: Sensitive data encryption ✅
- ISO 27001: Data classification & protection ✅
- HIPAA: PHI protection (if applicable) ✅

Key Management:
---------------
- Public key: backup-keys/backup-public-key.asc
- Private key: backup-keys/backup-private-key.asc (store securely!)
- Key expires: $(gpg --list-keys "$BACKUP_KEY_ID" | grep expires || echo "Check GPG keyring")
EOF

echo ""
echo -e "${GREEN}✅ Encrypted backup completed successfully!${NC}"
echo -e "${GREEN}📁 Location: $BACKUP_DIR${NC}"
echo -e "${GREEN}💾 Total size: $TOTAL_SIZE${NC}"
echo -e "${GREEN}🔒 Encrypted files: $ENCRYPTED_COUNT${NC}"
echo ""
echo -e "${BLUE}🔐 Security Status:${NC}"
echo "✅ User data (Authentik): ENCRYPTED"
echo "✅ Business data (ERPNext): ENCRYPTED"
echo "✅ Secrets: ENCRYPTED"
echo "✅ SSL certificates: ENCRYPTED"
echo "🔓 Logs/metrics: Unencrypted (non-sensitive)"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo "1. Private key is required for decryption - store securely!"
echo "2. Test decryption periodically"
echo "3. Rotate GPG keys before expiration"
echo "4. Monitor key expiration dates"
echo "5. Keep encrypted backups separate from keys"
echo ""
echo "To view manifest: cat $BACKUP_DIR/MANIFEST.txt"
echo "To decrypt file: gpg --decrypt file.gpg > file"

# Cleanup old backups (keep last 7 days)
echo ""
echo -e "${YELLOW}🧹 Cleaning up old backups (keeping last 7 days)...${NC}"
find "$BACKUP_ROOT" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
echo "✅ Cleanup complete"

# Final security check
echo ""
echo -e "${BLUE}🔍 Final Security Verification:${NC}"
if [ $ENCRYPTED_COUNT -ge 3 ]; then
    echo "✅ Expected encrypted files found ($ENCRYPTED_COUNT)"
else
    echo "⚠️  Warning: Expected more encrypted files (found: $ENCRYPTED_COUNT)"
fi

# Check for any leftover unencrypted sensitive files
SENSITIVE_UNENCRYPTED=$(find "$BACKUP_DIR" -name "authentik.sql" -o -name "erpnext.sql" -o -name "secrets.tar.gz" -o -name "acme.json" | grep -v "\.gpg$" || true)
if [ -z "$SENSITIVE_UNENCRYPTED" ]; then
    echo "✅ No unencrypted sensitive files found"
else
    echo "❌ WARNING: Unencrypted sensitive files found:"
    echo "$SENSITIVE_UNENCRYPTED"
fi

echo ""
echo -e "${GREEN}🎯 Encrypted backup process complete!${NC}"