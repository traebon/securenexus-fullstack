# External DNS Configuration Guide

This guide will help you configure DNS records for `securenexus.net` to point to your server.

---

## Overview

**Your Server IP**: `217.154.37.3`
**Domain**: `securenexus.net`

You need to configure DNS records at your domain registrar or DNS provider to point your domain to your server.

---

## Step 1: Identify Your DNS Provider

Your DNS is managed by whoever you registered the domain with, or where you transferred DNS management. Common providers:

- **Registrars**: Namecheap, GoDaddy, Google Domains, Cloudflare Registrar
- **DNS Providers**: Cloudflare, Route53 (AWS), DigitalOcean DNS, etc.

**How to Find Your DNS Provider:**

```bash
# Check nameservers for your domain
dig NS securenexus.net +short
```

The nameserver response will tell you who manages your DNS (e.g., `ns1.cloudflare.com` = Cloudflare).

---

## Step 2: Required DNS Records

You need to create these DNS records at your DNS provider:

### A Records (IPv4)

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | 217.154.37.3 | 300 |
| A | * | 217.154.37.3 | 300 |

**Explanation:**
- `@` = Root domain (`securenexus.net`)
- `*` = Wildcard for all subdomains (`*.securenexus.net`)

### Optional: AAAA Records (IPv6)

If you have an IPv6 address, add these as well:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| AAAA | @ | your:ipv6:address::here | 300 |
| AAAA | * | your:ipv6:address::here | 300 |

### CAA Records (Recommended for SSL)

Allow Let's Encrypt to issue certificates:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| CAA | @ | 0 issue "letsencrypt.org" | 300 |

---

## Step 3: Provider-Specific Instructions

### Cloudflare

1. Log in to https://dash.cloudflare.com
2. Select `securenexus.net`
3. Go to **DNS** → **Records**
4. Click **Add record**

**Add Root Domain:**
- Type: `A`
- Name: `@`
- IPv4 address: `217.154.37.3`
- Proxy status: **DNS only** (gray cloud, not orange)
- TTL: Auto
- Click **Save**

**Add Wildcard:**
- Type: `A`
- Name: `*`
- IPv4 address: `217.154.37.3`
- Proxy status: **DNS only** (gray cloud)
- TTL: Auto
- Click **Save**

**Important**: Turn off Cloudflare proxy (orange cloud) initially to test. You can enable it later if desired.

### Namecheap

1. Log in to https://namecheap.com
2. Go to **Domain List** → Select `securenexus.net`
3. Click **Manage** → **Advanced DNS**
4. Click **Add New Record**

**Add Root Domain:**
- Type: `A Record`
- Host: `@`
- Value: `217.154.37.3`
- TTL: Automatic
- Click ✓

**Add Wildcard:**
- Type: `A Record`
- Host: `*`
- Value: `217.154.37.3`
- TTL: Automatic
- Click ✓

### GoDaddy

1. Log in to https://godaddy.com
2. Go to **My Products** → **Domains**
3. Click `securenexus.net` → **DNS**
4. Click **Add** (or edit existing records)

**Add Root Domain:**
- Type: `A`
- Name: `@`
- Value: `217.154.37.3`
- TTL: 1 Hour
- Click **Save**

**Add Wildcard:**
- Type: `A`
- Name: `*`
- Value: `217.154.37.3`
- TTL: 1 Hour
- Click **Save**

### Google Domains / Google Cloud DNS

1. Log in to https://domains.google.com
2. Select `securenexus.net`
3. Click **DNS** on the left
4. Scroll to **Custom records**

**Add Root Domain:**
- Host name: (leave blank for @)
- Type: `A`
- TTL: 300
- Data: `217.154.37.3`
- Click **Add**

**Add Wildcard:**
- Host name: `*`
- Type: `A`
- TTL: 300
- Data: `217.154.37.3`
- Click **Add**

### Route 53 (AWS)

1. Log in to AWS Console → Route 53
2. Go to **Hosted zones** → `securenexus.net`
3. Click **Create record**

**Add Root Domain:**
- Record name: (leave blank)
- Record type: `A`
- Value: `217.154.37.3`
- TTL: 300
- Routing policy: Simple
- Click **Create records**

**Add Wildcard:**
- Record name: `*`
- Record type: `A`
- Value: `217.154.37.3`
- TTL: 300
- Routing policy: Simple
- Click **Create records**

### DigitalOcean

1. Log in to https://cloud.digitalocean.com
2. Go to **Networking** → **Domains**
3. Select `securenexus.net`

**Add Root Domain:**
- Type: `A`
- Hostname: `@`
- Will direct to: Enter IP `217.154.37.3`
- TTL: 300
- Click **Create Record**

**Add Wildcard:**
- Type: `A`
- Hostname: `*`
- Will direct to: Enter IP `217.154.37.3`
- TTL: 300
- Click **Create Record**

---

## Step 4: Verify DNS Propagation

DNS changes can take 5 minutes to 48 hours to propagate globally, but usually complete within 15-30 minutes.

### Test DNS Resolution

```bash
# Test root domain
dig securenexus.net +short

# Expected output:
# 217.154.37.3

# Test wildcard
dig test.securenexus.net +short

# Expected output:
# 217.154.37.3

# Test specific subdomains
dig authentik.securenexus.net +short
dig grafana.securenexus.net +short
dig status.securenexus.net +short

# All should return: 217.154.37.3
```

### Check from Multiple Locations

