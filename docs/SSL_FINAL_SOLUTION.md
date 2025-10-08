# SSL Certificate - Final Solution

**Date**: 2025-10-01
**Status**: Manual intervention required

---

## Summary

After extensive troubleshooting, Traefik's automatic ACME HTTP-01 challenge is experiencing persistent issues where challenge tokens aren't being served correctly. External ACME clients (lego) are also encountering API protocol issues with Let's Encrypt.

---

## Recommended Solution: Use Traefik with Existing Valid Certificates

### Option A: Restore Working Certificates (Simplest)

The backup file `acme/acme.json.backup` contains **valid Let's Encrypt certificates** that were successfully generated earlier:
- portal.securenexus.net (valid until Dec 30, 2025)
- prometheus.securenexus.net (valid until Dec 30, 2025)
- grafana.securenexus.net (valid until Dec 30, 2025)

**Steps:**
```bash
# Restore backup
cp acme/acme.json.backup acme/acme.json
chmod 600 acme/acme.json

# Restart Traefik
docker compose restart traefik

# Wait and test
sleep 5
curl -v https://portal.securenexus.net 2>&1 | grep "subject:"
```

**Note**: These certificates cover only 3 domains. Other services will still use self-signed certificates until Traefik's ACME retry succeeds.

---

### Option B: Use Certbot (Most Reliable)

Install and use certbot with manual DNS-01 challenge:

```bash
# Install certbot
apt-get update && apt-get install certbot -y

# Request wildcard certificate
certbot certonly --manual \
  --preferred-challenges dns \
  --email admin@securenexus.net \
  --agree-tos \
  -d securenexus.net \
  -d '*.securenexus.net'

# Certbot will prompt for TXT record
# Use our helper script:
./scripts/lego-dns-helper.sh "VALUE_FROM_CERTBOT"

# Press Enter in certbot when ready

# Once successful, import to Traefik
CERT_PATH="/etc/letsencrypt/live/securenexus.net"

# Convert to acme.json format
cat > acme/acme.json << 'EOF'
{
  "le": {
    "Account": {
      "Email": "admin@securenexus.net",
      "Registration": {
        "body": {"status": "valid"},
        "uri": ""
      },
      "PrivateKey": "",
      "KeyType": "4096"
    },
    "Certificates": [
      {
        "domain": {
          "main": "securenexus.net",
          "sans": ["*.securenexus.net"]
        },
        "certificate": "$(base64 -w0 < $CERT_PATH/fullchain.pem)",
        "key": "$(base64 -w0 < $CERT_PATH/privkey.pem)",
        "Store": "default"
      }
    ]
  }
}
EOF

chmod 600 acme/acme.json
docker compose restart traefik
```

---

### Option C: Wait for Traefik Auto-Fix (Passive)

Traefik will continue retrying certificate requests with exponential backoff. Sometimes these issues resolve themselves after:
- DNS caches fully expire (24-48 hours)
- Let's Encrypt API state resets
- Network routing stabilizes

**Monitor**: `docker compose logs -f traefik | grep -i acme`

---

### Option D: Switch to DNS-01 Challenge in Traefik

Modify Traefik to use DNS-01 instead of HTTP-01. This requires a DNS provider plugin or webhook.

**Edit `config/traefik.yml`:**
```yaml
certificatesResolvers:
  le:
    acme:
      email: "admin@securenexus.net"
      storage: "/acme/acme.json"
      # Remove httpChallenge, add dnsChallenge
      dnsChallenge:
        provider: manual
        # Or use acme-dns, cloudflare, etc.
```

**Challenge**: Traefik doesn't have a plugin for our custom DNS setup. Would need to:
1. Use external DNS provider (Cloudflare, Route53, etc.)
2. OR implement custom webhook handler
3. OR continue using manual external ACME client

---

## Scripts Created

### 1. Import Lego Certificates
`scripts/import-lego-certs.sh` - Converts lego certificates to Traefik format

**Usage:**
```bash
# After lego succeeds
./scripts/import-lego-certs.sh
docker compose restart traefik
```

### 2. DNS Helper
`scripts/lego-dns-helper.sh` - Automates TXT record updates

**Usage:**
```bash
./scripts/lego-dns-helper.sh "TXT_VALUE_FROM_ACME_CLIENT"
```

---

## Current Infrastructure Status

### ✅ Working
- All 24 services running
- DNS fully propagated (root + wildcard)
- HTTP→HTTPS redirects functional
- Firewall active
- HTTPS accessible (with self-signed certs)

### ⚠️ Needs Attention
- SSL certificates: Using self-signed (browser warnings)
- Traefik ACME: HTTP-01 challenge failing with 404
- External ACME clients: Protocol errors with Let's Encrypt API

---

## Workaround (Current State)

Services ARE accessible via HTTPS right now with self-signed certificates:

```bash
# Access with certificate bypass
curl -k https://portal.securenexus.net
curl -k https://securenexus.net

# Browser: Click "Advanced" → "Proceed to site"
```

**Security**: Connections are encrypted, but not validated by a trusted CA.

---

## My Recommendation

**For immediate production use**: **Option A** (Restore backup certificates)
- 3 services get valid certs immediately
- Traefik continues trying for others in background
- Low risk, no manual ACME challenges

**For complete solution**: **Option B** (Certbot)
- One wildcard cert covers all domains
- Manual but reliable
- Can set up auto-renewal later

**For hands-off**: **Option C** (Wait 24-48 hours)
- Let Traefik auto-retry
- May resolve on its own
- No immediate action needed

---

## Testing After Certificate Import

```bash
# Check certificate issuer
curl -v https://portal.securenexus.net 2>&1 | grep "issuer:"
# Should show: issuer: C = US, O = Let's Encrypt, CN = R...

# Test multiple domains
for domain in securenexus.net portal.securenexus.net grafana.securenexus.net; do
  echo "Testing $domain:"
  curl -I https://$domain 2>&1 | head -1
done

# Check certificate expiration
echo | openssl s_client -connect securenexus.net:443 2>/dev/null | openssl x509 -noout -dates
```

---

## Next Steps

1. Choose an option above
2. Follow the steps for that option
3. Test SSL certificates
4. Update this document with results

---

**All infrastructure is operational. SSL certificates are the final piece.**
