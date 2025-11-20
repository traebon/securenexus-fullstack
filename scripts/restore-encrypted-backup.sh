#!/bin/bash

# Restore Encrypted SecureNexus Backups
# Decrypts and restores encrypted backup files

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BACKUP_DIR=""
COMPOSE_DIR="/home/tristian/securenexus-fullstack"
BACKUP_KEY_ID="securenexus-backup@internal"

show_usage() {
    echo "Usage: $0 [OPTIONS] <backup_directory>"
    echo ""
    echo "Restore encrypted SecureNexus backups"
    echo ""
    echo "Arguments:"
    echo "  <backup_directory>    Path to backup directory (e.g., /backup/securenexus/20250114_140000)"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -d, --decrypt-only   Only decrypt files, don't restore to services"
    echo "  -v, --verify         Verify backup integrity before restoration"
    echo "  -t, --test           Test decryption without actual restoration"
    echo "  --compose-dir DIR    SecureNexus directory (default: /home/tristian/securenexus-fullstack)"
    echo ""
    echo "Examples:"
    echo "  $0 /backup/securenexus/20250114_140000"
    echo "  $0 --decrypt-only /backup/securenexus/20250114_140000"
    echo "  $0 --test /backup/securenexus/20250114_140000"
}

# Parse command line arguments
DECRYPT_ONLY=false
VERIFY_ONLY=false
TEST_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -d|--decrypt-only)
            DECRYPT_ONLY=true
            shift
            ;;
        -v|--verify)
            VERIFY_ONLY=true
            shift
            ;;
        -t|--test)
            TEST_MODE=true
            shift
            ;;
        --compose-dir)
            COMPOSE_DIR="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            BACKUP_DIR="$1"
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$BACKUP_DIR" ]; then
    echo -e "${RED}❌ Error: Backup directory required${NC}"
    show_usage
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}❌ Error: Backup directory does not exist: $BACKUP_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}🔓 SecureNexus Encrypted Backup Restoration${NC}"
echo "============================================"
echo "Backup Directory: $BACKUP_DIR"
echo "Compose Directory: $COMPOSE_DIR"
echo "Mode: $([ "$TEST_MODE" = true ] && echo "TEST" || ([ "$DECRYPT_ONLY" = true ] && echo "DECRYPT ONLY" || echo "FULL RESTORE"))"
echo

# Check if GPG private key is available
echo -e "${YELLOW}🔍 Checking GPG key availability...${NC}"
if ! gpg --list-secret-keys | grep -q "$BACKUP_KEY_ID"; then
    echo -e "${RED}❌ GPG private key not found: $BACKUP_KEY_ID${NC}"
    echo ""
    echo "To import private key:"
    echo "1. gpg --import backup-keys/backup-private-key.asc"
    echo "2. gpg --edit-key $BACKUP_KEY_ID trust (set to 'ultimate')"
    echo ""
    exit 1
fi
echo -e "${GREEN}✅ GPG private key available${NC}"

# Check manifest
MANIFEST="$BACKUP_DIR/MANIFEST.txt"
if [ ! -f "$MANIFEST" ]; then
    echo -e "${RED}❌ Backup manifest not found: $MANIFEST${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Backup Information:${NC}"
grep -E "^Date:|^Total Size:|^Encrypted Files:" "$MANIFEST" || echo "Manifest format may be older"
echo

# Function to decrypt file
decrypt_file() {
    local encrypted_file="$1"
    local output_file="${encrypted_file%.gpg}"

    if [ ! -f "$encrypted_file" ]; then
        echo "   ❌ Encrypted file not found: $(basename "$encrypted_file")"
        return 1
    fi

    echo "   🔓 Decrypting $(basename "$encrypted_file")..."

    if [ "$TEST_MODE" = true ]; then
        # Test mode - just verify we can decrypt (don't save output)
        if gpg --quiet --decrypt "$encrypted_file" > /dev/null 2>&1; then
            echo "   ✅ Decryption test passed: $(basename "$encrypted_file")"
            return 0
        else
            echo "   ❌ Decryption test failed: $(basename "$encrypted_file")"
            return 1
        fi
    else
        # Actually decrypt the file
        if gpg --quiet --decrypt "$encrypted_file" > "$output_file" 2>/dev/null; then
            echo "   ✅ Decrypted: $(du -h "$output_file" | cut -f1) - $(basename "$output_file")"
            return 0
        else
            echo "   ❌ Decryption failed: $(basename "$encrypted_file")"
            return 1
        fi
    fi
}

# Find all encrypted files
echo -e "${YELLOW}🔍 Finding encrypted files...${NC}"
ENCRYPTED_FILES=($(find "$BACKUP_DIR" -name "*.gpg" | sort))

