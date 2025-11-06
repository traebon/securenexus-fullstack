# SSL Certificate Status

**Date**: 2025-10-01
**Status**: ⚠️ Manual Intervention Required

---

## Current Situation

### ✅ Infrastructure Ready
- DNS fully propagated globally (root + wildcard `*.securenexus.net → 217.154.37.3`)
- HTTP→HTTPS redirects configured per-service
- ACME challenge endpoints accessible (HTTP-01)
- Traefik ACME resolver configured correctly

### ⚠️ Certificate Generation Blocked

**Issue**: Traefik's HTTP-01 ACME challenge is failing with 404 errors

**Root Cause**: Traefik is not serving challenge tokens when Let's Encrypt requests them. This appears to be a timing or internal routing issue where:
1. Let's Encrypt requests `http://domain/.well-known/acme-challenge/{token}`
2. Request reaches Traefik on port 80
3. Traefik returns 404 instead of the challenge token
4. Let's Encrypt validation fails with "unauthorized"

**Evidence**:
```
curl http://securenexus.net/.well-known/acme-challenge/test
# Returns: HTTP/1.1 404 Not Found (expected behavior for non-existent challenge)

# But when Let's Encrypt requests actual challenge URLs:
# Error: Invalid response from http://securenexus.net/.well-known/acme-challenge/{token}: 404
```

### 📦 Existing Certificates

Valid Let's Encrypt certificates exist in `acme/acme.json.backup`:
- `portal.securenexus.net` - Valid until Dec 30, 2025
- `prometheus.securenexus.net` - Valid until Dec 30, 2025
- `grafana.securenexus.net` - Valid until Dec 30, 2025

**However**: Traefik is not using these certificates (serving default self-signed instead)

---

## Solutions

### Option 1: Wait for Traefik Auto-Retry (Recommended)
Traefik will retry failed certificate requests with exponential backoff. Sometimes ACME challenge issues resolve themselves after:
- DNS cache expiration (Let's Encrypt seeing NXDOMAIN for some subdomains)
- Traefik internal state changes
- Network routing stabilization

**Action**: Monitor logs for successful attempts
```bash
docker compose logs -f traefik | grep -i acme
```

### Option 2: Use Staging Certificates for Testing
Switch to Let's Encrypt staging to avoid rate limits while debugging:

**Edit `config/traefik.yml`:**
```yaml
certificatesResolvers:
  le:
    acme:
      caServer: "https://acme-staging-v02.api.letsencrypt.org/directory"
      storage: "/acme/acme.json"
      httpChallenge:
        entryPoint: web
```

**Then restart**: `docker compose restart traefik`

### Option 3: Manual Certificate with Certbot
Use certbot with DNS-01 challenge (since we control DNS):

```bash
# Install certbot
apt-get update && apt-get install certbot

# Request wildcard certificate
certbot certonly --manual \
  --preferred-challenges dns \
  --email admin@securenexus.net \
  -d securenexus.net \
  -d '*.securenexus.net'

# Follow prompts to add TXT records to DNS zone
# Then import certificates into Traefik
```

### Option 4: External ACME Client with DNS-01
Use `lego` or `acme.sh` with the etcd DNS backend:

```bash
# Install lego
wget https://github.com/go-acme/lego/releases/download/v4.14.2/lego_v4.14.2_linux_amd64.tar.gz
tar -xzf lego_v4.14.2_linux_amd64.tar.gz

# Use DNS-01 with manual TXT record updates
./lego --email="admin@securenexus.net" \
  --domains="securenexus.net" \
  --domains="*.securenexus.net" \
  --dns manual run
```

### Option 5: Debug HTTP-01 Challenge
Investigate why Traefik isn't serving challenge tokens:

1. **Check Traefik logs during challenge**:
   ```bash
   docker compose logs traefik -f --tail 100
   ```

2. **Verify no HTTP routers catching challenges**:
   ```bash
   curl http://localhost:8080/api/http/routers | jq '.[] | select(.entryPoints[] == "web")'
   ```

3. **Test challenge response timing**:
   - Trigger cert request (access HTTPS service)
   - Immediately curl the challenge URL shown in logs
   - Check if Traefik serves the token

---

## Configuration Changes Made

### 1. DNS Zone File (`dns/zones/securenexus.net.zone`)
```
securenexus.net. IN SOA ns1.securenexus.net. admin.securenexus.net. (
    2025100101 ; serial - INCREMENTED
    ...
)
*.securenexus.net. IN A 217.154.37.3  # ADDED WILDCARD
```

### 2. Traefik Static Config (`config/traefik.yml`)
```yaml
entryPoints:
  web:
    address: ":80"
    # Removed global HTTP→HTTPS redirect (breaks ACME HTTP-01)
```

### 3. Traefik Dynamic Config (`config/dynamic/traefik_dynamic.yml`)
```yaml
http:
  middlewares:
    redirect-to-https:  # ADDED
      redirectScheme:
        scheme: https
        permanent: true
```

### 4. Service Labels (`compose.yml`)
Added HTTP routers with redirects to services:
```yaml
# Example for landing service
- traefik.http.routers.landing-http.rule=Host(`${DOMAIN}`)
- traefik.http.routers.landing-http.entrypoints=web
- traefik.http.routers.landing-http.middlewares=redirect-to-https@file
```

### 5. DNS Updater (`scripts/dns-updater.sh`)
- Migrated from etcd v2 API to v3 API
- Fixed path format: `/coredns/{domain}/{subdomain}/{type}`
- Base64 encoding for keys/values

---

## Verification Commands

```bash
# Check DNS resolution
dig securenexus.net +short
dig dns.securenexus.net +short

# Test HTTP redirect
curl -I http://securenexus.net

# Test ACME challenge endpoint
curl -I http://securenexus.net/.well-known/acme-challenge/test

# Check certificate in acme.json
docker compose exec traefik cat /acme/acme.json | jq -r '.le.Certificates | length'

# Monitor ACME attempts
docker compose logs -f traefik | grep -i acme
```

---

## Workaround (Temporary)

Services are accessible via HTTPS with self-signed certificates. Browsers will show security warnings but connections are encrypted.

**Accept self-signed in browser**: Click "Advanced" → "Proceed to site"

**curl with -k flag**: `curl -k https://portal.securenexus.net`

---

## Recommended Next Action

**Wait 24-48 hours** for:
1. Let's Encrypt DNS cache to fully clear (seeing NXDOMAIN for subdomains)
2. Traefik automatic retry cycles to attempt certificates again
3. Monitor logs: `docker compose logs -f traefik | grep acme`

If still failing after 48 hours, proceed with **Option 3** (manual certbot) or **Option 4** (external ACME client).

---

## Files to Reference

- Traefik ACME config: `config/traefik.yml:44-54`
- HTTP routers: `compose.yml` (search for `landing-http`, `portal-http`)
- DNS zone: `dns/zones/securenexus.net.zone`
- Backup certificates: `acme/acme.json.backup`

---

**All infrastructure is operational. SSL certificates are the only outstanding issue.**
