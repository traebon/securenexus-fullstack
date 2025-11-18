# Traefik to Caddy Migration Guide

**Purpose**: Replace Traefik with Caddy for Docker 29.0.0 compatibility
**Timeline**: 4-6 hours
**Downtime**: ~15 minutes during cutover

## Pre-Migration Checklist

- [ ] Backup current Traefik configuration
- [ ] Verify all services are running
- [ ] Test current routing functionality
- [ ] Confirm DNS records are correct

## Step 1: Preparation

### 1.1 Backup Current Configuration
```bash
# Backup Traefik configs
cp -r config/ config-backup-$(date +%Y%m%d)
cp compose.yml compose.yml.backup-$(date +%Y%m%d)

# Backup SSL certificates
cp -r acme/ acme-backup-$(date +%Y%m%d)
```

### 1.2 Add Caddy Volumes to compose.yml
```bash
# Add to volumes section in compose.yml
echo "  caddy-data:" >> compose.yml
echo "  caddy-config:" >> compose.yml
```

## Step 2: Update Compose Configuration

### 2.1 Replace Traefik Service
```bash
# Comment out existing Traefik service
sed -i '/^  traefik:/,/^  [a-zA-Z]/ s/^/#/' compose.yml

# Add Caddy service definition
cat config/caddy/caddy-compose.yml >> compose.yml
```

### 2.2 Remove Traefik Labels (Optional for now)
```bash
# Keep existing labels during transition for easier rollback
# We'll remove them after successful testing
```

## Step 3: Deploy Caddy

### 3.1 Start Caddy Service
```bash
# Stop Traefik first
docker compose stop traefik

# Start Caddy
docker compose up -d caddy

# Check Caddy status
docker compose logs caddy -f
```

### 3.2 Verify SSL Certificate Generation
```bash
# Caddy will automatically request Let's Encrypt certificates
# Watch logs for certificate generation
docker compose logs caddy | grep -i "certificate"
```

## Step 4: Testing

### 4.1 Test Core Services
```bash
# Test main domain
curl -I https://securenexus.net

# Test SSO
curl -I https://sso.securenexus.net

# Test portal
curl -I https://portal.securenexus.net

# Test client sites
curl -I https://byrne-accounts.org
curl -I https://erp.byrne-accounts.org
```

### 4.2 Test VPN-Only Services (from Tailscale network)
```bash
# These should only work from VPN
curl -I https://grafana.securenexus.net
curl -I https://prometheus.securenexus.net
```

### 4.3 Test SSL Certificates
```bash
# Check certificate details
echo | openssl s_client -connect sso.securenexus.net:443 -servername sso.securenexus.net | openssl x509 -noout -text
```

## Step 5: Security Configuration

### 5.1 Remove Homarr Port Exposure
```bash
# Remove direct port access to Homarr
sed -i '/7575.*7575/d' compose.yml
docker compose up -d homarr
```

### 5.2 Configure Authentik Integration (Optional)
For full SSO integration, you'll need to:
1. Set up Authentik Forward Auth outpost for Caddy
2. Update sso_auth.caddy snippet with proper configuration
3. Uncomment SSO imports in services that need protection

## Step 6: Cleanup (After Successful Testing)

### 6.1 Remove Traefik Labels
```bash
# Remove Traefik labels from all services (saves space and reduces confusion)
sed -i '/traefik\./d' compose.yml
```

### 6.2 Remove Traefik Service
```bash
# Remove Traefik service definition
sed -i '/^#  traefik:/,/^#  [a-zA-Z]/ d' compose.yml
```

### 6.3 Cleanup Volumes
```bash
# Remove unused Traefik volumes (keep config for reference)
docker volume rm securenexus-fullstack_traefik-data 2>/dev/null || true
```

## Rollback Plan (If Issues Occur)

### Emergency Rollback
```bash
# Stop Caddy
docker compose stop caddy

# Restore Traefik service
cp compose.yml.backup-$(date +%Y%m%d) compose.yml

# Start Traefik
docker compose up -d traefik

# Verify services
curl -I -H "Host: securenexus.net" http://localhost
```

## Post-Migration Tasks

- [ ] Update monitoring to check Caddy instead of Traefik
- [ ] Update documentation with new architecture
- [ ] Set up log monitoring for Caddy
- [ ] Configure automatic certificate renewal monitoring
- [ ] Update backup scripts to include Caddy data

## Troubleshooting

### Common Issues

1. **Certificate Generation Fails**
   - Check DNS records point to correct IP
   - Verify ports 80/443 are accessible
   - Check Caddy logs: `docker compose logs caddy`

2. **Service Not Accessible**
   - Verify service is running: `docker compose ps`
   - Check Caddyfile syntax: `docker compose exec caddy caddy validate`
   - Review Caddy logs for errors

3. **VPN Access Not Working**
   - Verify Tailscale is connected
   - Check IP allowlist in vpn_only.caddy snippet
   - Confirm Tailscale subnet (100.64.0.0/10)

### Debug Commands
```bash
# Test Caddyfile syntax
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# View active configuration
docker compose exec caddy caddy list-modules

# Check certificate status
docker compose exec caddy caddy list-modules --versions

# Live config reload (after changes)
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## Security Notes

- Caddy automatically generates and renews SSL certificates
- Security headers are applied to all HTTPS endpoints
- VPN-only services are protected by IP allowlist
- Automatic HTTP to HTTPS redirects are enabled
- HSTS is enforced with 2-year max-age

## Performance Notes

- Caddy uses automatic HTTPS with HTTP/3 support
- Built-in compression and caching
- Efficient reverse proxy with connection pooling
- Lower resource usage than Traefik for basic use cases