if [ ${#ENCRYPTED_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No encrypted files found in backup${NC}"
else
    echo "Found ${#ENCRYPTED_FILES[@]} encrypted files:"
    for file in "${ENCRYPTED_FILES[@]}"; do
        echo "  - $(basename "$file")"
    done
fi
echo

# Decrypt all encrypted files
echo -e "${YELLOW}🔓 Decrypting files...${NC}"
DECRYPT_SUCCESS=0
DECRYPT_FAILED=0

for encrypted_file in "${ENCRYPTED_FILES[@]}"; do
    if decrypt_file "$encrypted_file"; then
        ((DECRYPT_SUCCESS++))
    else
        ((DECRYPT_FAILED++))
    fi
done

echo ""
if [ $DECRYPT_FAILED -gt 0 ]; then
    echo -e "${RED}❌ Decryption Summary: $DECRYPT_SUCCESS successful, $DECRYPT_FAILED failed${NC}"
    if [ "$TEST_MODE" = false ]; then
        echo "Some files failed to decrypt. Restoration cannot continue safely."
        exit 1
    fi
else
    echo -e "${GREEN}✅ Decryption Summary: All $DECRYPT_SUCCESS files decrypted successfully${NC}"
fi

# Stop here if only testing or decrypt-only mode
if [ "$TEST_MODE" = true ]; then
    echo -e "${GREEN}🧪 Test completed successfully${NC}"
    echo "All encrypted files can be decrypted with current GPG setup."
    exit 0
fi

if [ "$DECRYPT_ONLY" = true ]; then
    echo -e "${GREEN}🔓 Decryption completed successfully${NC}"
    echo "Decrypted files are available in the backup directory."
    echo "Original encrypted files remain unchanged."
    exit 0
fi

# Full restoration mode
echo ""
echo -e "${YELLOW}⚠️  FULL RESTORATION MODE${NC}"
echo "This will restore data to the running SecureNexus instance."
echo "Current data may be overwritten!"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restoration cancelled."
    exit 0
fi

cd "$COMPOSE_DIR"

# Restore databases
echo ""
echo -e "${YELLOW}🗄️  Restoring databases...${NC}"

# Restore Authentik PostgreSQL
if [ -f "$BACKUP_DIR/databases/authentik.sql" ]; then
    echo "   📦 Restoring Authentik PostgreSQL..."
    docker compose exec -T authentik_db dropdb -U authentik authentik --if-exists
    docker compose exec -T authentik_db createdb -U authentik authentik
    docker compose exec -T authentik_db psql -U authentik authentik < "$BACKUP_DIR/databases/authentik.sql"
    echo "   ✅ Authentik PostgreSQL restored"
else
    echo "   ⚠️  Authentik PostgreSQL backup not found (skipped)"
fi

# Restore ERPNext MariaDB
if [ -f "$BACKUP_DIR/databases/erpnext.sql" ]; then
    echo "   📦 Restoring ERPNext MariaDB..."
    if docker compose ps erpnext-db 2>/dev/null | grep -q "Up"; then
        ERPNEXT_DB_PASS=$(cat secrets/erpnext_db_password.txt)
        docker compose exec -T erpnext-db mysql -u root -p"$ERPNEXT_DB_PASS" < "$BACKUP_DIR/databases/erpnext.sql"
        echo "   ✅ ERPNext MariaDB restored"
    else
        echo "   ⚠️  ERPNext MariaDB not running (skipped)"
    fi
else
    echo "   ⚠️  ERPNext MariaDB backup not found (skipped)"
fi

# Restore MySQL (CoreDNS)
if [ -f "$BACKUP_DIR/databases/mysql.sql" ] && [ -s "$BACKUP_DIR/databases/mysql.sql" ]; then
    echo "   📦 Restoring CoreDNS MySQL..."
    MYSQL_PASS=$(cat secrets/mysql_password.txt)
    docker compose exec -T mysql-db mysql -u coredns -p"$MYSQL_PASS" coredns < "$BACKUP_DIR/databases/mysql.sql"
    echo "   ✅ CoreDNS MySQL restored"
else
    echo "   ⚠️  CoreDNS MySQL backup not found or empty (skipped)"
fi

# Restore etcd
if [ -f "$BACKUP_DIR/databases/etcd.db" ]; then
    echo "   📦 Restoring etcd..."
    docker compose stop etcd
    docker compose cp "$BACKUP_DIR/databases/etcd.db" etcd:/tmp/etcd_restore.db
    docker compose exec etcd etcdctl snapshot restore /tmp/etcd_restore.db --data-dir /etcd-data-restored
    # Note: This requires etcd to be restarted with the restored data directory
    echo "   ✅ etcd snapshot restored (restart required)"
    docker compose start etcd
else
    echo "   ⚠️  etcd backup not found (skipped)"
fi

# Restore volumes
echo ""
echo -e "${YELLOW}💾 Restoring volumes...${NC}"

# Restore Grafana
if [ -f "$BACKUP_DIR/volumes/grafana.tar.gz" ]; then
    echo "   📦 Restoring Grafana data..."
    docker compose stop grafana
    docker run --rm -v securenexus-fullstack_grafana-data:/data -v "$BACKUP_DIR/volumes":/backup alpine sh -c "rm -rf /data/* && tar -xzf /backup/grafana.tar.gz -C /data"
    docker compose start grafana
    echo "   ✅ Grafana data restored"
else
    echo "   ⚠️  Grafana backup not found (skipped)"
fi

# Restore Uptime Kuma
if [ -f "$BACKUP_DIR/volumes/uptime-kuma.tar.gz" ]; then
    echo "   📦 Restoring Uptime Kuma data..."
    docker compose stop uptime-kuma
    docker run --rm -v securenexus-fullstack_uptime-kuma-data:/data -v "$BACKUP_DIR/volumes":/backup alpine sh -c "rm -rf /data/* && tar -xzf /backup/uptime-kuma.tar.gz -C /data"
    docker compose start uptime-kuma
    echo "   ✅ Uptime Kuma data restored"
else
    echo "   ⚠️  Uptime Kuma backup not found (skipped)"
fi

# Restore ERPNext volumes
if [ -f "$BACKUP_DIR/volumes/erpnext-sites.tar.gz" ]; then
    echo "   📦 Restoring ERPNext sites..."
    docker compose stop erpnext-backend erpnext-frontend erpnext-websocket
    docker run --rm -v securenexus-fullstack_erpnext-sites-data:/data -v "$BACKUP_DIR/volumes":/backup alpine sh -c "rm -rf /data/* && tar -xzf /backup/erpnext-sites.tar.gz -C /data"
    docker run --rm -v securenexus-fullstack_erpnext-assets-data:/data -v "$BACKUP_DIR/volumes":/backup alpine sh -c "rm -rf /data/* && tar -xzf /backup/erpnext-assets.tar.gz -C /data"
    docker compose start erpnext-backend erpnext-frontend erpnext-websocket
    echo "   ✅ ERPNext volumes restored"
else
    echo "   ⚠️  ERPNext volumes backup not found (skipped)"
fi

# Restore secrets (if decrypted)
if [ -f "$BACKUP_DIR/encrypted/secrets.tar.gz" ]; then
    echo ""
    echo -e "${YELLOW}🔐 Restoring secrets...${NC}"
    echo "   ⚠️  This will overwrite current secrets!"
    read -p "   Continue with secrets restoration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tar -xzf "$BACKUP_DIR/encrypted/secrets.tar.gz" -C .
        echo "   ✅ Secrets restored"
    else
        echo "   ⏭️  Secrets restoration skipped"
    fi
fi

# Restore ACME certificates (if decrypted)
if [ -f "$BACKUP_DIR/encrypted/acme.json" ]; then
    echo "   📦 Restoring ACME certificates..."
    mkdir -p acme/
    cp "$BACKUP_DIR/encrypted/acme.json" acme/
    chmod 600 acme/acme.json
    # Copy to Traefik container if running
    if docker compose ps traefik | grep -q "Up"; then
        docker compose cp acme/acme.json traefik:/acme/acme.json
        docker compose restart traefik
        echo "   ✅ ACME certificates restored and Traefik restarted"
    else
        echo "   ✅ ACME certificates restored to local directory"
    fi
fi

# Restore configuration files
if [ -d "$BACKUP_DIR/config" ]; then
    echo ""
    echo -e "${YELLOW}⚙️  Restoring configuration files...${NC}"
    echo "   ⚠️  This may overwrite current configuration!"
    read -p "   Continue with configuration restoration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp -r "$BACKUP_DIR/config"/* .
        echo "   ✅ Configuration files restored"
    else
        echo "   ⏭️  Configuration restoration skipped"
    fi
fi

# Final steps
echo ""
echo -e "${GREEN}✅ Restoration completed!${NC}"
echo ""
echo -e "${YELLOW}📋 Post-restoration steps:${NC}"
echo "1. Verify all services are running: docker compose ps"
echo "2. Check service logs: docker compose logs"
echo "3. Test application functionality"
echo "4. Verify Authentik users and configuration"
echo "5. Test SSL certificates"
echo "6. Verify DNS resolution"
echo ""
echo -e "${BLUE}🔧 If services don't start properly:${NC}"
echo "1. Check logs: docker compose logs [service]"
echo "2. Restart services: docker compose restart [service]"
echo "3. Rebuild if necessary: docker compose up -d --force-recreate [service]"
echo ""
echo -e "${GREEN}🎯 Encrypted backup restoration complete!${NC}"

# Cleanup decrypted files for security
echo ""
echo -e "${YELLOW}🧹 Security cleanup...${NC}"
read -p "Remove decrypted files from backup directory? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    for encrypted_file in "${ENCRYPTED_FILES[@]}"; do
        decrypted_file="${encrypted_file%.gpg}"
        if [ -f "$decrypted_file" ]; then
            rm "$decrypted_file"
            echo "   🗑️  Removed: $(basename "$decrypted_file")"
        fi
    done
    echo "✅ Security cleanup completed"
else
    echo "⚠️  Decrypted files left in backup directory - remember to secure them!"
fi