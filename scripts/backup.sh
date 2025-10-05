#!/bin/bash
# SecureNexus Full Stack - Automated Backup Script
# Performs comprehensive backup of all critical data

set -euo pipefail

# Configuration
BACKUP_ROOT="${BACKUP_ROOT:-/backup}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/securenexus-${TIMESTAMP}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
log_info "Creating backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"/{databases,volumes,config,secrets}

# Change to project directory
cd "$(dirname "$0")/.."

# Backup PostgreSQL (Authentik)
log_info "Backing up PostgreSQL (Authentik)..."
if docker compose exec -T authentik_db pg_dump -U authentik authentik > "${BACKUP_DIR}/databases/authentik_$(date +%Y%m%d).sql" 2>/dev/null; then
    log_info "PostgreSQL backup completed"
else
    log_warn "PostgreSQL backup failed or skipped"
fi

# Backup etcd (DNS records)
log_info "Backing up etcd (DNS records)..."
if docker compose exec etcd etcdctl snapshot save /tmp/etcd_backup.db >/dev/null 2>&1; then
    docker compose cp etcd:/tmp/etcd_backup.db "${BACKUP_DIR}/databases/etcd_$(date +%Y%m%d).db"
    log_info "etcd backup completed"
else
    log_warn "etcd backup failed"
fi

# Backup Grafana data
log_info "Backing up Grafana data..."
docker run --rm -v securenexus-fullstack_grafana-data:/data -v "${BACKUP_DIR}/volumes":/backup alpine tar -czf /backup/grafana_$(date +%Y%m%d).tar.gz -C /data . 2>/dev/null || log_warn "Grafana backup failed"

# Backup Headscale data
log_info "Backing up Headscale data..."
docker run --rm -v securenexus-fullstack_headscale-data:/data -v "${BACKUP_DIR}/volumes":/backup alpine tar -czf /backup/headscale_$(date +%Y%m%d).tar.gz -C /data . 2>/dev/null || log_warn "Headscale backup failed"

# Backup configuration files
log_info "Backing up configuration files..."
tar -czf "${BACKUP_DIR}/config/config_$(date +%Y%m%d).tar.gz" config/ dns/zones/ headscale/ monitoring/ compose.yml .env 2>/dev/null

# Backup secrets
log_info "Backing up secrets..."
tar -czf "${BACKUP_DIR}/secrets/secrets_$(date +%Y%m%d).tar.gz" secrets/ 2>/dev/null
chmod 600 "${BACKUP_DIR}/secrets/secrets_$(date +%Y%m%d).tar.gz"

# Backup ACME certificates
log_info "Backing up ACME certificates..."
if [ -d acme ]; then
    tar -czf "${BACKUP_DIR}/config/acme_$(date +%Y%m%d).tar.gz" acme/ 2>/dev/null
fi

# Calculate backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
log_info "Backup completed - Size: ${BACKUP_SIZE}"
log_info "Location: ${BACKUP_DIR}"

# Cleanup old backups
find "${BACKUP_ROOT}" -maxdepth 1 -type d -name "securenexus-*" -mtime +${RETENTION_DAYS} -exec rm -rf {} \; 2>/dev/null || true

log_info "Backup process complete!"
