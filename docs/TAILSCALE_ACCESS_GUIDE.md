# Tailscale VPN Access Guide

**Tailnet**: `spangled-atlas.ts.net`
**Server**: `neverland` (IP: `100.77.139.33`)
**Full Hostname**: `neverland.spangled-atlas.ts.net`

## 🎯 The Problem

Your admin services (Portainer, Grafana, Prometheus) are protected by the `admin-vpn` middleware, which only allows access from Tailscale IPs (`100.64.0.0/10`).

However, when you access via domain names like `https://portainer.securenexus.net`, Traefik checks:
1. ✅ Are you coming from a Tailscale IP?
2. ✅ Does the Host header match?

The issue is that when you're on Tailscale, you can reach the server, but the domain names still resolve to the public IP for everyone (DNS), so Traefik sees your request coming from outside the VPN.

## ✅ Solutions

### Option 1: Access via Direct Tailscale IP (With Host Header)

**Use this command from your client device** (connected to Tailscale):

```bash
# Portainer
curl -k -H "Host: portainer.securenexus.net" https://100.77.139.33

# Or in browser, you need to set up local DNS
```

**This is complicated for browsers** - not recommended.

---

### Option 2: Set Up Local /etc/hosts Override (RECOMMENDED for Tailscale)

On your **client device** (laptop/phone connected to Tailscale), add these entries to `/etc/hosts` (or `C:\Windows\System32\drivers\etc\hosts` on Windows):

```bash
# Edit /etc/hosts and add:
100.77.139.33   portainer.securenexus.net
100.77.139.33   grafana.securenexus.net
100.77.139.33   prometheus.securenexus.net
100.77.139.33   traefik.securenexus.net
```

**How to do this:**

**On Linux/Mac:**
```bash
sudo nano /etc/hosts

# Add the lines above, save and exit
```

**On Windows:**
```powershell
# Run as Administrator:
notepad C:\Windows\System32\drivers\etc\hosts

# Add the lines above, save
```

**On Android (requires root):**
- Use app like "Hosts Editor"
- Add entries manually

**Now when you visit** `https://portainer.securenexus.net`:
1. Your device resolves it to `100.77.139.33` (Tailscale IP)
2. Request goes through Tailscale VPN
3. Traefik sees Tailscale IP ✅
4. Access granted!

---

### Option 3: Use Tailscale MagicDNS with Split DNS

**Enable MagicDNS in Tailscale:**

1. Go to Tailscale Admin Console: https://login.tailscale.com/admin/dns
2. Enable MagicDNS
3. Add DNS records:
   ```
   portainer  →  100.77.139.33
   grafana    →  100.77.139.33
   prometheus →  100.77.139.33
   ```
4. Access via:
   ```
   https://portainer.spangled-atlas.ts.net
   https://grafana.spangled-atlas.ts.net
   https://prometheus.spangled-atlas.ts.net
   ```

**BUT** - This requires updating Traefik to recognize these hostnames!

---

### Option 4: Remove VPN Requirement (EASIEST) ⭐

**Just use Authentik SSO** instead of VPN requirement:

```bash
# Run this script:
./scripts/remove-vpn-requirement.sh

# Then access normally:
https://portainer.securenexus.net (no VPN needed, but still requires SSO login)
```

**Benefits:**
- ✅ Access from anywhere (home, phone, coffee shop)
- ✅ Still secure (Authentik SSO login required)
- ✅ No client-side configuration needed
- ✅ Simpler to manage
- ✅ 2FA/MFA still works via Authentik

**Security:**
- Still protected by Authentik SSO
- Still uses HTTPS (SSL/TLS)
- CrowdSec still protects from attacks
- You can enable MFA in Authentik for extra security

---

## 🎯 My Recommendation

Since you already have **Authentik SSO** protecting all your services:

**Run this to make life easier:**
```bash
./scripts/remove-vpn-requirement.sh
```

This removes the VPN layer (which was redundant) and you still have:
- ✅ Authentik login requirement
- ✅ HTTPS encryption
- ✅ CrowdSec protection
- ✅ Can enable MFA in Authentik
- ✅ Access from anywhere

**The VPN layer was adding complexity without much security benefit** since Authentik SSO is already excellent protection.

---

## 🔐 If You Really Want to Keep VPN Protection

**Best approach: Use /etc/hosts override**

**On your laptop (when connected to Tailscale):**

1. Connect to Tailscale:
   ```bash
   tailscale up
   ```

2. Edit hosts file:
   ```bash
   sudo nano /etc/hosts
   ```

3. Add these lines:
   ```
   100.77.139.33   portainer.securenexus.net
   100.77.139.33   grafana.securenexus.net
   100.77.139.33   prometheus.securenexus.net
   ```

4. Save and exit

5. Now access normally in browser:
   ```
   https://portainer.securenexus.net
   https://grafana.securenexus.net
   ```

**This works because:**
- Your device resolves domain to Tailscale IP
- Traffic goes through VPN tunnel
- Traefik sees request from Tailscale IP ✅
- Host header matches ✅
- Access granted!

---

## 📱 Mobile Access

**For phones/tablets:**

1. **Option A**: Remove VPN requirement (recommended)
   - Run the script on server
   - Access normally via browser
   - Login with Authentik

2. **Option B**: Use Tailscale app + hosts file
   - Install Tailscale app
   - Use app like "Hosts Editor" (Android, requires root)
   - Add hosts entries
   - Access via browser

---

## ⚡ Quick Decision Guide

**Choose based on your needs:**

| Need | Solution | Effort |
|------|----------|--------|
| Access from anywhere easily | Remove VPN requirement | ⭐ Easy |
| Maximum security with VPN | /etc/hosts override | ⭐⭐ Medium |
| Keep everything as-is | Do nothing, use Tailscale IP | ⭐⭐⭐ Complex |

---

## 🚀 Let's Get You Access Right Now!

**What would you like me to do?**

1. **"Remove VPN"** - I'll run the script and you can access immediately
2. **"Setup hosts file"** - I'll show you exactly what to add for your OS
3. **"Both"** - Explain how to do /etc/hosts for when you want VPN, but also remove VPN requirement for easier access

What works best for you?
