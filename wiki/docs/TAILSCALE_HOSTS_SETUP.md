# Tailscale VPN Access - Hosts File Setup

**Tailnet**: `spangled-atlas.ts.net`
**Server**: `neverland.spangled-atlas.ts.net`
**Tailscale IP**: `100.77.139.33`

## Quick Setup Guide

To access VPN-protected services (Portainer, Grafana, Prometheus), you need to configure your client device to route requests through Tailscale.

---

## 🐧 Linux (Ubuntu/Debian/Fedora/etc.)

**Step 1: Connect to Tailscale**
```bash
tailscale up
tailscale status  # Verify connection
```

**Step 2: Edit hosts file**
```bash
sudo nano /etc/hosts
```

**Step 3: Add these lines at the END of the file**
```bash
# SecureNexus VPN Access (Tailscale: spangled-atlas.ts.net)
100.77.139.33   portainer.securenexus.net
100.77.139.33   grafana.securenexus.net
100.77.139.33   prometheus.securenexus.net
100.77.139.33   traefik.securenexus.net
```

**Step 4: Save and exit**
- Press `Ctrl+O` (save)
- Press `Enter` (confirm)
- Press `Ctrl+X` (exit)

**Step 5: Verify**
```bash
ping portainer.securenexus.net
# Should show: 100.77.139.33

# Access in browser:
https://portainer.securenexus.net
```

---

## 🍎 macOS

**Step 1: Connect to Tailscale**
```bash
# Tailscale should be running in menu bar
# Click icon → Ensure connected
```

**Step 2: Edit hosts file**
```bash
sudo nano /etc/hosts
```

**Step 3: Add these lines at the END**
```bash
# SecureNexus VPN Access (Tailscale: spangled-atlas.ts.net)
100.77.139.33   portainer.securenexus.net
100.77.139.33   grafana.securenexus.net
100.77.139.33   prometheus.securenexus.net
100.77.139.33   traefik.securenexus.net
```

**Step 4: Save and exit**
- Press `Ctrl+O` → `Enter` → `Ctrl+X`

**Step 5: Flush DNS cache**
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

**Step 6: Verify**
```bash
ping portainer.securenexus.net
# Should show: 100.77.139.33

# Open browser:
https://portainer.securenexus.net
```

---

## 🪟 Windows 10/11

**Step 1: Open Notepad as Administrator**

**Method A (Quick):**
1. Press `Windows` key
2. Type: `notepad`
3. Right-click "Notepad"
4. Click "Run as administrator"
5. Click "Yes" when prompted

**Method B (Start Menu):**
1. Click Start
2. Search "Notepad"
3. Right-click
4. Select "Run as administrator"

**Step 2: Open hosts file**
1. In Notepad: `File` → `Open`
2. Navigate to: `C:\Windows\System32\drivers\etc\`
3. Change file filter from "Text Documents (*.txt)" to **"All Files (*.*)"**
4. Select the file named: `hosts`
5. Click `Open`

**Step 3: Add these lines at the END of the file**
```
# SecureNexus VPN Access (Tailscale: spangled-atlas.ts.net)
100.77.139.33   portainer.securenexus.net
100.77.139.33   grafana.securenexus.net
100.77.139.33   prometheus.securenexus.net
100.77.139.33   traefik.securenexus.net
```

**Step 4: Save the file**
1. `File` → `Save`
2. Close Notepad

**Step 5: Flush DNS cache**

Open **Command Prompt** (no admin needed):
```cmd
ipconfig /flushdns
```

**Step 6: Verify**

Open **Command Prompt**:
```cmd
ping portainer.securenexus.net
```
Should show: `Pinging portainer.securenexus.net [100.77.139.33]`

**Step 7: Access in browser**
```
https://portainer.securenexus.net
```

---

## 📱 Android

**Requirements**: Rooted device or specific apps

**Method 1: Hosts Editor (Requires Root)**

1. Install "Hosts Editor" from Google Play Store
2. Open app and grant root permissions
3. Tap "+" to add new entry
4. Add each entry:
   ```
   100.77.139.33   portainer.securenexus.net
   100.77.139.33   grafana.securenexus.net
   100.77.139.33   prometheus.securenexus.net
   ```
5. Tap "Save"
6. Enable hosts file

**Method 2: AdAway (Requires Root)**
1. Install AdAway
2. Go to "Hosts sources"
3. Add custom hosts entries
4. Apply

**Method 3: Remove VPN Requirement (No Root Needed)**

**Better option for mobile**: Just remove the VPN requirement on the server:
```bash
# Run on server:
./scripts/remove-vpn-requirement.sh
```

Then access normally from Android browser without any hosts file changes.

---

## 🍎 iOS/iPadOS

**iOS does not support hosts file editing** unless jailbroken.

**Recommended Solution**: Remove VPN requirement on server

```bash
# Run on server:
./scripts/remove-vpn-requirement.sh
```

Then access services normally via Safari or any browser. Still protected by Authentik SSO!

---

## ✅ Verification Steps

After editing your hosts file, verify it's working:

**1. Test DNS Resolution**
```bash
# Linux/Mac:
ping portainer.securenexus.net

