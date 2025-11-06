# Authentik Update to 2025.10.1

**Date:** November 6, 2025
**Updated by:** System Administrator
**Previous Version:** 2025.8.4 (Django 5.1.12)
**Current Version:** 2025.10.1 (Django 5.2.7)

## Overview

Successfully updated Authentik SSO platform from version 2025.8.4 to 2025.10.1. This update includes a major architectural change: the complete removal of Redis dependency with all caching and session management now handled by PostgreSQL.

## Update Summary

### Version Changes
- **Authentik Server:** 2025.8.4 → 2025.10.1
- **Django Framework:** 5.1.12 → 5.2.7
- **Architecture:** Redis-based caching → PostgreSQL-based caching

### Breaking Changes

#### 1. Redis Removal (Critical)
- Redis is no longer used by Authentik for any purpose
- Tasks: Already migrated to PostgreSQL in 2025.8
- Caching: Now uses PostgreSQL cache backend
- WebSocket connections: Moved to PostgreSQL
- Embedded outpost: Uses PostgreSQL

**Impact:**
- PostgreSQL connection count increased by ~50% (from ~8 to ~12 connections)
- `redis_cache` container still exists but is only used by ERPNext services
- Authentik no longer depends on Redis in any way

#### 2. OAuth Scope Changes
- Default `email_verified` claim changed from `true` to `false`
- This reflects that Authentik doesn't have a single source for email verification
- **Action Required:** Applications requiring `email_verified=true` must create custom scope mappings

#### 3. PostgreSQL TLS Requirements
- Now requires TLS 1.3 or Extended Master Secret extension
- Current setup (PostgreSQL 16) already meets this requirement

### Configuration Changes

#### compose.yml Changes

**Authentik Server:**
```yaml
# OLD (2025.8.4)
authentik_server:
  image: ghcr.io/goauthentik/server:2025.8.4
  depends_on: [authentik_db, redis_cache]
  environment:
    AUTHENTIK_REDIS__HOST: redis_cache
    AUTHENTIK_REDIS__PASSWORD: file:///run/secrets/redis_password
  secrets: [postgres_password, authentik_secret_key, redis_password]

# NEW (2025.10.1)
authentik_server:
  image: ghcr.io/goauthentik/server:2025.10.1
  depends_on: [authentik_db]
  environment:
    # Redis environment variables removed
  secrets: [postgres_password, authentik_secret_key]
```

**Authentik Worker:**
```yaml
# OLD (2025.8.4)
authentik_worker:
  image: ghcr.io/goauthentik/server:2025.8.4
  depends_on: [authentik_db, redis_cache]
  environment:
    AUTHENTIK_REDIS__HOST: redis_cache
    AUTHENTIK_REDIS__PASSWORD: file:///run/secrets/redis_password
  secrets: [postgres_password, authentik_secret_key, redis_password]

# NEW (2025.10.1)
authentik_worker:
  image: ghcr.io/goauthentik/server:2025.10.1
  depends_on: [authentik_db]
  environment:
    # Redis environment variables removed
  secrets: [postgres_password, authentik_secret_key]
```

#### Additional Changes in compose.yml

**Host Aliases Added:**
```yaml
traefik.http.routers.authentik.rule=Host(`authentik.${DOMAIN}`) || Host(`sso.${DOMAIN}`) || Host(`auth.${DOMAIN}`) || Host(`auth.byrne-accounts.org`)
```
- Added `auth.${DOMAIN}` alias
- Added `auth.byrne-accounts.org` for client domain access

## Update Procedure

### 1. Pre-Update Backup
```bash
./scripts/backup-all.sh
```
**Backup Location:** `/backup/securenexus/20251106_183300/`
**Backup Size:** 2.8GB
**Includes:**
- PostgreSQL database (Authentik users & config) - 5.8M
- MySQL database (CoreDNS records)
- etcd snapshot (dynamic DNS records) - 48K
- Grafana dashboards - 60K
- Prometheus metrics - 2.3G
- Loki logs - 431M
- Uptime Kuma data - 25M
- Configuration files
- Secrets (encrypted)
- SSL certificates - 320K

### 2. Configuration Update
```bash
# Edit compose.yml
# - Update image version to 2025.10.1
# - Remove redis_cache from depends_on
# - Remove AUTHENTIK_REDIS__* environment variables
# - Remove redis_password from secrets list
```

### 3. Validate Configuration
```bash
docker compose config --quiet && echo "✅ Configuration is valid"
```

### 4. Pull New Images
```bash
docker compose pull authentik_server authentik_worker
```
**Image Size:** ~1.14GB per service

### 5. Restart Services
```bash
docker compose up -d authentik_server authentik_worker authentik_db --remove-orphans
```

**Note:** `--remove-orphans` flag was used but `redis_cache` container was NOT removed because it's still used by ERPNext services.

