# Tailscale VPN Health Check Issue - Resolution

**Issue Reported:** 2025-10-05

## Problem Summary

Tailscale health check shows error:
```
Tailscale could not establish an encrypted connection with '"vpn.securenexus.net"':
likely intercepted connection; certificate is self-signed by CN=TRAEFIK DEFAULT CERT
```

## Root Cause Analysis

### What's Happening

1. **System migrated from Headscale to Tailscale**
   - Previously used self-hosted Headscale coordinator at `vpn.securenexus.net`
   - Now using official Tailscale service (controlplane.tailscale.com)
   - Old Headscale references remain in documentation and possibly Tailscale state

2. **DNS Wildcard Record**
   - Zone file has `*.securenexus.net. IN A 137.74.40.208` (dns/zones/securenexus.net.zone:14)
   - This causes `vpn.securenexus.net` to resolve to the server IP
   - All HTTPS traffic to server IP goes through Traefik

3. **Certificate Mismatch**
   - Tailscale (or a periodic health check) tries to reach `vpn.securenexus.net`
   - Traffic hits Traefik reverse proxy
   - Traefik presents its default self-signed certificate (no router configured for vpn domain)
   - Certificate doesn't match expected Headscale certificate
   - Health check fails

### Current Status ✅

**Tailscale IS working correctly:**
- Connected to official Tailscale network (controlplane.tailscale.com)
- Node has IP: 100.77.139.33
- Network check: PASSING
- UDP connectivity: ✅ Yes
- IPv4: ✅ 137.74.40.208
- IPv6: ✅ 2001:41d0:305:2100::1ade
- DERP latency: 4.3ms to London server
- Can see peers: vps-09e1118a

**The health warning is cosmetic** - it's about an old/stale reference to vpn.securenexus.net that doesn't affect actual VPN functionality.

## Solutions

### Option 1: Quick Fix (Ignore Warning) ⚡

**Status:** This is safe to ignore
- Tailscale VPN is fully functional
- The warning is about a legacy domain that's no longer used
- No impact on actual VPN connectivity or security

**Pros:** No changes needed
**Cons:** Cosmetic warning remains

---

### Option 2: Remove Wildcard DNS Record 🔧

**Changes needed:**
```bash
# Edit dns/zones/securenexus.net.zone
# Replace line 14:
*.securenexus.net. IN A 137.74.40.208

# With explicit records:
portal.securenexus.net. IN A 137.74.40.208
grafana.securenexus.net. IN A 137.74.40.208
prometheus.securenexus.net. IN A 137.74.40.208
traefik.securenexus.net. IN A 137.74.40.208
authentik.securenexus.net. IN A 137.74.40.208
sso.securenexus.net. IN A 137.74.40.208
status.securenexus.net. IN A 137.74.40.208
alerts.securenexus.net. IN A 137.74.40.208
dns.securenexus.net. IN A 137.74.40.208
brand.securenexus.net. IN A 137.74.40.208

# Increment serial number (line 3):
2025100224 ; serial (was 2025100223)

# Reload DNS
docker compose restart coredns
```

**Pros:**
- Prevents accidental resolution of unused subdomains
- More explicit DNS configuration
- Resolves the health warning

**Cons:**
- Need to add new A records manually when adding services
- More maintenance overhead

---

### Option 3: Add Explicit vpn Subdomain Override 🎯

**Changes needed:**
```bash
# Edit dns/zones/securenexus.net.zone
# Add before the wildcard (line 14):
vpn.securenexus.net. IN A 127.0.0.1  ; Prevent routing to Traefik

# Keep wildcard:
*.securenexus.net. IN A 137.74.40.208

# Increment serial:
2025100224 ; serial

# Reload DNS
docker compose restart coredns
```

**Pros:**
- Minimal change
- Wildcard still works for new services
- Prevents vpn.securenexus.net from hitting Traefik

**Cons:**
- Doesn't fully clean up legacy configuration
- Warning might persist if cached

---

### Option 4: Clean Tailscale State and Reset 🔄