# Windows:
ping portainer.securenexus.net
```
Expected output: `100.77.139.33`

**2. Test Tailscale Connectivity**
```bash
tailscale ping neverland
```
Expected: Successful pongs from `100.77.139.33`

**3. Test HTTP Access**
```bash
# Linux/Mac:
curl -k https://portainer.securenexus.net | head -20

# Windows PowerShell:
Invoke-WebRequest -Uri https://portainer.securenexus.net -SkipCertificateCheck
```
Expected: HTML content (not "403 Forbidden")

**4. Test in Browser**
Open browser and visit:
- https://portainer.securenexus.net
- https://grafana.securenexus.net
- https://prometheus.securenexus.net

Expected: Login page (may show certificate warning - this is normal)

---

## 🔒 About Certificate Warnings

**Why do I see certificate warnings?**

The SSL certificate is issued for the public domain `securenexus.net`, not for the Tailscale IP `100.77.139.33`.

**How to proceed:**

**Chrome/Edge:**
1. Click "Advanced"
2. Click "Proceed to portainer.securenexus.net (unsafe)"

**Firefox:**
1. Click "Advanced"
2. Click "Accept the Risk and Continue"

**Safari:**
1. Click "Show Details"
2. Click "visit this website"

**This is safe** because:
- ✅ You're on your private VPN (Tailscale)
- ✅ Traffic is encrypted by Tailscale
- ✅ You trust your own server
- ✅ Still protected by Authentik SSO

---

## 🎯 Complete Example Hosts File

**Linux/Mac** (`/etc/hosts`):
```bash
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost

# SecureNexus VPN Access (Tailscale: spangled-atlas.ts.net)
100.77.139.33   portainer.securenexus.net
100.77.139.33   grafana.securenexus.net
100.77.139.33   prometheus.securenexus.net
100.77.139.33   traefik.securenexus.net
```

**Windows** (`C:\Windows\System32\drivers\etc\hosts`):
```
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#

127.0.0.1       localhost
::1             localhost

# SecureNexus VPN Access (Tailscale: spangled-atlas.ts.net)
100.77.139.33   portainer.securenexus.net
100.77.139.33   grafana.securenexus.net
100.77.139.33   prometheus.securenexus.net
100.77.139.33   traefik.securenexus.net
```

---

## 🛠️ Troubleshooting

### Problem: Still getting "403 Forbidden"

**Solution 1: Verify hosts file is loaded**
```bash
# Check DNS resolution
ping portainer.securenexus.net

# Should show: 100.77.139.33
# If it shows different IP, hosts file not working
```

**Solution 2: Reload DNS**
```bash
# Linux:
sudo systemd-resolve --flush-caches

# Mac:
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Windows:
ipconfig /flushdns
```

**Solution 3: Restart browser**

Close and reopen your browser completely.

**Solution 4: Check Tailscale connection**
```bash
tailscale status
# Ensure you're connected and see neverland
```

### Problem: "DNS_PROBE_FINISHED_NXDOMAIN"

**Cause**: Hosts file not loaded or syntax error

**Solution**:
1. Check hosts file syntax (no typos)
2. Ensure no extra spaces or tabs
3. Save file properly
4. Flush DNS cache
5. Restart browser

### Problem: "Connection refused"

**Cause**: Traefik or Portainer not running

**Solution**:
```bash
# On server:
docker compose ps portainer grafana prometheus

# Restart if needed:
docker compose up -d portainer grafana prometheus
```

### Problem: Certificate warnings every time

**This is normal** when accessing via Tailscale IP!

**To avoid warnings** (advanced):
1. Set up Tailscale HTTPS
2. Or use `--ssl-cert` option with custom cert
3. Or remove VPN requirement and access normally

---

## 🔄 To Remove Hosts File Entries Later

If you decide to remove VPN requirement on server, you can remove these entries:

**Linux/Mac:**
```bash
sudo nano /etc/hosts
# Delete the 4 lines starting with 100.77.139.33
# Save and exit
```

**Windows:**
```
# Run Notepad as administrator
# Open: C:\Windows\System32\drivers\etc\hosts
# Delete the 4 lines starting with 100.77.139.33
# Save
```

---

## 🎉 Success!

Once hosts file is configured, you can access:

- **Portainer**: https://portainer.securenexus.net
- **Grafana**: https://grafana.securenexus.net
- **Prometheus**: https://prometheus.securenexus.net
- **Traefik Dashboard**: https://traefik.securenexus.net

All through your secure Tailscale VPN tunnel! 🔐

---

**Need help?** See troubleshooting section above or run the alternative script to remove VPN requirement:
```bash
./scripts/remove-vpn-requirement.sh
```
