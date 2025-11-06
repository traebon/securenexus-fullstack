# Certbot SSL Certificate Generation Guide

Follow these steps to generate valid Let's Encrypt certificates using certbot.

---

## Step 1: Install Certbot

```bash
sudo apt-get update
sudo apt-get install certbot -y
```

---

## Step 2: Request Wildcard Certificate

Run certbot with manual DNS challenge:

```bash
sudo certbot certonly --manual \
  --preferred-challenges dns \
  --email admin@securenexus.net \
  --agree-tos \
  -d securenexus.net \
  -d '*.securenexus.net'
```

---

## Step 3: Add TXT Record

Certbot will prompt you with something like:

```
Please deploy a DNS TXT record under the name:
_acme-challenge.securenexus.net.

with the following value:
ABC123XYZ456EXAMPLE

Press Enter to Continue
```

**Use the helper script to add the TXT record:**

```bash
# Copy the TXT value from certbot prompt, then run:
./scripts/lego-dns-helper.sh "ABC123XYZ456EXAMPLE"
```

This script will:
- Update the DNS zone file
- Increment the serial number
- Restart CoreDNS
- Verify the TXT record is live

**Then press Enter in certbot to continue.**

---

## Step 4: Second TXT Record (Wildcard)

Certbot will prompt for a second TXT record for `*.securenexus.net`:

```
Please deploy a DNS TXT record under the name:
_acme-challenge.securenexus.net.

with the following value:
DEF789UVW012ANOTHER

Press Enter to Continue
```

**Add this second TXT record:**

```bash
# This will ADD a second TXT record (not replace)
./scripts/lego-dns-helper.sh "DEF789UVW012ANOTHER"
```

**Then press Enter in certbot.**

---

## Step 5: Certificate Generation

Certbot will verify the TXT records and generate certificates:

```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/securenexus.net/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/securenexus.net/privkey.pem
```

---

## Step 6: Import Certificates to Traefik

Run the import script:

```bash
sudo bash << 'IMPORT_SCRIPT'
CERT_PATH="/etc/letsencrypt/live/securenexus.net"

# Encode certificates to base64
CERT_B64=$(base64 -w0 < "$CERT_PATH/fullchain.pem")
KEY_B64=$(base64 -w0 < "$CERT_PATH/privkey.pem")

# Backup existing acme.json
cp acme/acme.json acme/acme.json.pre-certbot-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

# Create new acme.json with certbot certificates
cat > acme/acme.json << EOF
{
  "le": {
    "Account": {
      "Email": "admin@securenexus.net",
      "Registration": {
        "body": {
          "status": "valid"
        },
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
        "certificate": "$CERT_B64",
        "key": "$KEY_B64",
        "Store": "default"
      }
    ]
  }
}
EOF

# Set proper permissions and ownership
chmod 600 acme/acme.json
chown $(stat -c '%u:%g' acme) acme/acme.json

echo "✅ Certificates imported to acme/acme.json"
IMPORT_SCRIPT
```

---

## Step 7: Restart Traefik

```bash
docker compose restart traefik
```

Wait a few seconds, then test:

```bash
sleep 5
curl -v https://securenexus.net 2>&1 | grep "subject:"
```

Should show:
```
*  subject: CN=securenexus.net
*  issuer: C = US, O = Let's Encrypt, CN = R...
```

---

## Step 8: Cleanup TXT Records

After successful certificate generation, remove the TXT records:

```bash
# Edit the zone file
vim dns/zones/securenexus.net.zone

# Remove the _acme-challenge lines
# Increment serial: 2025100104 → 2025100105

# Restart CoreDNS
docker compose restart coredns
```

---

## Step 9: Verify All Domains

Test multiple domains:

```bash
for domain in securenexus.net portal.securenexus.net grafana.securenexus.net prometheus.securenexus.net; do
  echo "Testing $domain:"
  curl -I https://$domain 2>&1 | head -1
done
```

All should show `HTTP/2 200` or similar success response.

---

## Certificate Renewal

Certbot certificates are valid for 90 days. To renew:

```bash
# Dry run test
sudo certbot renew --dry-run

# Actual renewal (when needed)
sudo certbot renew

# Then re-import to Traefik (Step 6)
```

**Set up auto-renewal:**

```bash
# Create renewal hook script
sudo cat > /etc/letsencrypt/renewal-hooks/deploy/import-to-traefik.sh << 'HOOK'
#!/bin/bash
cd /home/tristian/securenexus-fullstack

CERT_PATH="/etc/letsencrypt/live/securenexus.net"
CERT_B64=$(base64 -w0 < "$CERT_PATH/fullchain.pem")
KEY_B64=$(base64 -w0 < "$CERT_PATH/privkey.pem")

cat > acme/acme.json << EOF
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
        "certificate": "$CERT_B64",
        "key": "$KEY_B64",
        "Store": "default"
      }
    ]
  }
}
EOF

chmod 600 acme/acme.json
chown $(stat -c '%u:%g' acme) acme/acme.json

docker compose restart traefik
HOOK

sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/import-to-traefik.sh

# Test renewal
sudo certbot renew --dry-run
```

---

## Troubleshooting

### TXT Record Not Propagating

```bash
# Check locally
dig @localhost _acme-challenge.securenexus.net TXT +short

# Check from Google DNS
dig @8.8.8.8 _acme-challenge.securenexus.net TXT +short

# Restart CoreDNS if needed
docker compose restart coredns
```

### Certbot Validation Timeout

If certbot times out waiting for DNS:
- Wait 30 seconds after running the helper script
- Verify TXT record is visible externally
- Press Enter only when confirmed

### Certificate Not Loading in Traefik

```bash
# Check acme.json permissions
ls -la acme/acme.json
# Should be: -rw------- with proper owner

# Check Traefik logs
docker compose logs traefik | tail -50

# Verify certificate in acme.json
cat acme/acme.json | jq -r '.le.Certificates[].domain'
```

---

## Success Criteria

✅ Certbot completes without errors
✅ Certificates saved to `/etc/letsencrypt/live/securenexus.net/`
✅ `acme/acme.json` contains base64-encoded certificates
✅ Traefik serves valid Let's Encrypt certificates
✅ No browser SSL warnings
✅ All subdomains accessible via HTTPS

---

**This wildcard certificate covers all current and future subdomains!**
