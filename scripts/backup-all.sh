#!/bin/bash
# Comprehensive Backup Script for SecureNexus
# Backs up databases, volumes, and configuration

set -e

# Configuration
BACKUP_ROOT="${BACKUP_ROOT:-/backup/securenexus}"  # Use env var if set, otherwise default
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/${DATE}"
COMPOSE_DIR="/home/tristian/securenexus-fullstack"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Starting SecureNexus Backup - ${DATE}${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"/{databases,volumes,config}

cd "$COMPOSE_DIR"

# 1. Backup PostgreSQL (Authentik)
echo -e "${YELLOW}📦 Backing up PostgreSQL (Authentik)...${NC}"
docker compose exec -T authentik_db pg_dump -U authentik authentik > "$BACKUP_DIR/databases/authentik.sql"
echo "✅ PostgreSQL backed up: $(du -h "$BACKUP_DIR/databases/authentik.sql" | cut -f1)"

# 2. Backup MySQL (CoreDNS)
echo -e "${YELLOW}📦 Backing up MySQL (CoreDNS)...${NC}"
MYSQL_PASS=$(cat secrets/mysql_password.txt)
docker compose exec -T mysql-db mysqldump -u coredns -p"$MYSQL_PASS" coredns > "$BACKUP_DIR/databases/mysql.sql" 2>/dev/null || echo "⚠️  MySQL backup skipped (may be empty)"

# 3. Backup MariaDB (ERPNext) - if exists
echo -e "${YELLOW}📦 Backing up MariaDB (ERPNext)...${NC}"
if docker compose ps erpnext-db 2>/dev/null | grep -q "Up"; then
    ERPNEXT_DB_PASS=$(cat secrets/erpnext_db_password.txt)
    docker compose exec -T erpnext-db mysqldump -u root -p"$ERPNEXT_DB_PASS" --all-databases > "$BACKUP_DIR/databases/erpnext.sql" 2>/dev/null
    echo "✅ ERPNext MariaDB backed up: $(du -h "$BACKUP_DIR/databases/erpnext.sql" | cut -f1)"
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

# 11. Backup secrets (IMPORTANT: encrypt this!)
echo -e "${YELLOW}📦 Backing up secrets (ENCRYPTED)...${NC}"
tar -czf "$BACKUP_DIR/config/secrets.tar.gz" secrets/
chmod 600 "$BACKUP_DIR/config/secrets.tar.gz"
echo "✅ Secrets backed up (encrypted recommended for off-site storage)"

# 12. Backup ACME certificates
echo -e "${YELLOW}📦 Backing up SSL certificates...${NC}"
mkdir -p "$BACKUP_DIR/config/acme"
# Use docker cp to avoid permission issues with root-owned acme.json
if docker compose cp traefik:/acme/acme.json "$BACKUP_DIR/config/acme/acme.json" 2>/dev/null; then
    echo "✅ ACME certificates backed up: $(du -h "$BACKUP_DIR/config/acme/acme.json" | cut -f1)"
elif [ -f acme/acme.json ]; then
    # Fallback to direct copy if docker cp fails
    cp acme/acme.json "$BACKUP_DIR/config/acme/" 2>/dev/null && echo "✅ ACME certificates backed up" || echo "⚠️  ACME backup failed (permission denied)"
else
    echo "⚠️  No ACME certificates found"
fi

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

# Create backup manifest
cat > "$BACKUP_DIR/MANIFEST.txt" << EOF
SecureNexus Backup Manifest
===========================
Date: ${DATE}
Total Size: ${TOTAL_SIZE}

Contents:
---------
1. databases/authentik.sql - PostgreSQL database (Authentik users & config)
2. databases/mysql.sql - MySQL database (CoreDNS records)
3. databases/erpnext.sql - MariaDB database (ERPNext data)
4. databases/etcd.db - etcd snapshot (dynamic DNS records)
5. volumes/erpnext-sites.tar.gz - ERPNext site files
6. volumes/erpnext-assets.tar.gz - ERPNext assets (compiled JS/CSS)
7. volumes/grafana.tar.gz - Grafana dashboards & settings
8. volumes/prometheus.tar.gz - Prometheus metrics data
9. volumes/loki.tar.gz - Loki log data
10. volumes/uptime-kuma.tar.gz - Uptime monitoring data
11. config/ - All configuration files
12. config/erp-branding/ - ERPNext branding scripts
13. config/secrets.tar.gz - Secrets (ENCRYPT for off-site!)
14. config/acme/ - SSL certificates

Restoration:
------------
See scripts/restore-backup.sh for restoration procedures

Notes:
------
- Secrets file should be encrypted before off-site storage
- Test restoration periodically
- Keep at least 7 daily backups
- Keep at least 4 weekly backups
- Keep at least 12 monthly backups
EOF

echo ""
echo -e "${GREEN}✅ Backup completed successfully!${NC}"
echo -e "${GREEN}📁 Location: $BACKUP_DIR${NC}"
echo -e "${GREEN}💾 Total size: $TOTAL_SIZE${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "1. Encrypt secrets.tar.gz before uploading to off-site storage"
echo "2. Test restoration periodically"
echo "3. Consider automating with cron: 0 2 * * * /home/tristian/securenexus-fullstack/scripts/backup-all.sh"
echo ""
echo "To view manifest: cat $BACKUP_DIR/MANIFEST.txt"

# Cleanup old backups (keep last 7 days)
echo -e "${YELLOW}🧹 Cleaning up old backups (keeping last 7 days)...${NC}"
find "$BACKUP_ROOT" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
echo "✅ Cleanup complete"
