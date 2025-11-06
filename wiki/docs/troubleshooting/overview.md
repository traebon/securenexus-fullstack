# Troubleshooting Overview

Common issues, solutions, and diagnostic procedures for the SecureNexus platform.

## Quick Diagnostics

### System Health Check

```bash
# Check all containers
docker compose ps

# Expected: All services showing "Up" or "Up (healthy)"
# If any show "Restarting" or "Exit", investigate

# View resource usage
docker stats --no-stream

# Check disk space
df -h

# Check memory
free -h

# Check load average
uptime
```

### Service Status

```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | \
  jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Check Traefik routers
curl -s http://localhost:8080/api/http/routers | jq

# Check firewall status
sudo ufw status numbered
```

## Common Issues

### 1. Container Won't Start

**Symptoms**:
- Container shows "Restarting" or "Exit (1)"
- Service not accessible

**Diagnosis**:
```bash
# Check container logs
docker compose logs <service-name> --tail=50

# Check container exit code
docker compose ps <service-name>

# Inspect container
docker inspect <container-id>
```

**Common causes**:

#### Missing Environment Variables

```bash
# Check .env file
cat .env

# Verify required variables set
grep DOMAIN .env
grep EMAIL .env
```

**Fix**: Set missing variables in `.env`

#### Missing Secrets

```bash
# Check secrets directory
ls -la secrets/

# Regenerate if needed
make secrets
```

**Fix**: Generate missing secrets

#### Port Conflict

```bash
# Check listening ports
sudo ss -tulpn | grep :<port>
```

**Fix**: Stop conflicting service or change port in compose.yml

#### Dependency Not Ready

```bash
# Check depends_on in compose.yml
docker compose config | grep -A5 depends_on
```

**Fix**: Ensure dependencies are running, add health checks

### 2. SSL Certificate Issues

**Symptoms**:
- Browser shows "Your connection is not private"
- Certificate warnings

**Diagnosis**:
```bash
# Check Traefik ACME logs
docker compose logs traefik | grep -i acme | tail -50

# View stored certificates
docker compose exec traefik cat /acme.json | jq '.le.Certificates'

# Test SSL
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | \
  openssl x509 -noout -dates
```

**Common causes**:

#### DNS Not Propagated

```bash
# Check DNS resolution
dig <domain>

# Check from external resolver
dig @8.8.8.8 <domain>
```

**Fix**: Wait for DNS propagation (up to 24-48 hours)

#### Rate Limit Exceeded

```bash
# Check Traefik logs for rate limit errors
docker compose logs traefik | grep -i "rate limit"
```

**Fix**: Wait 1 hour, use DNS-01 challenge, or use staging Let's Encrypt

**Documentation**: [SSL Final Solution](../SSL_FINAL_SOLUTION.md)

#### Firewall Blocking

```bash
# Check if port 80/443 open
sudo ufw status | grep -E "(80|443)"

# Test externally
curl -I http://<domain>
```

**Fix**: Open ports 80 and 443

### 3. VPN Access Issues

**Symptoms**:
- Can't access Grafana/Prometheus/Portainer
- 403 Forbidden error

**Diagnosis**:
```bash
# Check Tailscale status
docker compose logs tailscale | tail -20

# Check Tailscale connection
docker compose exec tailscale tailscale status

# Verify client connected
# (on client device)
tailscale status
```

**Common causes**:

#### Tailscale Not Running

```bash
# Check container
docker compose ps tailscale
```

**Fix**: `docker compose up -d tailscale`

#### Client Not Connected

**Fix**: Start Tailscale on client device, authenticate

#### IP Not in Whitelist

**Middleware** (`config/dynamic/traefik_dynamic.yml`):
```yaml
admin-vpn:
  ipWhiteList:
    sourceRange:
      - "100.64.0.0/10"  # Tailscale range
```

**Fix**: Ensure client IP in 100.64.0.0/10 range

**Documentation**:
- [Admin VPN Access Fix](../ADMIN_VPN_ACCESS_FIX.md)
- [VPN Health Check Issue](../VPN_HEALTH_CHECK_ISSUE.md)
- [Tailscale Access Guide](../TAILSCALE_ACCESS_GUIDE.md)

### 4. Grafana 403 Forbidden

**Symptom**: Grafana returns 403 Forbidden

**Cause**: VPN middleware blocking non-Tailscale IPs

**Solution**:
1. Install Tailscale on client device
2. Connect to VPN
3. Retry accessing Grafana

**Alternative** (temporary, not recommended):
```yaml
# Remove admin-vpn middleware temporarily
# In compose.yml, remove from Grafana labels:
# - traefik.http.routers.grafana.middlewares=admin-vpn@file
```

**Documentation**: [Grafana 403 Explanation](../GRAFANA_403_EXPLANATION.md)

### 5. DNS Resolution Issues

**Symptoms**:
- DNS queries failing
- Services can't resolve each other

**Diagnosis**:
```bash
# Test DNS locally
dig @localhost <domain>

# Check CoreDNS logs
docker compose logs coredns | tail -50

# Check etcd records
docker compose exec etcd etcdctl get --prefix /coredns/
```

