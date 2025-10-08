# Grafana 403 Error - Expected Behavior

## Summary

**The 403 error when accessing Grafana from the server itself is CORRECT and EXPECTED behavior.**

Your security configuration is working properly. The server cannot access its own admin services via public domains because it's not coming from the Tailscale VPN network.

---

## Why You're Getting 403

### The Request Flow

When you run `curl https://grafana.securenexus.net` **from the server itself**:

1. **DNS Resolution:**
   - `grafana.securenexus.net` → `137.74.40.208` (server's public IP)

2. **Network Routing:**
   - Request goes out to the public IP
   - Returns to Traefik on the same server
   - Traefik sees source IP: `137.74.40.208` (server's public IP)

3. **Middleware Check:**
   - `admin-vpn` middleware checks if source IP is in allowed ranges:
     - ✅ `100.64.0.0/10` (Tailscale VPN)
     - ✅ `127.0.0.1/32` (localhost)
     - ✅ `172.18.0.0/16` (Docker internal network)
   - ❌ `137.74.40.208` (server's public IP) is NOT allowed

4. **Result:**
   - **403 Forbidden** ✅ (correct security response)

---

## How to Access Grafana (3 Options)

### ✅ Option 1: Access from Another Device (RECOMMENDED)

Access Grafana from your **PC or phone** that's connected to Tailscale VPN:

**From your PC (already connected to Tailscale):**
```bash
# Your PC shows as: 100.91.127.102 pc-main
# Just open browser to:
https://grafana.securenexus.net
```

**From your phone (already connected to Tailscale):**
```bash
# Your phone shows as: 100.68.130.34 google-pixel-9-pro
# Just open browser to:
https://grafana.securenexus.net
```

Your PC and phone are already authenticated to Tailscale, so they have IPs in the `100.64.0.0/10` range and will be allowed through the `admin-vpn` middleware.

---

### Option 2: Create Local Hosts Override

**If you need to access from the server itself**, add a hosts file entry:

```bash
# Add to /etc/hosts
echo "172.18.0.5 grafana.securenexus.net" | sudo tee -a /etc/hosts

# Find Grafana's Docker IP first:
docker inspect securenexus-fullstack-grafana-1 | jq -r '.[0].NetworkSettings.Networks.proxy.IPAddress'

# Then test:
curl -I https://grafana.securenexus.net
```

**Pros:**
- Allows server to access its own services
- Traffic stays within Docker network (faster)
- Source IP will be Docker network range (allowed by admin-vpn)

**Cons:**
- Need to update if container IP changes
- Requires manual maintenance

---

### Option 3: Add Server IP to Whitelist (NOT RECOMMENDED)

**⚠️ Security Warning:** This defeats the purpose of VPN-only access.

```yaml
# Edit config/dynamic/traefik_dynamic.yml
admin-vpn:
  ipAllowList:
    sourceRange:
      - 100.64.0.0/10   # Tailscale CGNAT range
      - 127.0.0.1/32    # Localhost
      - 172.18.0.0/16   # Docker proxy network
      - 137.74.40.208/32 # Server's public IP (NOT RECOMMENDED)
```

**Why NOT recommended:**
- Allows access from server's public IP
- If someone gains SSH access to server, they can access admin services
- Bypasses VPN security requirement

---

## Verification

### ✅ From PC/Phone (Tailscale connected):

```bash
# Should return 200 OK with Grafana HTML
curl -I https://grafana.securenexus.net

# Or just open in browser - should load Grafana dashboard
```

### ❌ From Server (expected to fail):

```bash
# Returns 403 Forbidden (correct behavior)
curl -I https://grafana.securenexus.net
```

### Check Your Tailscale Devices:

```bash
tailscale status
```

Output shows:
- ✅ `100.77.139.33   vps-09e1118a` (server)
- ✅ `100.68.130.34   google-pixel-9-pro` (phone - can access Grafana)
- ✅ `100.91.127.102  pc-main` (PC - can access Grafana)

---

## Understanding the Security Model

### The Purpose of admin-vpn Middleware

1. **VPN-Only Access:** Admin services only accessible from Tailscale VPN
2. **Zero Trust:** Even if someone compromises the server, they can't access admin interfaces without VPN
3. **Remote Access:** Legitimate admins can access from anywhere via Tailscale

### Why Server Can't Access Its Own Services

- The server's public IP is deliberately **excluded** from admin access
- This prevents local privilege escalation attacks
- Forces all admin access through Tailscale (authenticated, encrypted)

### What IS Accessible from Server

Public services with no VPN requirement:
- ✅ Landing page: `https://securenexus.net`
- ✅ Portal: `https://portal.securenexus.net`
- ✅ Authentik SSO: `https://sso.securenexus.net`
- ✅ Uptime status: `https://status.securenexus.net`
- ✅ Mail webmail: `https://mail.securenexus.net`

Admin services (VPN required):
- ❌ Grafana: `https://grafana.securenexus.net` (403 from server)
- ❌ Prometheus: `https://prometheus.securenexus.net` (403 from server)
- ❌ Traefik: `https://traefik.securenexus.net` (403 from server)
- ❌ Alertmanager: `https://alerts.securenexus.net` (403 from server)

---

## Recommended Workflow

### For Admin Tasks:

1. **Use your PC or phone** (already Tailscale connected)
2. **Open browser to admin services** (Grafana, Prometheus, etc.)
3. **Access is granted** because you're coming from Tailscale VPN

### For Server Maintenance:

1. **SSH to server** for command-line tasks
2. **Use direct Docker commands** for container management
3. **Use Tailscale-connected device** for web UIs

### Examples:

```bash
# SSH to server (from PC)
ssh tristian@vps-09e1118a

# View Grafana logs
docker compose logs grafana

# Restart Grafana
docker compose restart grafana

# Access Grafana web UI (from PC browser, not SSH session)
# Browser: https://grafana.securenexus.net
```

---

## Troubleshooting

### "I can't access Grafana from my PC"

**Check:**
1. Is Tailscale connected on PC?
   ```bash
   tailscale status  # Should show 100.x.x.x IP
   ```

2. Can you ping the server via Tailscale?
   ```bash
   tailscale ping vps-09e1118a
   ```

3. Is DNS resolving correctly?
   ```bash
   nslookup grafana.securenexus.net
   # Should return 137.74.40.208
   ```

### "Grafana won't load / times out"

**Possible causes:**
- Firewall blocking port 443
- DNS not resolving
- Traefik not running
- Grafana container down

**Check:**
```bash
# On server:
docker compose ps grafana
docker compose logs grafana --tail 20
curl http://localhost:8080/api/http/routers | jq | grep grafana
```

### "I get certificate errors"

**Cause:** SSL certificate issue

**Check:**
```bash
# Verify certificate
openssl s_client -connect grafana.securenexus.net:443 -servername grafana.securenexus.net </dev/null 2>/dev/null | openssl x509 -noout -dates
```

---

## Summary

✅ **Your configuration is correct**
- Admin services are properly protected by VPN-only access
- 403 from server is expected and secure behavior
- Access from PC/phone (Tailscale connected) works correctly

🔐 **Security working as designed**
- Server's public IP deliberately excluded from admin access
- Zero-trust model: admin access requires VPN authentication
- Protection against local privilege escalation

📱 **To access Grafana:**
1. Use your PC (100.91.127.102) or phone (100.68.130.34)
2. Make sure Tailscale is connected
3. Open browser to https://grafana.securenexus.net
4. Should load without 403 error

---

**Document Status:** Issue Explained - No Fix Needed
**Security Status:** ✅ Working Correctly
**Action Required:** Access from Tailscale-connected device (PC/phone)