Use online tools to check DNS propagation:
- https://www.whatsmydns.net/#A/securenexus.net
- https://dnschecker.org/#A/securenexus.net

These will show if DNS has propagated globally.

---

## Step 5: Test HTTPS Access

Once DNS propagates, test your services:

```bash
# Test main site
curl -I https://securenexus.net

# Test status page
curl -I https://status.securenexus.net

# Test authentik (will require login or redirect)
curl -I https://authentik.securenexus.net
```

### Expected Results

- **HTTP**: Should redirect to HTTPS (301 or 308)
- **HTTPS**: Should return 200 OK or authentication redirect
- **SSL Certificate**: Traefik will auto-generate via Let's Encrypt

---

## Step 6: SSL Certificate Generation

Traefik will automatically request SSL certificates from Let's Encrypt once:
1. DNS points to your server
2. Port 80 is accessible (for HTTP-01 challenge)
3. Domain is reachable from the internet

**Monitor certificate requests:**

```bash
# Watch Traefik logs
docker compose logs -f traefik | grep -i acme

# Check ACME storage
ls -lh acme/acme.json

# Should show growing file size as certificates are added
```

**First certificate request may take 1-2 minutes.**

---

## Troubleshooting

### DNS Not Resolving

```bash
# Check if DNS has updated
dig securenexus.net +short

# If it returns old IP or nothing:
# - Wait longer (can take up to 24 hours)
# - Clear local DNS cache:
sudo systemd-resolve --flush-caches

# Check from external DNS server
dig @8.8.8.8 securenexus.net +short
```

### SSL Certificate Errors

```bash
# Check Traefik logs for ACME errors
docker compose logs traefik | grep -i "error\|fail"

# Common issues:
# 1. Port 80 not accessible from internet (check firewall)
# 2. DNS not propagated yet (wait longer)
# 3. Rate limit hit (wait 1 hour, Let's Encrypt has limits)
```

**Verify port 80 is accessible:**
```bash
# From external machine
curl -I http://securenexus.net

# Should get redirect to HTTPS
```

### Cloudflare Proxy Issues

If using Cloudflare with proxy enabled (orange cloud):
- SSL mode must be **Full** or **Full (Strict)**
- Traefik can still generate certificates
- Be aware of Cloudflare's IP in logs instead of real client IPs

**Recommendation**: Keep proxy **OFF** (gray cloud) initially for testing.

---

## Current DNS Configuration

### Before External DNS Setup

Your CoreDNS server is authoritative for `securenexus.net` but requires external DNS to reach it:

```
Internet User
    ↓
External DNS (needs configuration) ← YOU ARE HERE
    ↓
Your Server (217.154.37.3)
    ↓
Traefik (routing based on Host header)
    ↓
Backend Services
```

### After External DNS Setup

```
Internet User
    ↓
External DNS (returns 217.154.37.3) ✅
    ↓
Your Server Firewall (port 443 allowed) ✅
    ↓
Traefik (SSL termination + routing) ✅
    ↓
Middleware (security, VPN check, etc.) ✅
    ↓
Backend Service ✅
```

---

## Security Notes

### DNS Provider Security

- Enable **2FA** on your DNS provider account
- Use **strong passwords**
- Consider **DNS provider with DDoS protection** (Cloudflare free tier)
- Enable **DNSSEC** if available (improved security)

### Cloudflare Recommendations

If using Cloudflare:
- **Pros**: Free DDoS protection, CDN, analytics
- **Cons**: They terminate SSL (you lose end-to-end encryption visibility)
- **Setup**: Set SSL mode to "Full" to encrypt Cloudflare → Your Server

### Rate Limits

Let's Encrypt has rate limits:
- **50 certificates per domain per week**
- **5 duplicate certificates per week**

If testing, use Traefik's staging CA first:
```yaml
# In config/traefik.yml
certificatesResolvers:
  le:
    acme:
      caServer: "https://acme-staging-v02.api.letsencrypt.org/directory"
```

---

## Quick Reference

### Minimum Required Records

```
Type    Name    Value           TTL
A       @       217.154.37.3    300
A       *       217.154.37.3    300
```

### Verification Commands

```bash
# Check DNS
dig securenexus.net +short

# Test HTTP
curl -I http://securenexus.net

# Test HTTPS
curl -I https://securenexus.net

# Watch certificate generation
docker compose logs -f traefik | grep -i acme
```

### Your Services After DNS Setup

Once configured, these will be accessible:

**Public:**
- https://securenexus.net
- https://portal.securenexus.net
- https://status.securenexus.net

**VPN Only:**
- https://authentik.securenexus.net
- https://grafana.securenexus.net
- https://prometheus.securenexus.net
- https://traefik.securenexus.net
- https://vpn.securenexus.net
- https://dns.securenexus.net

---

## Need Help?

If you get stuck:

1. **Check your DNS provider's documentation** - Each has specific guides
2. **Verify DNS propagation** - Use whatsmydns.net
3. **Check Traefik logs** - `docker compose logs traefik`
4. **Test locally first** - Use `/etc/hosts` to test before DNS propagates
5. **Review firewall** - Ensure ports 80 and 443 are open

---

**Next Steps:**
1. Log in to your DNS provider
2. Add the A records as shown above
3. Wait 15-30 minutes for propagation
4. Test with `dig securenexus.net`
5. Access https://securenexus.net

Your infrastructure is ready and waiting for DNS configuration!