**Common causes**:

#### CoreDNS Not Running

```bash
docker compose ps coredns
```

**Fix**: `make up-dns`

#### etcd Empty

```bash
# Manually sync DNS records
./scripts/dns-sync.sh
```

#### Zone File Error

```bash
# Validate zone file syntax
named-checkzone securenexus.net dns/zones/securenexus.net.zone
```

**Fix**: Correct syntax errors in zone file

### 6. Email Not Sending

**Symptoms**:
- ERPNext can't send email
- Emails not received

**Diagnosis**:
```bash
# Check Mailcow logs
docker logs mailcow-postfix-mailcow | tail -50

# Check mail queue
docker exec mailcow-postfix-mailcow postqueue -p

# Test SMTP
telnet mail.securenexus.net 587
```

**Common causes**:

#### Incorrect Credentials

**Check** (`sites/<site>/site_config.json`):
```json
{
  "mail_server": "mail.securenexus.net",
  "mail_port": 587,
  "use_tls": 1,
  "mail_login": "erp@example.com",
  "mail_password": "********"
}
```

**Fix**: Update credentials

#### Firewall Blocking

```bash
sudo ufw status | grep 587
```

**Fix**: `sudo ufw allow 587/tcp`

#### Mailcow Not Running

```bash
cd mail/mailcow-dockerized/
docker compose ps
```

**Fix**: `cd mail/mailcow-dockerized && docker compose up -d`

### 7. High Resource Usage

**Symptoms**:
- Slow response times
- Out of memory errors
- High CPU usage

**Diagnosis**:
```bash
# Identify resource hog
docker stats --no-stream | sort -k3 -h

# Check Prometheus metrics
curl -s http://localhost:9090/api/v1/query?query=container_memory_usage_bytes | jq

# Check system load
top -b -n 1 | head -20
```

**Common causes**:

#### Prometheus Memory

**Increased to 2GB** (already optimized in October 2025)

**Check**:
```bash
docker stats prometheus --no-stream
```

**Fix** (if needed): Adjust limits in compose.yml

#### Too Many Containers

**Fix**: Stop unnecessary services, scale down

#### Disk Full

```bash
df -h
du -sh /var/lib/docker/volumes/*
```

**Fix**:
- Clean Docker: `docker system prune -a --volumes`
- Expand disk
- Adjust retention policies

### 8. Service Not Accessible

**Symptoms**:
- 404 Not Found
- Connection timeout
- 502 Bad Gateway

**Diagnosis**:
```bash
# Check Traefik routing
curl -s http://localhost:8080/api/http/routers | \
  jq '.[] | select(.name | contains("<service>"))'

# Check backend health
curl -s http://localhost:8080/api/http/services | \
  jq '.[] | select(.name | contains("<service>"))'

# Test internal connectivity
docker compose exec traefik ping <service-name>

# Check service logs
docker compose logs <service-name> | tail -50
```

**Common causes**:

#### Traefik Label Missing

**Fix**: Add router labels to compose.yml

#### Backend Not Healthy

**Fix**: Check service logs, restart service

#### Network Issue

**Fix**: Verify service on `proxy` network

### 9. Backup Failed

**Symptoms**:
- Backup script errors
- Backup log shows failures

**Diagnosis**:
```bash
# Check backup log
tail -f /var/log/securenexus-backup.log

# Check disk space
df -h /backup/

# Check permissions
ls -la /backup/securenexus/
```

**Common causes**:

#### Disk Full

```bash
df -h /backup/
```

**Fix**: Clean old backups, expand disk

#### Permissions Error

```bash
sudo chown -R $(whoami):$(whoami) /backup/securenexus/
```

#### Container Not Running

**Fix**: Ensure all services running before backup

### 10. Authentication Issues

**Symptoms**:
- Can't login to Authentik
- SSO not working
- "Invalid credentials" errors

**Diagnosis**:
```bash
# Check Authentik logs
docker compose logs authentik_server | tail -50

# Check PostgreSQL
docker compose exec authentik_db psql -U authentik -d authentik -c "SELECT COUNT(*) FROM authentik_core_user;"

# Check Redis
docker compose exec redis_cache redis-cli PING
```

**Common causes**:

#### Authentik Secret Changed

**NEVER change** `secrets/authentik_secret_key` after initial setup

**Fix**: Restore original secret, restart Authentik

#### Database Connection Failed

```bash
docker compose logs authentik_db
```

**Fix**: Ensure PostgreSQL running and healthy

#### Time Sync Issue

**Symptom**: "Token expired" errors

```bash
# Check system time
timedatectl status
```

**Fix**: Sync time with NTP

**Documentation**: [Authentik Time Sync Fix](../AUTHENTIK_TIME_SYNC_FIX.md)

## Diagnostic Procedures

### Full System Diagnostic

