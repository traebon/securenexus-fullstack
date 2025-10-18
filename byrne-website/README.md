# Byrne Accounting Website + ERP + POS System

Complete accounting firm solution with professional website, ERPNext ERP system, and AwesomePOS point-of-sale integration.

## Quick Start

### 1. Deploy Everything

```bash
# Generate secrets
make secrets

# Deploy Byrne Accounting stack
make up-byrne
```

### 2. Wait for Initialization (5-10 minutes)

```bash
# Monitor ERPNext startup
docker compose logs -f erpnext-backend
```

### 3. Install AwesomePOS

```bash
# Once ERPNext is ready
make install-awesomepos
```

### 4. Access Systems

- **Website**: https://byrneaccounting.net
- **Client Portal**: https://byrneaccounting.net/portal
- **ERP System**: https://erp.byrneaccounting.net
- **POS System**: https://pos.byrneaccounting.net

**Default ERPNext Login**:
- Username: `Administrator`
- Password: `cat secrets/erpnext_admin_password.txt`

## Architecture

### Services (8 containers)

1. **byrne-website** - Marketing website (Nginx)
2. **erpnext-backend** - ERPNext application server
3. **erpnext-worker** - Background job processor
4. **erpnext-scheduler** - Scheduled task runner
5. **erpnext-db** - PostgreSQL 16 database
6. **erpnext-redis-cache** - Redis cache (512MB)
7. **erpnext-redis-queue** - Redis job queue
8. **AwesomePOS** - POS plugin (runs in erpnext-backend)

### Security

- ✅ **Public Website**: CrowdSec protection + secure headers
- ✅ **ERP/POS**: Authentik SSO authentication required
- ✅ **SSL**: Automatic Let's Encrypt certificates via Traefik
- ✅ **Network**: Docker network isolation
- ✅ **Secrets**: Docker secrets management
- ✅ **Backups**: Automated daily backups via existing system

## Configuration

### DNS Setup

**Internal DNS** (CoreDNS):
- Configured in: `dns/zones/byrneaccounting.net.zone`
- Automatic A records for all subdomains

**External DNS** (At your domain registrar):
```
byrneaccounting.net      A    137.74.40.208
*.byrneaccounting.net    A    137.74.40.208
```

### Authentik SSO Integration

See detailed guide: `docs/BYRNE_ACCOUNTING_SETUP.md#authentik-sso-integration`

**Summary**:
1. Create OAuth2 provider in Authentik
2. Create application for ERPNext
3. Configure Social Login in ERPNext
4. Test SSO flow

## Maintenance

### View Logs

```bash
# All Byrne services
docker compose logs -f | grep -E "byrne|erpnext"

# Specific service
docker compose logs -f erpnext-backend
docker compose logs -f byrne-website
```

### Restart Services

```bash
# Restart ERPNext
docker compose restart erpnext-backend erpnext-worker erpnext-scheduler

# Restart website
docker compose restart byrne-website
```

### Backup

```bash
# Automated daily backups (already configured)
sudo ./scripts/backup-rotation.sh

# Manual database backup
docker compose exec -T erpnext-db pg_dump -U erpnext erpnext > erpnext_backup_$(date +%Y%m%d).sql
```

### Updates

```bash
# Update ERPNext
docker compose pull frappe/erpnext
docker compose up -d erpnext-backend erpnext-worker erpnext-scheduler

# Update website
make build-byrne-website
docker compose up -d byrne-website

# Update AwesomePOS
docker exec -it erpnext-backend bash -c "
  cd /home/frappe/frappe-bench &&
  bench update --app awesome_pos &&
  bench build --apps awesome_pos
"
```

## Troubleshooting

### ERPNext Won't Start

```bash
# Check database is ready
docker compose ps erpnext-db

# Check logs for errors
docker compose logs erpnext-backend | tail -50

# Restart with clean state
docker compose restart erpnext-db erpnext-redis-cache erpnext-redis-queue
sleep 10
docker compose restart erpnext-backend
```

### Website Not Accessible

```bash
# Verify container is running
docker compose ps byrne-website

# Check Traefik routing
curl -I https://byrneaccounting.net

# Rebuild if needed
make build-byrne-website
docker compose up -d byrne-website
```

### AwesomePOS Not Working

```bash
# Verify installation
docker compose exec erpnext-backend bench --site erp.byrneaccounting.net list-apps
# Should show: frappe, erpnext, awesome_pos

# Reinstall if needed
make install-awesomepos
```

## Development

### Website Structure

```
byrne-website/
├── index.html           # Main landing page
├── portal.html          # Client portal access page
├── assets/
│   ├── css/style.css   # Styling
│   └── js/main.js      # JavaScript
├── nginx.conf          # Nginx configuration
├── Dockerfile          # Container build
└── README.md           # This file
```

### Customization

**Edit Website Content**:
```bash
# Edit HTML files
vim byrne-website/index.html
vim byrne-website/portal.html

# Edit styles
vim byrne-website/assets/css/style.css

# Rebuild and deploy
make build-byrne-website
docker compose up -d byrne-website
```

**Customize ERPNext**:
- Use ERPNext's built-in customization tools
- Go to: **Customize** → **Customize Form** / **Custom Field**

**Configure POS**:
- Go to: **Retail** → **POS Profile**
- Customize payment methods, warehouses, pricing

## Resources

- **Full Setup Guide**: `docs/BYRNE_ACCOUNTING_SETUP.md`
- **ERPNext Docs**: https://docs.erpnext.com/
- **AwesomePOS**: https://github.com/awesome-erp/awesome_pos
- **Traefik Config**: `config/dynamic/traefik_dynamic.yml`
- **Compose Config**: `compose.yml` (lines 714-912)

## Support

For issues or questions:
1. Check logs: `docker compose logs -f [service]`
2. Review setup guide: `docs/BYRNE_ACCOUNTING_SETUP.md`
3. Check system status: `make ps`
4. Verify DNS: `dig byrneaccounting.net`

## Security Notes

- Change default ERPNext admin password after first login
- Configure MFA in Authentik for all users
- Review Authentik access policies regularly
- Monitor CrowdSec alerts: `docker compose logs crowdsec`
- Keep ERPNext updated with security patches

---

**Status**: Production Ready ✅

All services integrated with SecureNexus infrastructure security standards.
