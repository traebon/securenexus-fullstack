# SecureNexus Disaster Recovery Procedures

**Last Updated**: October 7, 2025
**Document Version**: 1.0
**Critical Priority**: CONFIDENTIAL

---

## Table of Contents

1. [Overview](#overview)
2. [Emergency Contacts](#emergency-contacts)
3. [Recovery Time Objectives (RTO/RPO)](#recovery-time-objectives-rtorpo)
4. [Backup Inventory](#backup-inventory)
5. [Complete System Recovery](#complete-system-recovery)
6. [Service-Specific Recovery](#service-specific-recovery)
7. [Data Recovery](#data-recovery)
8. [Verification Procedures](#verification-procedures)
9. [Post-Recovery Checklist](#post-recovery-checklist)

---

## Overview

This document provides step-by-step procedures for recovering the SecureNexus Full Stack infrastructure from various disaster scenarios.

### Disaster Scenarios Covered

1. **Complete server failure** (hardware/OS corruption)
2. **Data corruption** (database/volume corruption)
3. **Service failure** (individual service crashes)
4. **Security breach** (compromise requiring rebuild)
5. **Accidental deletion** (configuration/data loss)

---

## Emergency Contacts

### Primary Administrator
- **Name**: Tristian
- **System**: vps-09e1118a.securenexus.net
- **IP**: 137.74.40.208

### Critical Access Information
- **SSH**: Port 22 (standard)
- **VPN**: Tailscale (100.77.139.33)
- **Backup Location**: `/backup/securenexus/`
- **Git Repository**: Local at `/home/tristian/securenexus-fullstack`

---

## Recovery Time Objectives (RTO/RPO)

### Service Priority Tiers

| Tier | Services | RTO | RPO | Impact |
|------|----------|-----|-----|--------|
| **Critical** | DNS, Traefik, Authentik | 15 min | 1 hour | Complete outage |
| **High** | Mail, Monitoring | 1 hour | 6 hours | Service degradation |
| **Medium** | Portal, Homepage | 4 hours | 24 hours | User inconvenience |
| **Low** | Historical metrics | 24 hours | 7 days | No immediate impact |

**RTO**: Recovery Time Objective (how quickly service is restored)
**RPO**: Recovery Point Objective (maximum data loss acceptable)

---

## Backup Inventory

### Automated Backups

**Location**: `/backup/securenexus/`

**Schedule**:
- Daily: 7 days retention (02:00 AM)
- Weekly: 4 weeks retention (Sundays)
- Monthly: 12 months retention (1st of month)

**Contents**:
```
/backup/securenexus/
├── daily/
│   └── YYYYMMDD_HHMMSS/
│       ├── databases/
│       │   ├── authentik.sql (PostgreSQL dump)
│       │   ├── mysql.sql (CoreDNS records)
│       │   └── etcd.db (DNS dynamic records)
│       ├── volumes/
│       │   ├── grafana.tar.gz
│       │   ├── prometheus.tar.gz
│       │   ├── loki.tar.gz
│       │   └── uptime-kuma.tar.gz
│       └── config/
│           ├── compose.yml
│           ├── .env
│           ├── secrets.tar.gz (ENCRYPT!)
│           ├── config/ (Traefik, monitoring)
│           ├── dns-zones/
│           └── acme/ (SSL certificates)
├── weekly/ (same structure)
└── monthly/ (same structure)
```

### Off-Site Backups

**Recommendation**: Copy encrypted backups to:
- Cloud storage (encrypted)
- Physical backup drive (off-site)
- Secondary server

---

## Complete System Recovery

### Scenario: Total Server Loss

**Estimated Time**: 2-4 hours

#### Step 1: Provision New Server

```bash
# Minimum requirements:
- CPU: 4 cores
- RAM: 24 GB
- Disk: 200 GB
- OS: Ubuntu 24.04 LTS
- Network: Public IP, ports 22, 80, 443, 53, 25, 587, 993, 995, 143, 465
```

#### Step 2: Install Prerequisites

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Install required tools
sudo apt install git ufw jq curl wget -y

# Reboot
sudo reboot
```

#### Step 3: Configure Firewall

```bash
# Setup UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment "SSH"
sudo ufw allow 53 comment "DNS"
sudo ufw allow 80/tcp comment "HTTP"
sudo ufw allow 443/tcp comment "HTTPS"
sudo ufw allow 853/tcp comment "DNS-over-TLS"
sudo ufw allow 25/tcp comment "SMTP"
sudo ufw allow 143/tcp comment "IMAP"
sudo ufw allow 465/tcp comment "SMTPS"
sudo ufw allow 587/tcp comment "Submission"
sudo ufw allow 993/tcp comment "IMAPS"
sudo ufw allow 995/tcp comment "POP3S"
sudo ufw allow 41641/udp comment "Tailscale"
sudo ufw enable
```

#### Step 4: Clone Repository

```bash
# Create user (if needed)
sudo useradd -m -s /bin/bash tristian
sudo usermod -aG sudo,docker tristian
su - tristian

# Clone repository
cd ~
git clone <repository_url> securenexus-fullstack
# OR restore from backup
cd ~
tar -xzf /path/to/backup/config.tar.gz
```

#### Step 5: Restore Configuration

```bash
cd ~/securenexus-fullstack

# Restore from latest backup
LATEST_BACKUP=$(ls -t /backup/securenexus/daily/ | head -1)
BACKUP_DIR="/backup/securenexus/daily/${LATEST_BACKUP}"

# Restore configuration files
cp -r "${BACKUP_DIR}/config/"* .

# Restore secrets
tar -xzf "${BACKUP_DIR}/config/secrets.tar.gz"
chmod 600 secrets/*

# Restore .env
cp "${BACKUP_DIR}/config/.env" .

# Restore DNS zones
cp -r "${BACKUP_DIR}/config/dns-zones/"* dns/zones/

# Restore ACME certificates
sudo mkdir -p acme
sudo cp "${BACKUP_DIR}/config/acme/acme.json" acme/
sudo chmod 600 acme/acme.json
```

#### Step 6: Restore Docker Volumes

```bash
# Create volumes first
docker volume create securenexus-fullstack_grafana-data
docker volume create securenexus-fullstack_prometheus-data
docker volume create securenexus-fullstack_loki-data
docker volume create securenexus-fullstack_uptime-kuma-data

# Restore Grafana
docker run --rm -v securenexus-fullstack_grafana-data:/data \
  -v "${BACKUP_DIR}/volumes":/backup alpine \
  tar -xzf /backup/grafana.tar.gz -C /data

# Restore Prometheus (optional - metrics can be regenerated)
docker run --rm -v securenexus-fullstack_prometheus-data:/data \
  -v "${BACKUP_DIR}/volumes":/backup alpine \
  tar -xzf /backup/prometheus.tar.gz -C /data

# Restore Loki
docker run --rm -v securenexus-fullstack_loki-data:/data \
  -v "${BACKUP_DIR}/volumes":/backup alpine \
  tar -xzf /backup/loki.tar.gz -C /data

# Restore Uptime Kuma
docker run --rm -v securenexus-fullstack_uptime-kuma-data:/data \
  -v "${BACKUP_DIR}/volumes":/backup alpine \
  tar -xzf /backup/uptime-kuma.tar.gz -C /data
```

#### Step 7: Start Core Infrastructure

```bash
# Start in stages
make up-core          # Traefik, Docker proxy, CrowdSec
sleep 30

make up-identity      # Authentik
sleep 30

# Restore PostgreSQL database
docker compose exec -T authentik_db psql -U authentik -d authentik < "${BACKUP_DIR}/databases/authentik.sql"
docker compose restart authentik_server authentik_worker
```

#### Step 8: Start Remaining Services

```bash
make up-dns           # CoreDNS, etcd, MySQL
sleep 30

# Restore etcd
docker compose cp "${BACKUP_DIR}/databases/etcd.db" etcd:/tmp/etcd_backup.db
docker compose exec etcd etcdctl snapshot restore /tmp/etcd_backup.db --data-dir /etcd-data-new
docker compose restart etcd

# Restore MySQL (if used)
MYSQL_PASS=$(cat secrets/mysql_password.txt)
docker compose exec -T mysql-db mysql -u coredns -p"$MYSQL_PASS" coredns < "${BACKUP_DIR}/databases/mysql.sql"

make up-monitoring    # Prometheus, Grafana, Loki
make up-portal        # Landing, Homepage
```

#### Step 9: Setup Tailscale VPN

```bash
# Install Tailscale on host
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Update firewall if needed
# Update admin-vpn middleware IP ranges in config/dynamic/traefik_dynamic.yml
```

#### Step 10: Verify Recovery

```bash
# Check all services
docker compose ps

# Test DNS
dig @localhost portal.securenexus.net

# Test web services
curl -I https://portal.securenexus.net

# Check Grafana
curl -I https://grafana.securenexus.net

# Verify Authentik
curl -I https://sso.securenexus.net
```

---

## Service-Specific Recovery

### PostgreSQL (Authentik Database)

```bash
# Stop Authentik services
docker compose stop authentik_server authentik_worker

# Restore database
docker compose exec -T authentik_db psql -U authentik -d authentik < /path/to/authentik.sql

# Restart services
docker compose start authentik_server authentik_worker

# Verify
docker compose logs authentik_server | tail -20
```

### etcd (Dynamic DNS)

```bash
# Stop CoreDNS
docker compose stop coredns

# Restore snapshot
docker compose cp /path/to/etcd.db etcd:/tmp/etcd_backup.db
docker compose exec etcd etcdctl snapshot restore /tmp/etcd_backup.db

# Restart services
docker compose restart etcd coredns

# Verify
docker compose exec etcd etcdctl get --prefix /coredns
```

### Grafana

```bash
# Stop Grafana
docker compose stop grafana

# Restore volume
docker run --rm -v securenexus-fullstack_grafana-data:/data \
  -v /path/to/backup:/backup alpine \
  sh -c "rm -rf /data/* && tar -xzf /backup/grafana.tar.gz -C /data"

# Restart
docker compose start grafana

# Verify
curl -I https://grafana.securenexus.net
```

### SSL Certificates (ACME)

```bash
# Stop Traefik
docker compose stop traefik

# Restore certificates
sudo cp /path/to/backup/acme.json acme/
sudo chmod 600 acme/acme.json

# Restart Traefik
docker compose start traefik

# Verify
openssl s_client -connect portal.securenexus.net:443 -servername portal.securenexus.net < /dev/null
```

---

## Data Recovery

### Individual File Recovery

```bash
# Find backup containing file
find /backup/securenexus -name "filename"

# Extract specific file
tar -xzf /backup/path/archive.tar.gz path/to/file
```

### Point-in-Time Recovery

```bash
# List available backups
ls -lh /backup/securenexus/daily/
ls -lh /backup/securenexus/weekly/
ls -lh /backup/securenexus/monthly/

# Choose backup based on date
RESTORE_DATE="20251007"
BACKUP_DIR="/backup/securenexus/daily/${RESTORE_DATE}_*"

# Restore from that point
# (follow Complete System Recovery steps)
```

---

## Verification Procedures

### Post-Recovery Checklist

After any recovery, verify all critical functions:

#### 1. Infrastructure Health

```bash
# All containers running
docker compose ps | grep -c "Up"  # Should equal 29

# All healthy
docker compose ps | grep -c "healthy"  # Check health status

# Resource usage normal
docker stats --no-stream
```

#### 2. Network Services

```bash
# DNS resolution
dig @localhost portal.securenexus.net +short

# HTTPS working
curl -I https://portal.securenexus.net | grep "200 OK"

# SSL certificates valid
echo | openssl s_client -connect portal.securenexus.net:443 2>/dev/null | openssl x509 -noout -dates
```

#### 3. Authentication

```bash
# Authentik responding
curl -I https://sso.securenexus.net | grep "200 OK"

# Database connected
docker compose logs authentik_server | grep -i "connected"

# Test login (manual)
# Navigate to https://sso.securenexus.net
```

#### 4. Monitoring

```bash
# Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
# Should return nothing

# Grafana accessible
curl -I https://grafana.securenexus.net

# Alerts configured
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[].name'
```

#### 5. Mail Services

```bash
# Check Mailcow containers
cd mail/mailcow && docker compose ps

# Test SMTP
telnet localhost 25
# Type: QUIT

# Test IMAP
telnet localhost 143
# Type: a01 LOGOUT
```

#### 6. Data Integrity

```bash
# PostgreSQL
docker compose exec authentik_db psql -U authentik -d authentik -c "SELECT COUNT(*) FROM auth_user;"

# etcd
docker compose exec etcd etcdctl get --prefix /coredns | wc -l

# Grafana dashboards
curl -s -u admin:password http://localhost:3000/api/search | jq 'length'
```

---

## Post-Recovery Checklist

### Immediate (First Hour)

- [ ] All 29 containers running and healthy
- [ ] DNS resolution working
- [ ] HTTPS sites accessible (portal, grafana, traefik)
- [ ] Authentik login working
- [ ] Monitoring collecting metrics
- [ ] Firewall rules active
- [ ] Tailscale VPN connected

### Short-Term (First Day)

- [ ] All Prometheus targets up (19/19)
- [ ] SSL certificates valid and auto-renewing
- [ ] Mail delivery working (send/receive test)
- [ ] Backup automation running
- [ ] Alert rules active in Alertmanager
- [ ] Log aggregation working (Loki)
- [ ] No critical errors in logs

### Medium-Term (First Week)

- [ ] Monitor resource usage trends
- [ ] Verify all user accounts accessible
- [ ] Test all SSO integrations
- [ ] Confirm backup rotation working
- [ ] Review and tune alert thresholds
- [ ] Document any recovery issues
- [ ] Update disaster recovery plan

---

## Recovery Scenarios

### Scenario 1: Single Container Failure

**Problem**: One container crashed or corrupted

**Solution**:
```bash
# Restart container
docker compose restart [service_name]

# If still failing, recreate
docker compose up -d --force-recreate [service_name]

# If data corrupted, restore from backup
# (see Service-Specific Recovery)
```

**Time**: 5-15 minutes

---

### Scenario 2: Database Corruption

**Problem**: PostgreSQL or MySQL data corrupted

**Solution**:
```bash
# Stop dependent services
docker compose stop authentik_server authentik_worker

# Restore database
docker compose exec -T authentik_db psql -U authentik -d authentik < /backup/latest/databases/authentik.sql

# Restart services
docker compose start authentik_server authentik_worker

# Verify
docker compose logs authentik_server
```

**Time**: 15-30 minutes

---

### Scenario 3: Configuration Loss

**Problem**: Accidentally deleted configuration files

**Solution**:
```bash
# Restore from backup
LATEST_BACKUP=$(ls -t /backup/securenexus/daily/ | head -1)
cp -r /backup/securenexus/daily/${LATEST_BACKUP}/config/* /home/tristian/securenexus-fullstack/

# OR restore from Git
cd /home/tristian/securenexus-fullstack
git reset --hard HEAD

# Restart affected services
docker compose restart traefik
```

**Time**: 5-10 minutes

---

### Scenario 4: SSL Certificate Loss

**Problem**: ACME certificates deleted or corrupted

**Solution**:
```bash
# Option 1: Restore from backup
sudo cp /backup/latest/config/acme/acme.json acme/
sudo chmod 600 acme/acme.json
docker compose restart traefik

# Option 2: Regenerate (takes longer)
sudo rm acme/acme.json
docker compose restart traefik
# Wait for ACME challenge (5-10 minutes)
```

**Time**: 5-15 minutes

---

### Scenario 5: Secrets Compromised

**Problem**: Security breach, need to rotate all secrets

**Solution**:
```bash
# 1. Shut down services immediately
docker compose down

# 2. Generate new secrets
cd scripts
./generate-secrets.sh

# 3. Update Authentik secret key (CRITICAL - don't rotate unless breach)
# Keep existing: authentik_secret_key

# 4. Rotate databases passwords
# Update: postgres_password, redis_password, mysql_password

# 5. Restart with new secrets
docker compose up -d

# 6. Force all users to re-login
docker compose exec authentik_server ak user session clear --all

# 7. Review audit logs for breach scope
docker compose logs --since 24h authentik_server | grep -i "failed\|unauthorized"
```

**Time**: 1-2 hours

---

### Scenario 6: Tailscale VPN Lost

**Problem**: Cannot access admin services

**Solution**:
```bash
# Option 1: Re-authenticate Tailscale
sudo tailscale up

# Option 2: Temporarily disable VPN requirement
# Edit config/dynamic/traefik_dynamic.yml
# Comment out admin-vpn middleware for emergency access
# SECURITY WARNING: Only do this from trusted network!

# After regaining access, restore VPN protection
```

**Time**: 10-30 minutes

---

## Testing Disaster Recovery

### Regular Testing Schedule

- **Monthly**: Test single service restoration
- **Quarterly**: Test complete database restoration
- **Bi-Annually**: Full disaster recovery drill

### Test Procedure

```bash
# 1. Document current state
docker compose ps > /tmp/pre-test-state.txt

# 2. Create test backup
/home/tristian/securenexus-fullstack/scripts/backup-all.sh

# 3. Perform destructive test (in isolated environment if possible)
# Example: Corrupt a database
docker compose exec authentik_db psql -U authentik -c "DROP DATABASE authentik;"

# 4. Time the recovery
time {
    # Restore steps here
    docker compose exec -T authentik_db psql -U authentik < /backup/latest/databases/authentik.sql
}

# 5. Verify recovery
docker compose ps
# Run all verification checks

# 6. Document results and lessons learned
```

---

## Appendix: Emergency Commands

### Quick Reference

```bash
# Stop everything
docker compose down

# Start everything
docker compose up -d

# Restart specific service
docker compose restart [service]

# View logs
docker compose logs -f [service]

# Check health
docker compose ps
docker stats --no-stream

# Latest backup location
ls -lht /backup/securenexus/daily/ | head -2

# Quick restore command
LATEST=$(ls -t /backup/securenexus/daily/ | head -1)
echo "Latest backup: /backup/securenexus/daily/$LATEST"
```

---

## Document History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-10-07 | Initial creation | System Admin |

---

**END OF DISASTER RECOVERY DOCUMENTATION**

**IMPORTANT**: Keep this document up-to-date and test procedures regularly!