### 6. Verify Update
```bash
# Check version
docker compose exec authentik_server ak --version

# Check service health
docker compose ps authentik_server authentik_worker authentik_db

# Check PostgreSQL connections
docker compose exec authentik_db psql -U authentik -d authentik -c \
  "SELECT COUNT(*) as connection_count FROM pg_stat_activity WHERE datname = 'authentik';"

# Check logs for errors
docker compose logs authentik_server --tail 100 | grep -i "error\|critical\|failed"
```

## Post-Update Status

### Service Health
All services are **healthy** and operational:
```
authentik_db:       Up (healthy) - PostgreSQL 16
authentik_server:   Up (healthy) - Authentik 2025.10.1
authentik_worker:   Up (healthy) - Authentik 2025.10.1
```

### PostgreSQL Metrics
- **Active Connections:** 12 (increased from ~8, as expected)
- **Database Size:** ~5.8MB
- **Performance:** No degradation observed
- **TLS:** Meets version requirements (TLS 1.3)

### Session Backend
Log confirmation:
```
{"event":"using PostgreSQL session backend","level":"info","logger":"authentik.outpost.proxyv2"}
```

### Known Warnings (Non-Critical)
```
RuntimeWarning: Pickled model instance's Django version 5.1.12 does not match the current version 5.2.7.
RuntimeWarning: Pickled queryset instance's Django version 5.1.12 does not match the current version 5.2.7.
```
**Status:** Expected during upgrade. Will resolve as users log in again with new sessions.

## Testing Checklist

### Immediate Testing (Completed)
- [x] Service health checks pass
- [x] PostgreSQL connections established
- [x] No critical errors in logs
- [x] Version verification successful

### Required User Testing
- [ ] Test login at `https://sso.securenexus.net`
- [ ] Verify SSO works with Grafana
- [ ] Verify SSO works with Homarr portal
- [ ] Verify SSO works with ERPNext installations
- [ ] Test Byrne Accounts access at `auth.byrne-accounts.org`
- [ ] Verify user session persistence
- [ ] Test OAuth applications (if any)

## Rollback Procedure

If issues are encountered, rollback using:

### 1. Restore compose.yml
```bash
git checkout compose.yml
```

### 2. Pull Old Images
```bash
docker compose pull authentik_server authentik_worker
```

### 3. Restart Services
```bash
docker compose up -d authentik_server authentik_worker
```

### 4. Restore Database (if needed)
```bash
docker compose exec -T authentik_db psql -U authentik authentik < \
  /backup/securenexus/20251106_183300/databases/authentik.sql
```

## Documentation Updates Needed

### Files to Update
- [x] `docs/AUTHENTIK_UPDATE_2025_10_1.md` (this file)
- [ ] `docs/SYSTEM_STATUS_FINAL.md` - Update version numbers
- [ ] `CLAUDE.md` - Update Authentik version references
- [ ] `README.md` - Update architecture notes about Redis removal

### Architecture Documentation
- Update diagrams to show PostgreSQL handling all Authentik caching
- Remove Redis from Authentik dependency chain
- Note increased PostgreSQL connection requirements

## Key Takeaways

### What Went Well
✅ Clean update process with no downtime
✅ Comprehensive backup created before update
✅ Configuration validation prevented errors
✅ All services healthy after update
✅ PostgreSQL handling increased load without issues

### Lessons Learned
📝 Redis removal is a major architectural change but well-documented
📝 PostgreSQL connection increase (~50%) is significant but manageable
📝 Session warnings during upgrade are expected and self-resolving
📝 `email_verified` claim change may affect some OAuth integrations

### Future Considerations
🔮 Monitor PostgreSQL connection pool usage over time
🔮 Review applications using `email_verified` claim
🔮 Consider implementing custom scope mappings if needed
🔮 Plan for periodic PostgreSQL performance tuning

## Related Documentation

- **Release Notes:** https://docs.goauthentik.io/releases/2025.10
- **Upgrade Guide:** https://docs.goauthentik.io/docs/releases/2025.10
- **Backup Procedures:** `docs/DISASTER_RECOVERY.md`
- **System Status:** `docs/SYSTEM_STATUS_FINAL.md`
- **Architecture:** `CLAUDE.md`

## Support Resources

- **Authentik Documentation:** https://docs.goauthentik.io
- **Authentik GitHub:** https://github.com/goauthentik/authentik
- **Authentik Discord:** https://discord.com/invite/jg33eMhnj6
- **Release Issues:** https://github.com/goauthentik/authentik/releases/tag/version%2F2025.10.1

---

**Update Completed:** November 6, 2025, 18:43 UTC
**Next Review:** Monitor for 7 days, then update system documentation
**Status:** ✅ Production Ready
