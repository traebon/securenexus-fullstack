# Nameserver Configuration Guide

Your CoreDNS server is already configured as an authoritative nameserver for `securenexus.net`. You just need to tell your domain registrar to use it.

---

## Current Setup ✅

Your DNS is already configured:

```
Domain: securenexus.net
Nameservers: ns1.securenexus.net, ns2.securenexus.net
Both resolve to: 217.154.37.3

Zone file: dns/zones/securenexus.net.zone
CoreDNS: Running on ports 53 (DNS) and 853 (DNS-over-TLS)
```

**Verification:**
```bash
# Your CoreDNS is working locally
dig @localhost securenexus.net +short
# Returns: 217.154.37.3, 172.18.0.12
```

---

## What You Need to Do

You need to update your domain registrar to use your own nameservers instead of theirs.

### Step 1: Register Glue Records at Your Registrar

Because your nameservers (`ns1.securenexus.net`) are **under** your own domain, you need **glue records**.

**Glue records** tell the internet where to find your nameservers before DNS can work.

#### At Your Domain Registrar

**You need to:**
1. Log in to where you registered `securenexus.net`
2. Register custom/private nameservers (also called "glue records" or "host records")
3. Update domain to use those nameservers

---

## Registrar-Specific Instructions

### Cloudflare Registrar

Cloudflare doesn't support custom nameservers on domains registered with them. You'll need to:
- Keep using Cloudflare nameservers
- Add DNS records in Cloudflare dashboard pointing to `217.154.37.3`

**OR** transfer domain to another registrar that supports custom nameservers.

---

### Namecheap

#### Step 1: Register Nameservers (Glue Records)

1. Log in to https://namecheap.com
2. Go to **Domain List** → `securenexus.net` → **Manage**
3. Click **Advanced DNS** tab
4. Scroll to **Personal DNS Server** section
5. Click **Add Nameserver**

**Add NS1:**
- Nameserver: `ns1`
- IP Address: `217.154.37.3`
- Click ✓

**Add NS2:**
- Nameserver: `ns2`
- IP Address: `217.154.37.3`
- Click ✓

#### Step 2: Change Domain Nameservers

1. Go back to **Domain** tab
2. Find **Nameservers** section
3. Select **Custom DNS**
4. Enter:
   - `ns1.securenexus.net`
   - `ns2.securenexus.net`
5. Click ✓ to save

**Propagation**: 24-48 hours

---

### GoDaddy

#### Step 1: Register Nameservers (Glue Records)

1. Log in to https://godaddy.com
2. Go to **My Products** → **Domains**
3. Click `securenexus.net` → **Manage**
4. Scroll to **Additional Settings**
5. Click **Manage DNS Nameservers**
6. Click **Register my nameservers** (or "Host names")

**Add NS1:**
- Hostname: `ns1`
- IP Address: `217.154.37.3`
- Click **Add**

**Add NS2:**
- Hostname: `ns2`
- IP Address: `217.154.37.3`
- Click **Add**

#### Step 2: Change Domain Nameservers

1. Go back to DNS management
2. Click **Change Nameservers**
3. Select **Enter my own nameservers (advanced)**
4. Enter:
   - `ns1.securenexus.net`
   - `ns2.securenexus.net`
5. Click **Save**

---

### Google Domains

#### Step 1: Register Nameservers (Glue Records)

1. Log in to https://domains.google.com
2. Select `securenexus.net`
3. Click **DNS** on the left
4. Scroll to **Name servers**
5. Click **Use custom name servers**
6. Click **Manage name servers**

**Add NS1:**
- Name server: `ns1.securenexus.net`
- IPv4 address: `217.154.37.3`
- Click **Add**

**Add NS2:**
- Name server: `ns2.securenexus.net`
- IPv4 address: `217.154.37.3`
- Click **Add**

#### Step 2: Change Domain Nameservers

1. Still in **Name servers** section
2. Select **Use custom name servers**
3. Enter:
   - `ns1.securenexus.net`
   - `ns2.securenexus.net`
4. Click **Save**

---

### Gandi

#### Step 1: Register Glue Records

1. Log in to https://gandi.net
2. Go to **Domain** → `securenexus.net`
3. Click **Glue Records**
4. Click **Add**

**Add NS1:**
- Name: `ns1.securenexus.net`
- IPv4: `217.154.37.3`
- Save

**Add NS2:**
- Name: `ns2.securenexus.net`
- IPv4: `217.154.37.3`
- Save

#### Step 2: Change Nameservers

1. Go to **Nameservers** tab
2. Select **External nameservers**
3. Enter:
   - `ns1.securenexus.net`
   - `ns2.securenexus.net`
4. Click **Submit**

---

### Hover

#### Step 1: Register Nameservers

1. Log in to https://hover.com
2. Go to **Domains** → `securenexus.net`
3. Click **DNS** or **Nameservers**
4. Look for **Register a nameserver** or **Glue records**

**Add both nameservers with IP 217.154.37.3**

#### Step 2: Change Domain Nameservers

1. Click **Edit nameservers**
2. Enter:
   - `ns1.securenexus.net`
   - `ns2.securenexus.net`
3. Save

---

### Generic Instructions (Any Registrar)

If your registrar isn't listed above:

#### Step 1: Find "Host Records", "Glue Records", or "Register Nameserver"

Look for these sections in your registrar's control panel:
- "Host Records"
- "Glue Records"
- "Register Nameserver"
- "Private Nameservers"
- "Custom Nameservers"

Create entries:
```
ns1.securenexus.net → 217.154.37.3
ns2.securenexus.net → 217.154.37.3
```

