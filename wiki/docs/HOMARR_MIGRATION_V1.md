# Homarr v1.0 Migration Guide

**Status**: ✅ Migration Complete - Fresh Installation
**Date**: October 11, 2025
**Original Version**: Homarr 0.x (ghcr.io/ajnart/homarr:latest) - Removed
**Current Version**: Homarr 1.0 (ghcr.io/homarr-labs/homarr:latest)

## Overview

Homarr 1.0 is a complete rewrite that is NOT backwards compatible with 0.x versions. This guide documents the parallel installation approach, allowing you to test v1.0 while keeping v0.x running.

## Current Status

### Homarr v1.0 (Production)
- **Service**: `homarr`
- **Image**: `ghcr.io/homarr-labs/homarr:latest`
- **URL**: `http://137.74.40.208:7575` (direct access)
- **Intended URL**: `https://portal.${DOMAIN}` (Traefik routing - see Known Issues)
- **Volume**: `homarr-data:/appdata`
- **Port**: 7575 (exposed for direct access)
- **Status**: ✅ Running successfully - Fresh installation
- **Encryption Key**: Stored in `secrets/homarr_encryption_key.txt`
- **Data**: User started from scratch (no migration needed)

## Key Breaking Changes

### Infrastructure
1. **New Image Repository**: `ghcr.io/ajnart/homarr` → `ghcr.io/homarr-labs/homarr`
2. **Data Directory**: `/data` → `/appdata` (completely restructured)
3. **Required Environment Variable**: `SECRET_ENCRYPTION_KEY` (64-char hex string)

### Configuration Changes
1. **Docker Integration**: `DOCKER_HOST` → `DOCKER_HOSTNAMES` and `DOCKER_PORTS` (configured via UI in v1.0)
2. **Database**: New schema incompatible with 0.x
3. **Storage**: No more JSON files - all data in database

### Features
- Internal Nginx proxy for multi-server architecture
- WebSocket server on port 3001
- Task server on port 3002
- Built-in Redis server (embedded)
- SQLite database for persistent storage

## Accessing Homarr v1.0

**Direct Access URL**: `http://137.74.40.208:7575`

**Firewall**: Port 7575 should be allowed if needed for external access

**Traefik Access**: `https://portal.securenexus.net` (see Known Issues below)

## Known Issues

### Traefik Routing Not Working
**Issue**: Traefik does not register the `portal` router for the new Homarr v1.0 container, despite correct labels and network configuration.

**Symptoms**:
- Direct port access works: `http://137.74.40.208:7575` ✅
- Traefik routing returns 404: `https://portal.securenexus.net` ❌
- Container has correct labels and is on `securenexus-fullstack_proxy` network
- Traefik can see the container via docker-proxy API
- No errors in Traefik logs

**Investigation**:
- Labels verified correct on container: ✅
- Container IP: 172.18.0.31 (same as before)
- Network: securenexus-fullstack_proxy ✅
- Docker provider can query container via docker-proxy ✅
- Previous `portal@docker` router worked for old homarr-v1 container
- Router not re-registered after container recreation

**Workaround**: Use direct port access for now: `http://137.74.40.208:7575`

**Potential Solutions to Try**:
1. Remove and recreate Traefik container (not just restart)
2. Check for conflicting router names in other services
3. Enable Traefik DEBUG logging to see provider events
4. Manually trigger Docker provider refresh (if possible)

## Migration Summary

### What Was Done (October 11, 2025)

1. ✅ **Old Homarr 0.x Removed**
   - Container stopped and removed
   - Volume `securenexus-fullstack_homarr-data` deleted (old 0.x data)
   - User confirmed starting from scratch (no data migration needed)

2. ✅ **Homarr v1.0 Installed as Primary Service**
   - Service renamed from `homarr-v1` to `homarr`
   - Container name: `homarr`
   - Port changed from 7576 to standard 7575
   - Volume migrated: `homarr-v1-data` → `homarr-data`
   - Traefik labels updated to use `portal.${DOMAIN}`