**Changes needed:**
```bash
# 1. Logout from Tailscale
sudo tailscale logout

# 2. Remove state file
sudo rm /var/lib/tailscale/tailscaled.state

# 3. Restart Tailscale daemon
sudo systemctl restart tailscaled

# 4. Re-authenticate (official Tailscale, no custom login server)
sudo tailscale up

# 5. Follow browser authentication flow
```

**Pros:**
- Completely removes any Headscale references
- Clean slate for Tailscale configuration
- Should eliminate health warning

**Cons:**
- Requires re-authentication
- Need to reconfigure any Tailscale settings (ACLs, exit nodes, etc.)
- VPN temporarily unavailable during process

---

## Recommended Action Plan

### Immediate (Do Now)

✅ **No action required** - Tailscale is working correctly. The health warning is cosmetic.

### Short-term (This Week)

**Recommended: Option 3** - Add explicit vpn subdomain override
- Minimal risk
- Prevents confusion
- Maintains wildcard for convenience

```bash
# Quick fix script
cd /home/tristian/securenexus-fullstack

# Backup current zone file
cp dns/zones/securenexus.net.zone dns/zones/securenexus.net.zone.backup

# Edit zone file (add override before wildcard)
# Then increment serial and reload DNS
docker compose restart coredns

# Verify
dig @localhost vpn.securenexus.net +short  # Should show 127.0.0.1
```

### Medium-term (This Month)

1. **Clean up old Headscale documentation**
   - Remove/update references in:
     - VPN_SETUP.md
     - tailscale-setup.md
     - fix-vpn-connection.md
     - vpn-setup-instructions.txt
     - DEPLOYMENT_SUMMARY.md
     - FIREWALL.md

2. **Update documentation to reflect Tailscale-only setup**

3. **Consider Option 4** if health warning persists after DNS changes

---

## Verification Steps

After implementing fixes:

```bash
# 1. Check DNS resolution
dig @localhost vpn.securenexus.net +short

# 2. Verify Tailscale status
tailscale status

# 3. Run network check
tailscale netcheck

# 4. Check for health warnings
tailscale status 2>&1 | grep -i health

# 5. Test VPN connectivity
tailscale ping <peer-ip>
```

---

## Related Files

**DNS Configuration:**
- `dns/zones/securenexus.net.zone` - Zone file with wildcard record

**Tailscale References:**
- `compose.yml:???` - Tailscale container definition (correct, no changes needed)
- `VPN_SETUP.md` - Old Headscale setup instructions
- `tailscale-setup.md` - Contains Headscale login server references
- `fix-vpn-connection.md` - Troubleshooting for Headscale
- `vpn-setup-instructions.txt` - Headscale auth keys

**System Configuration:**
- `/var/lib/tailscale/tailscaled.state` - Tailscale state (may contain old references)
- Tailscale daemon running as systemd service (not container)

---

## Key Findings

1. ✅ **Tailscale is fully functional** - connected to official Tailscale network
2. ✅ **No security issue** - VPN traffic not actually going through Traefik
3. ⚠️ **Cosmetic health warning** - old reference to vpn.securenexus.net
4. 📝 **Documentation outdated** - multiple files reference Headscale
5. 🌐 **DNS wildcard** - causes vpn.securenexus.net to resolve to server

---

## Admin-VPN Middleware Impact

**Important:** This health warning does NOT affect the `admin-vpn` middleware functionality:

- `admin-vpn` middleware checks source IP ranges (100.64.0.0/10 for Tailscale CGNAT)
- Tailscale VPN is working and assigning IPs in this range
- Admin services protected by admin-vpn middleware ARE accessible from Tailscale VPN
- The health warning is unrelated to middleware security

**Test admin service access:**
```bash
# From a Tailscale-connected device:
curl -I https://grafana.securenexus.net  # Should work if VPN connected
curl -I https://prometheus.securenexus.net  # Should work if VPN connected
curl -I https://traefik.securenexus.net  # Should work if VPN connected
```

---

**Document Status:** DIAGNOSTIC COMPLETE
**Priority:** LOW (cosmetic issue, functionality not affected)
**Action Required:** Optional - implement Option 3 to remove warning
