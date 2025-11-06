# Commands Reference

Complete command reference for all SecureNexus components.

## Quick Access

For the most commonly used sysadmin commands, see [Reference Overview - System Administrator Quick Reference](overview.md#system-administrator-quick-reference).

## Docker & Docker Compose

### Container Management

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d <service-name>

# Stop all services
docker compose down

# Stop specific service
docker compose stop <service-name>

# Restart service
docker compose restart <service-name>

# View status
docker compose ps

# View logs
docker compose logs -f <service-name>

# Execute command in container
docker compose exec <service-name> <command>

# View resource usage
docker stats

# View detailed container info
docker inspect <container-id>
```

### Image Management

```bash
# Pull latest images
docker compose pull

# Build custom images
docker compose build

# List images
docker images

# Remove unused images
docker image prune -a

# Remove specific image
docker rmi <image-id>
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume-name>

# Remove unused volumes
docker volume prune

# Backup volume
docker run --rm -v <volume>:/data -v $(pwd):/backup alpine tar czf /backup/volume-backup.tar.gz /data

# Restore volume
docker run --rm -v <volume>:/data -v $(pwd):/backup alpine tar xzf /backup/volume-backup.tar.gz -C /
```

### Network Management

```bash
# List networks
docker network ls

# Inspect network
docker network inspect <network-name>

# Create network
docker network create <network-name>

# Connect container to network
docker network connect <network-name> <container-name>
```

## Make Commands

```bash
# Generate secrets
make secrets

# Pre-deployment checks
make preflight

# Start service groups
make up-core
make up-identity
make up-portal
make up-monitoring
make up-dns
make up-all

# Stop all services
make down

# View status
make ps

# View logs
make logs

# Restart specific service
make restart S=<service-name>
```

## ERPNext (Bench) Commands

### Site Management

```bash
# Create new site
docker compose exec erpnext-backend \
  bench new-site <domain> --admin-password <password> --install-app erpnext

# List sites
docker compose exec erpnext-backend bench --site all list-apps

# Drop site (WARNING: Permanent!)
docker compose exec erpnext-backend \
  bench drop-site <domain> --root-password <mysql-root-pass>

# Migrate site (after updates)
docker compose exec erpnext-backend bench --site <domain> migrate

# Clear cache
docker compose exec erpnext-backend bench --site <domain> clear-cache

# Rebuild assets
docker compose exec erpnext-backend bench build
```

### Backup & Restore

```bash
# Backup site
docker compose exec erpnext-backend \
  bench --site <domain> backup --with-files

# Backup all sites
docker compose exec erpnext-backend bench backup-all-sites

# Restore site
docker compose exec erpnext-backend \
  bench --site <domain> restore /path/to/backup.sql --with-files
```

### User Management

```bash
# Add system manager
docker compose exec erpnext-backend \
  bench --site <domain> add-system-manager user@example.com

# Set user password
docker compose exec erpnext-backend \
  bench --site <domain> set-admin-password <password>

# Disable user
docker compose exec erpnext-backend \
  bench --site <domain> disable-user user@example.com
```

### Debugging

```bash
# Console
docker compose exec erpnext-backend \
  bench --site <domain> console

# Doctor (health check)
docker compose exec erpnext-backend \
  bench --site <domain> doctor

# Reload DocTypes
docker compose exec erpnext-backend \
  bench --site <domain> reload-doctype <doctype>
```

## Database Commands

### MariaDB (ERPNext)

```bash
# Access MariaDB shell
docker compose exec mariadb mysql -u root -p

# Backup database
docker compose exec mariadb mysqldump -u root -p <database> > backup.sql

# Restore database
docker compose exec -T mariadb mysql -u root -p <database> < backup.sql

# List databases
docker compose exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# Database size
docker compose exec mariadb mysql -u root -p -e "
  SELECT table_schema AS 'Database',
         ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
  FROM information_schema.tables
  GROUP BY table_schema;"

# Optimize table
docker compose exec mariadb mysql -u root -p -e "
  USE <database>;
  OPTIMIZE TABLE \`tabSales Invoice\`;
  ANALYZE TABLE \`tabSales Invoice\`;"
```

### PostgreSQL (Authentik)

```bash
# Access PostgreSQL shell
docker compose exec authentik_db psql -U authentik -d authentik

# Backup database
docker compose exec authentik_db pg_dump -U authentik authentik > backup.sql

# Restore database
docker compose exec -T authentik_db psql -U authentik authentik < backup.sql

# Database size
docker compose exec authentik_db psql -U authentik -d authentik -c "
  SELECT pg_size_pretty(pg_database_size('authentik'));"

# Vacuum database
docker compose exec authentik_db psql -U authentik -d authentik -c "
  VACUUM ANALYZE;"

# List tables
docker compose exec authentik_db psql -U authentik -d authentik -c "\dt"
```

### Redis

```bash
# Access Redis CLI
docker compose exec redis_cache redis-cli

# Test connection
docker compose exec redis_cache redis-cli PING

# Get info
docker compose exec redis_cache redis-cli INFO

# Flush cache
docker compose exec redis_cache redis-cli FLUSHALL

# Get key count
docker compose exec redis_cache redis-cli DBSIZE
```

### etcd (DNS Records)

```bash
# List all keys
docker compose exec etcd etcdctl get --prefix /

# List DNS records
docker compose exec etcd etcdctl get --prefix /coredns/

# Get specific record
docker compose exec etcd etcdctl get /coredns/net/securenexus/<subdomain>

# Put record
docker compose exec etcd etcdctl put /coredns/net/securenexus/test '{"host":"1.2.3.4","ttl":300}'

# Delete record
docker compose exec etcd etcdctl del /coredns/net/securenexus/test

# Backup etcd
docker compose exec etcd etcdctl snapshot save /backup/etcd-snapshot.db

# Restore etcd
docker compose exec etcd etcdctl snapshot restore /backup/etcd-snapshot.db
```

## Monitoring Commands

### Prometheus

```bash
# Query metric
curl "http://localhost:9090/api/v1/query?query=up"

# Query range
curl "http://localhost:9090/api/v1/query_range?query=up&start=$(date -d '1 hour ago' +%s)&end=$(date +%s)&step=60"

# List targets
curl http://localhost:9090/api/v1/targets

# List alerts
curl http://localhost:9090/api/v1/alerts

# Reload configuration
curl -X POST http://localhost:9090/-/reload
```

### Loki

```bash
# Query logs (requires logcli)
logcli query '{container_name="erpnext-backend"}' --addr=http://localhost:3100

# Query with filter
logcli query '{container_name="traefik"} |= "error"' --addr=http://localhost:3100

# Tail logs
logcli query '{job="containers"}' --tail --addr=http://localhost:3100
```

### Grafana

```bash
# Reset admin password
docker compose exec grafana grafana-cli admin reset-admin-password <new-password>

# List datasources
curl -s http://admin:password@localhost:3000/api/datasources

# Create API key
curl -X POST http://admin:password@localhost:3000/api/auth/keys \
  -H "Content-Type: application/json" \
  -d '{"name":"api-key","role":"Admin"}'
```

## DNS Commands

### CoreDNS

```bash
# Test DNS resolution
dig @localhost <domain>

# Test specific record type
dig @localhost MX <domain>
dig @localhost TXT <domain>

# Test from external resolver
dig @8.8.8.8 <domain>

# Check CoreDNS metrics
curl http://localhost:9153/metrics

# View CoreDNS logs
docker compose logs coredns | tail -50
```

### DNS Sync

```bash
# Manually sync DNS records
./scripts/dns-sync.sh

# View etcd DNS records
docker compose exec etcd etcdctl get --prefix /coredns/
```

## Email Commands (Mailcow)

### Mail Queue

```bash
# View queue
docker exec mailcow-postfix-mailcow postqueue -p

# Flush queue
docker exec mailcow-postfix-mailcow postqueue -f

# Delete queue
docker exec mailcow-postfix-mailcow postsuper -d ALL
```

### Mailbox Management

```bash
# Via Mailcow API (requires API key)
# Add domain
curl -X POST "https://mail.securenexus.net/api/v1/add/domain" \
  -H "X-API-Key: <key>" \
  -d '{"domain":"example.com"}'

# Add mailbox
curl -X POST "https://mail.securenexus.net/api/v1/add/mailbox" \
  -H "X-API-Key: <key>" \
  -d '{"local_part":"user","domain":"example.com","password":"pass"}'

# List mailboxes
curl "https://mail.securenexus.net/api/v1/get/mailbox/all" \
  -H "X-API-Key: <key>"
```

### Testing

```bash
# Test SMTP
telnet mail.securenexus.net 587

# Test IMAP
telnet mail.securenexus.net 993

# Send test email
echo "Test message" | mail -s "Test Subject" user@example.com
```

## Security Commands

### Firewall (UFW)

```bash
# View status
sudo ufw status numbered

# View verbose
sudo ufw status verbose

# Allow port
sudo ufw allow <port>/<protocol>

# Allow from specific IP
sudo ufw allow from <ip> to any port <port>

# Rate limit (for SSH)
sudo ufw limit 22/tcp

# Delete rule
sudo ufw delete <rule-number>

# Reload firewall
sudo ufw reload

# Enable/disable
sudo ufw enable
sudo ufw disable
```

### CrowdSec

```bash
# List banned IPs
docker compose exec crowdsec cscli decisions list

# Ban IP
docker compose exec crowdsec cscli decisions add --ip <ip> --duration 4h --reason "Manual ban"

# Unban IP
docker compose exec crowdsec cscli decisions delete --ip <ip>

# View metrics
docker compose exec crowdsec cscli metrics

# Update patterns
docker compose exec crowdsec cscli hub update
docker compose exec crowdsec cscli hub upgrade
```

### SSL Certificates

```bash
# Check expiry
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | \
  openssl x509 -noout -enddate

# View certificate details
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | \
  openssl x509 -noout -text

# Test SSL
curl -vI https://<domain> 2>&1 | grep "SSL certificate verify"

# View Traefik certificates
docker compose exec traefik cat /acme.json | jq '.le.Certificates'
```

## Backup & Restore Commands

### Automated Backup

```bash
# Run backup
sudo ./scripts/backup-rotation.sh

# View backup log
tail -f /var/log/securenexus-backup.log

# List backups
ls -lh /backup/securenexus/{daily,weekly,monthly}/

# Verify latest backup
latest=$(ls -t /backup/securenexus/daily/ | head -1)
ls -lh /backup/securenexus/daily/$latest/
```

### Manual Backup

```bash
# Backup specific service
docker compose exec <service> <backup-command>

# Backup volume
docker run --rm -v <volume>:/data -v /backup:/backup alpine \
  tar czf /backup/<volume>-$(date +%Y%m%d).tar.gz /data
```

### Restore

```bash
# Restore from latest backup
./scripts/restore-from-backup.sh /backup/securenexus/daily/<latest>

# Restore specific volume
docker run --rm -v <volume>:/data -v /backup:/backup alpine \
  tar xzf /backup/<volume>.tar.gz -C /
```

## System Maintenance

### Updates

```bash
# Update OS packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker compose pull
docker compose up -d

# Update specific service
docker compose pull <service>
docker compose up -d <service>
```

### Cleanup

```bash
# Clean Docker system
docker system prune -a --volumes

# Clean old logs
sudo journalctl --vacuum-time=7d

# Clean old backups (keep retention policy)
# (handled automatically by backup-rotation.sh)

# Clean package cache
sudo apt clean
sudo apt autoclean
sudo apt autoremove
```

### Health Checks

```bash
# Quick health check
docker compose ps
df -h
free -h

# Full diagnostic
./scripts/system-diagnostic.sh

# Smoke tests
./scripts/smoke-postdeploy.sh
```

## Tailscale (VPN)

```bash
# Check status
docker compose exec tailscale tailscale status

# Check connected devices
docker compose exec tailscale tailscale status --json | jq '.Peer'

# Ping peer
docker compose exec tailscale tailscale ping <peer-name>

# Get IP
docker compose exec tailscale tailscale ip

# Restart Tailscale
docker compose restart tailscale
```

## Utility Scripts

All utility scripts are located in `scripts/` directory:

```bash
# Backup and recovery
./scripts/backup-rotation.sh                  # Automated backup
./scripts/backup-all.sh                       # Manual backup
./scripts/restore-from-backup.sh <path>       # Restore

# Setup and configuration
./scripts/generate-secrets.sh                 # Generate secrets
./scripts/preflight.sh                        # Pre-deployment checks
./scripts/setup-ufw-firewall.sh              # Configure firewall
./scripts/setup-automated-backups.sh          # Setup cron

# Client provisioning
./scripts/provision-client-complete.sh --name "Client" --subdomain "client"
./scripts/create-dickinson-user.sh            # Create user
./scripts/create-sysadmin-user.sh             # Create sysadmin

# SSL certificates
./scripts/update-mailcow-certs.sh             # Sync to Mailcow

# DNS management
./scripts/dns-sync.sh                          # Sync DNS records

# Testing
./scripts/smoke-postdeploy.sh                  # Post-deployment tests
./scripts/test-vpn-connection.sh               # Test VPN

# Maintenance
./scripts/cleanup-docker.sh                    # Clean Docker
```

## Next Steps

- **[System Administrator Reference](overview.md)**: Sysadmin quick reference
- **[API Reference](api.md)**: API documentation
- **[Troubleshooting](../troubleshooting/overview.md)**: Fix common issues