3. ✅ **Configuration Updates**
   - `compose.yml`: Service definition updated
   - Traefik labels: Changed from `portal-v1` to `portal` routers
   - BASE_URL: Updated to `https://portal.${DOMAIN}`
   - Encryption key: Stored in `secrets/homarr_encryption_key.txt`

4. ⚠️ **Known Issue**: Traefik routing not working (see above)
   - Workaround: Direct access via `http://137.74.40.208:7575`

## Migration Process (Historical Reference)

### Phase 1: Export from Homarr 0.x

**Note**: User opted for fresh installation, so this phase was skipped.

**IMPORTANT**: You must be on Homarr 0.15.10+ to export data.

1. Access your current Homarr instance: `https://portal.${DOMAIN}`
2. Navigate to: **Management > Tools > Migrate to 1.0**
3. Select which items to export:
   - Dashboards and layouts
   - Widgets and integrations
   - Users and permissions
   - Settings and preferences
4. Download the export ZIP file
5. **Save the secret key displayed** - you'll need it to import encrypted data (passwords, API keys, etc.)

### Phase 2: Import to Homarr v1.0

1. Access the new Homarr v1.0 instance: `https://portal-v1.${DOMAIN}`
2. Complete initial setup wizard
3. Navigate to import section
4. Upload the exported ZIP file
5. Enter the secret key from Phase 1
6. Review and confirm import

### Phase 3: Testing

Test all functionality in v1.0:
- [ ] Dashboard layout matches expectations
- [ ] All widgets display correctly
- [ ] Service integrations work (Docker, *arr apps, etc.)
- [ ] User authentication works
- [ ] Permissions are correct
- [ ] Custom settings applied

### Phase 4: Cutover (When Ready)

**Option A: Switch DNS routing (Recommended)**

Update Traefik labels to point `portal.${DOMAIN}` to v1.0:

```yaml
# In compose.yml, update homarr-v1 labels:
- traefik.http.routers.portal-v1.rule=Host(`portal.${DOMAIN}`)  # Change from portal-v1
- traefik.http.routers.portal-v1-http.rule=Host(`portal.${DOMAIN}`)  # Change from portal-v1

# Update old homarr to use different domain (or disable):
- traefik.http.routers.portal.rule=Host(`portal-old.${DOMAIN}`)  # Backup access
```

**Option B: Rename services**

1. Stop both containers: `docker compose stop homarr homarr-v1`
2. Rename in compose.yml: `homarr` → `homarr-old`, `homarr-v1` → `homarr`
3. Update all labels and references
4. Restart: `docker compose up -d homarr`

**Option C: Remove old version**

Once confident in v1.0:
```bash
# Stop old homarr
docker compose stop homarr

# Remove from compose.yml
# Delete old volume if desired
docker volume rm securenexus-fullstack_homarr-data
```

## Configuration Details

### Homarr v1.0 Service Configuration

```yaml
homarr-v1:
  image: ghcr.io/homarr-labs/homarr:latest
  container_name: homarr-v1
  restart: unless-stopped
  networks: [proxy]
  environment:
    - BASE_URL=https://portal-v1.${DOMAIN}
    - PORT=7576
    - SECRET_ENCRYPTION_KEY=<64-char-hex-key>
  volumes:
    - homarr-v1-data:/appdata
    - /var/run/docker.sock:/var/run/docker.sock:ro
  labels:
    - traefik.enable=true
    - traefik.http.routers.portal-v1.rule=Host(`portal-v1.${DOMAIN}`)
    - traefik.http.routers.portal-v1.entrypoints=websecure
    - traefik.http.routers.portal-v1.tls.certresolver=le
    - traefik.http.routers.portal-v1.middlewares=secure-headers@file
    - traefik.http.services.portal-v1.loadbalancer.server.port=7576
  profiles: ["portal"]
```