**Run comprehensive diagnostic**:
```bash
./scripts/system-diagnostic.sh

# Or manually:

echo "=== Container Status ==="
docker compose ps

echo "=== Resource Usage ==="
docker stats --no-stream

echo "=== Disk Space ==="
df -h

echo "=== Memory ==="
free -h

echo "=== Network ==="
ip addr

echo "=== Firewall ==="
sudo ufw status numbered

echo "=== DNS ==="
dig @localhost securenexus.net

echo "=== SSL Certificates ==="
docker compose exec traefik cat /acme.json | jq '.le.Certificates | length'

echo "=== Prometheus Targets ==="
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'

echo "=== Recent Errors ==="
docker compose logs --tail=100 | grep -i error
```

### Service-Specific Diagnostics

**ERPNext**:
```bash
# Check sites
docker compose exec erpnext-backend bench --site all list-apps

# Check database connection
docker compose exec erpnext-backend bench --site <site> mariadb

# Check scheduler
docker compose logs erpnext-scheduler | tail -50

# Run doctor
docker compose exec erpnext-backend bench --site <site> doctor
```

**Authentik**:
```bash
# Check worker status
docker compose logs authentik_worker | tail -50

# Check database
docker compose exec authentik_db psql -U authentik -d authentik -c "\dt"

# Check Redis
docker compose exec redis_cache redis-cli INFO
```

**Prometheus**:
```bash
# Check targets
curl -s http://localhost:9090/api/v1/targets

# Check TSDB status
curl -s http://localhost:9090/api/v1/status/tsdb

# Check configuration
curl -s http://localhost:9090/api/v1/status/config
```

## Recovery Procedures

### Container Recovery

```bash
# Restart single container
docker compose restart <service>

# Recreate container
docker compose up -d --force-recreate <service>

# Full restart
docker compose down && docker compose up -d
```

### Database Recovery

**From backup** (see [Disaster Recovery](../DISASTER_RECOVERY.md)):

```bash
# PostgreSQL (Authentik)
docker compose exec -T authentik_db psql -U authentik authentik < /backup/path/authentik.sql

# MariaDB (ERPNext)
docker compose exec -T mariadb mysql -u root -p < /backup/path/mariadb.sql

# etcd (DNS)
docker compose exec etcd etcdctl snapshot restore /backup/path/etcd.db
```

### Configuration Recovery

```bash
# Restore from Git
git checkout HEAD -- config/

# Or from backup
cp -r /backup/securenexus/latest/config/* config/
```

## Preventive Measures

### Monitoring

- **Enable all alerts**: 30+ rules in `monitoring/alert_rules.yml`
- **Review dashboards** regularly: Grafana
- **Check status page**: Uptime Kuma

### Maintenance

- **Weekly**: Review logs for errors/warnings
- **Monthly**: Test backups, rotate secrets
- **Quarterly**: Security audit, performance review

### Documentation

- **Document custom changes**: Update CHANGELOG.md
- **Keep runbooks updated**: Add new issues/solutions
- **Share knowledge**: Team documentation

## Getting Help

### Documentation

- **Search wiki**: Use search bar above
- **Check guides**: Comprehensive guides in docs/
- **Review logs**: Most issues evident in logs

### Community

- **ERPNext Forum**: https://discuss.erpnext.com
- **Traefik Community**: https://community.traefik.io
- **Authentik Discord**: https://discord.gg/authentik

### Support

- **System logs**: `make logs`
- **Diagnostic report**: `./scripts/system-diagnostic.sh`
- **Backup status**: `tail -f /var/log/securenexus-backup.log`

## Quick Reference

### Log Viewing

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f <service-name>

# Last N lines
docker compose logs <service-name> --tail=100

# Since timestamp
docker compose logs <service-name> --since="2025-10-01T00:00:00Z"

# Filter by pattern
docker compose logs | grep -i error
```

### Container Management

```bash
# Start service
docker compose up -d <service>

# Stop service
docker compose stop <service>

# Restart service
docker compose restart <service>

# Remove service
docker compose rm -sf <service>

# Recreate service
docker compose up -d --force-recreate <service>
```

### Quick Fixes

```bash
# Restart all services
docker compose restart

# Clear cache (ERPNext)
docker compose exec erpnext-backend bench --site <site> clear-cache

# Rebuild assets (ERPNext)
docker compose exec erpnext-backend bench build

# Flush Redis
docker compose exec redis_cache redis-cli FLUSHALL

# Reload Traefik config
docker compose restart traefik
```

## Detailed Troubleshooting Guides

- **[VPN Issues](../fix-vpn-connection.md)**: Tailscale connection problems
- **[Authentik Time Sync](../AUTHENTIK_TIME_SYNC_FIX.md)**: Time synchronization fix
- **[Keycloak Frame Options](../KEYCLOAK_FRAME_OPTIONS_FIX.md)**: Frame embedding issues
- **[PC Hosts File Fix](../PC_HOSTS_FILE_FIX.md)**: Local DNS resolution

## System Diagnostic Reports

Pre-generated diagnostic reports:
- [System Diagnostic Report](../SYSTEM_DIAGNOSTIC_REPORT.md)
- [System Diagnostic Report 2025-10-07](../SYSTEM_DIAGNOSTIC_REPORT_2025-10-07.md)
- [System Status Final](../SYSTEM_STATUS_FINAL.md)