#### Step 2: Update Domain Nameservers

Find "Nameservers" or "DNS Settings" and change to:
```
ns1.securenexus.net
ns2.securenexus.net
```

---

## Verification

### Step 1: Check Glue Records Were Created

```bash
# Query parent nameservers for your domain
dig @a.gtld-servers.net securenexus.net NS +norec

# Should show:
# securenexus.net.    86400   IN   NS   ns1.securenexus.net.
# securenexus.net.    86400   IN   NS   ns2.securenexus.net.

# And glue records:
# ns1.securenexus.net. 86400  IN   A    217.154.37.3
# ns2.securenexus.net. 86400  IN   A    217.154.37.3
```

### Step 2: Check DNS Resolution

Wait 24-48 hours after making changes, then test:

```bash
# Check nameservers
dig NS securenexus.net +short
# Should return:
# ns1.securenexus.net.
# ns2.securenexus.net.

# Check root domain
dig securenexus.net +short
# Should return:
# 217.154.37.3
# 172.18.0.12

# Test subdomains
dig authentik.securenexus.net +short
dig grafana.securenexus.net +short

# Test from public DNS
dig @8.8.8.8 securenexus.net +short
dig @1.1.1.1 securenexus.net +short
```

### Step 3: Check from Multiple Locations

Use online tools:
- https://www.whatsmydns.net/#NS/securenexus.net
- https://dnschecker.org/#NS/securenexus.net

Should show your nameservers propagated globally.

---

## Your DNS Zone File

Current zone file at `dns/zones/securenexus.net.zone`:

```
securenexus.net. IN SOA ns1.securenexus.net. admin.securenexus.net. (
    2025092901 ; serial
    3600       ; refresh
    1800       ; retry
    604800     ; expire
    86400      ; minimum
)
securenexus.net. IN NS ns1.securenexus.net.
securenexus.net. IN NS ns2.securenexus.net.
securenexus.net. IN A 217.154.37.3
ns1.securenexus.net. IN A 217.154.37.3
ns2.securenexus.net. IN A 217.154.37.3
```

### Adding Subdomains

Subdomains are handled automatically by:
1. **etcd backend** - Dynamic records created by `dns-updater` service
2. **Wildcard resolution** - CoreDNS can return A records for any subdomain

You can also manually add records to the zone file:

```bash
# Edit zone file
vim dns/zones/securenexus.net.zone

# Add records like:
# test.securenexus.net. IN A 217.154.37.3

# Increment serial number (important!)
# Change: 2025092901 to 2025092902

# Reload CoreDNS
docker compose restart coredns
```

---

## Dynamic DNS Updates

Your `dns-updater` service automatically creates DNS records in etcd for containers with Traefik labels:

**Current dynamic records:**
```bash
# Check etcd for DNS records
docker compose exec etcd etcdctl get --prefix /coredns/

# These are created automatically for your services
```

**How it works:**
1. Container starts with Traefik labels (e.g., `Host=grafana.securenexus.net`)
2. `dns-updater` watches Docker events
3. Creates A record in etcd: `grafana.securenexus.net → container IP`
4. CoreDNS reads from etcd and serves the record

This means all your Traefik-routed services automatically get DNS records!

---

## Troubleshooting

### Nameservers Not Working

**Issue**: DNS not resolving after 48 hours

**Check:**
```bash
# Verify CoreDNS is listening
ss -ulnp | grep :53

# Test locally
dig @localhost securenexus.net

# Check from external DNS server
dig @8.8.8.8 securenexus.net

# Query parent servers directly
dig @a.gtld-servers.net securenexus.net NS
```

**Common causes:**
1. **Glue records not registered** - Go back to registrar and add them
2. **Firewall blocking port 53** - Check UFW allows port 53
3. **CoreDNS not running** - Check `docker compose ps | grep coredns`

### Glue Records Required

If you get an error like "nameserver is under the domain itself", you need glue records.

**Why?** The internet needs to know where `ns1.securenexus.net` is **before** it can query DNS for `securenexus.net`. That's what glue records do - they're registered at the registrar level.

### Port 53 Blocked

```bash
# Verify port 53 is open
sudo ufw status | grep 53

# Should show:
# 53/tcp         ALLOW       Anywhere
# 53/udp         ALLOW       Anywhere
# 853/tcp        ALLOW       Anywhere
```

### Serial Number Issues

If you edit the zone file, **always increment the serial number**:

```
Current: 2025092901
New:     2025092902
```

Format: `YYYYMMDDnn` (year, month, day, revision number)

---

## Current Status

✅ CoreDNS running and listening on port 53
✅ Zone file configured with NS records
✅ Glue records defined (ns1, ns2 → 217.154.37.3)
✅ Firewall allows DNS traffic (port 53)
✅ Dynamic DNS updates working via etcd

**What you need to do:**
1. Log in to your domain registrar
2. Register nameserver glue records
3. Update domain to use your nameservers
4. Wait 24-48 hours for propagation

---

## Quick Reference

### Your Nameservers
```
ns1.securenexus.net → 217.154.37.3
ns2.securenexus.net → 217.154.37.3
```

### Test Commands
```bash
# Check nameservers
dig NS securenexus.net

# Check A record
dig securenexus.net

# Test locally
dig @localhost securenexus.net

# Test via public DNS
dig @8.8.8.8 securenexus.net
```

### Monitor DNS Propagation
- https://www.whatsmydns.net/#NS/securenexus.net
- https://dnschecker.org/#NS/securenexus.net

---

**Your DNS infrastructure is ready - just needs registrar configuration!**