### Encryption Key Management

**Location**: `secrets/homarr_encryption_key.txt`

**Value**: `868dbce3483128d67f1da74cde540b5205786d32815b4ed38d217b73d1495c0c`

**Generation**: `openssl rand -hex 32`

**Security Note**: This key encrypts sensitive data like passwords and API keys. Do NOT change it after initial setup.

## Docker Integration

Homarr v1.0 can access Docker via the mounted socket (`/var/run/docker.sock`). Docker integration is configured through the UI:

1. Go to Settings > Integrations > Docker
2. Add Docker host (default: unix:///var/run/docker.sock)
3. Test connection
4. Enable container monitoring

**Note**: Unlike v0.x, v1.0 doesn't use `DOCKER_HOSTNAMES` and `DOCKER_PORTS` environment variables.

## Troubleshooting

### Issue: "Invalid environment variables" error

**Cause**: Missing `SECRET_ENCRYPTION_KEY`

**Solution**: Ensure environment variable is set with 64-character hex string

### Issue: Container restarts continuously

**Check**:
1. Logs: `docker compose logs homarr-v1`
2. Encryption key is valid (64 hex chars)
3. Volume mount is correct (`/appdata` not `/data`)

### Issue: Cannot access portal-v1 URL

**Check**:
1. Container is running: `docker compose ps homarr-v1`
2. Traefik routing: `curl -H "Host: portal-v1.${DOMAIN}" http://localhost/`
3. SSL certificate generated: Check Traefik logs
4. DNS resolves to server IP

### Issue: Data export not available in old Homarr

**Solution**: Update to Homarr 0.15.10+ first:

```yaml
# Temporarily update old homarr image
image: ghcr.io/ajnart/homarr:0.15.10
```

Restart, export data, then proceed with v1.0 migration.

## Rollback Plan

If issues arise during migration:

1. **Keep old Homarr running** - Don't remove it until v1.0 is fully validated
2. **Backup v0.x data**:
   ```bash
   docker run --rm -v securenexus-fullstack_homarr-data:/data \
     -v $(pwd)/backups:/backup alpine \
     tar czf /backup/homarr-v0-backup-$(date +%Y%m%d).tar.gz /data
   ```
3. **Revert Traefik labels** to point `portal.${DOMAIN}` back to old homarr
4. **Stop v1.0**: `docker compose stop homarr-v1`

## Post-Migration Cleanup

After successful cutover and testing period (1-2 weeks):

1. Remove old Homarr service from `compose.yml`
2. Remove old volume:
   ```bash
   docker volume rm securenexus-fullstack_homarr-data
   ```
3. Update documentation to reflect v1.0 as primary
4. Remove `homarr-v1` naming, rename to `homarr`

## Resources

- [Official Migration Guide](https://homarr.dev/blog/2025/01/19/migration-guide-1.0/)
- [Homarr 1.0 Announcement](https://homarr.dev/blog/2024/09/23/version-1.0/)
- [Docker Installation Docs](https://homarr.dev/docs/getting-started/installation/docker/)
- [Environment Variables](https://homarr.dev/docs/advanced/environment-variables/)

## Support

For issues specific to this deployment:
- Review logs: `docker compose logs -f homarr-v1`
- Check system status: `docker compose ps`
- Traefik dashboard: `https://traefik.${DOMAIN}` (VPN only)

For Homarr v1.0 issues:
- GitHub Issues: https://github.com/homarr-labs/homarr/issues
- Discord: https://discord.gg/aCsmEV5RgA

---

**Next Steps**:
1. Access old Homarr and export data via Management > Tools > Migrate to 1.0
2. Save the export ZIP file and secret key
3. Access new Homarr v1.0 at `https://portal-v1.${DOMAIN}`
4. Import the data and test thoroughly
5. Plan cutover when confident in v1.0 functionality
