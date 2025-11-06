# PC Access Fix - Windows Hosts File Solution

## Problem

Your PC can't resolve `*.tail02904e.ts.net` hostnames because Tailscale MagicDNS isn't configured on the client side.

**Server Tailscale IP:** `100.77.139.33`

---

## ✅ Solution: Edit Hosts File on Your PC

### For Windows PC:

#### Step 1: Open Notepad as Administrator

1. Press `Windows + S` (search)
2. Type: `notepad`
3. Right-click on Notepad
4. Select **"Run as administrator"**

#### Step 2: Open Hosts File

1. In Notepad: `File` → `Open`
2. Navigate to: `C:\Windows\System32\drivers\etc`
3. Change file filter from "Text Documents (*.txt)" to **"All Files (*.*)"**
4. Open the file named: `hosts` (no extension)

#### Step 3: Add These Lines

Add to the bottom of the file:

```
# Tailscale SecureNexus Admin Services
100.77.139.33  grafana.securenexus.net
100.77.139.33  prometheus.securenexus.net
100.77.139.33  traefik.securenexus.net
100.77.139.33  alerts.securenexus.net
```

#### Step 4: Save and Close

1. `File` → `Save`
2. Close Notepad

#### Step 5: Test Access

Open browser to:
- `https://grafana.securenexus.net`
- `https://prometheus.securenexus.net`
- `https://traefik.securenexus.net`
- `https://alerts.securenexus.net`

**Expected:** Should work now! ✅

---

## How This Works

1. **Before:** `grafana.securenexus.net` → DNS → `137.74.40.208` → Internet route → 403
2. **After:** `grafana.securenexus.net` → Hosts file → `100.77.139.33` → Tailscale VPN route → ✅ Works!

The hosts file overrides DNS and forces your PC to use the Tailscale IP address, which routes traffic through the VPN tunnel where Traefik can see your Tailscale IP (100.x.x.x).

---

## Alternative: Enable Tailscale MagicDNS on PC

If you prefer not to edit hosts file:

### Step 1: Check Tailscale Settings on PC

1. Open Tailscale on your PC
2. Click the Tailscale icon → `Settings` or `Preferences`
3. Look for **"Use Tailscale DNS"** or **"MagicDNS"**
4. Enable it if disabled

### Step 2: Configure DNS

1. In Tailscale admin console (https://login.tailscale.com)
2. Go to `DNS` settings
3. Enable **"MagicDNS"**
4. Ensure **"Override local DNS"** is enabled

### Step 3: Restart Tailscale on PC

Then the `*.tail02904e.ts.net` hostnames should resolve.

---

## Verification Commands

### On Your PC (Windows PowerShell):

```powershell
# Test if hosts file is working
ping grafana.securenexus.net
# Should show: Pinging grafana.securenexus.net [100.77.139.33]

# Test HTTPS access
curl -I https://grafana.securenexus.net
# Should return: 200 OK (not 403)
```

### Check Tailscale Connection

```powershell
tailscale status
# Should show:
# 100.77.139.33   vps-09e1118a
# 100.91.127.102  pc-main  (you)
```

---

## Troubleshooting

### "Still getting 403"

**Cause:** Hosts file not saved correctly or DNS cache

**Fix:**
```powershell
# Flush DNS cache (Windows)
ipconfig /flushdns

# Restart browser
# Try again
```

### "Certificate warning"

**Cause:** Expected - certificate is valid

**Fix:**
- Click "Advanced" → "Proceed to grafana.securenexus.net (unsafe)"
- This is safe because you're accessing via Tailscale VPN
- The certificate IS valid for securenexus.net (it's the IP that's different)

### "Connection refused"

**Cause:** Tailscale not connected

**Fix:**
```powershell
# Check Tailscale status
tailscale status

# If not connected, reconnect:
tailscale up
```

---

## Rollback Instructions

If you want to undo the hosts file changes:

1. Open Notepad as Administrator
2. Open `C:\Windows\System32\drivers\etc\hosts`
3. Remove the lines you added (starting with 100.77.139.33)
4. Save and close

---

## Summary

**Quickest Solution:** Edit Windows hosts file
```
100.77.139.33  grafana.securenexus.net
100.77.139.33  prometheus.securenexus.net
100.77.139.33  traefik.securenexus.net
100.77.139.33  alerts.securenexus.net
```

**Then access:** `https://grafana.securenexus.net` (should work!)

---

**This fix:**
- ✅ Uses Tailscale VPN tunnel
- ✅ Traefik sees your Tailscale IP (100.x.x.x)
- ✅ admin-vpn middleware allows access
- ✅ Encrypted end-to-end
- ✅ No server changes needed
