# Authentik Time Synchronization Warning - Resolution Guide

**Warning**: "Server and client are further than 5 seconds apart"

## Current Status

✅ **Host server time**: Synchronized via systemd-timesyncd
✅ **NTP service**: Active and running
✅ **Container time**: Matches host (both in UTC)
✅ **Time source**: ntp.ubuntu.com

**Diagnosis**: Server time is correct. The warning is likely caused by **client/browser time** being incorrect.

---

## Solution 1: Check Your Client Device Time (Most Common)

The "client" in the warning refers to **your device** (PC, phone, tablet) accessing Authentik, not the server.

### Windows
1. Right-click clock in taskbar → "Adjust date/time"
2. Enable "Set time automatically"
3. Enable "Set time zone automatically"
4. Click "Sync now" under "Synchronize your clock"

### Mac
1. System Preferences → Date & Time
2. Enable "Set date and time automatically"
3. Select closest time server or use default

### Linux
```bash
# Check current time
timedatectl status

# Enable NTP sync
sudo timedatectl set-ntp true

# Force immediate sync
sudo systemctl restart systemd-timesyncd
```

### Android
1. Settings → Date & time
2. Enable "Automatic date & time"
3. Enable "Automatic time zone"

### iOS
1. Settings → General → Date & Time
2. Enable "Set Automatically"

---

## Solution 2: Clear Browser Cache

Sometimes the warning persists in cache even after time is synced:

1. Hard refresh Authentik page: `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)
2. Or clear browser cache completely
3. Log out and log back into Authentik

---

## Solution 3: Verify Server Time (Already Done ✅)

Your server is already correctly configured:

```bash
# Current configuration
System clock synchronized: yes
NTP service: active
Time zone: UTC
Time source: ntp.ubuntu.com

# Both host and containers show same time
Host:      Tue Oct  7 08:11:10 UTC 2025
Container: Tue Oct  7 08:11:10 UTC 2025
```

---

## Solution 4: Force Server Time Resync (If Needed)

If server time drift occurs in future:

```bash
# Check NTP sync status
timedatectl status

# Restart time sync service
sudo systemctl restart systemd-timesyncd

# Force immediate sync
sudo timedatectl set-ntp false
sudo timedatectl set-ntp true

# Verify sync
timedatectl timesync-status
```

---

## Solution 5: Restart Authentik (If Warning Persists)

If warning continues after fixing client time:

```bash
# Restart Authentik services
docker compose restart authentik_server authentik_worker

# Or just the server
docker compose restart authentik_server
```

---

## Why This Matters

Time synchronization is critical for:
- **OIDC/OAuth tokens**: Have expiration timestamps
- **Session management**: Session cookies expire at specific times
- **TOTP/MFA**: Time-based one-time passwords
- **SAML assertions**: Timestamped security tokens
- **Audit logs**: Accurate event timestamps

**Tolerance**: Most systems allow ±5 seconds. Beyond that, authentication fails.

---

## Verify Fix

After applying solutions:

1. Check your device time matches: https://time.is/
2. Refresh Authentik admin interface
3. Check System → System Tasks → Status
4. Warning should disappear if time is within 5 seconds

---

## Prevention

### Client Side
- Keep automatic time sync enabled on all devices
- Use reliable NTP servers
- Check time after system sleep/hibernate

### Server Side (Already Configured ✅)
Your server already has:
- systemd-timesyncd active and running
- NTP synchronization enabled
- UTC timezone configured
- Multiple NTP servers configured

---

## Advanced: Check Time Drift

To monitor for time drift issues:

```bash
# Check NTP sync details
timedatectl timesync-status

# See NTP server responses
journalctl -u systemd-timesyncd | tail -20

# Compare with authoritative time
curl -s http://worldtimeapi.org/api/timezone/Etc/UTC | grep datetime
```

---

## Troubleshooting

### If Warning Persists After All Steps

1. **Check from different device**: Access Authentik from another device to isolate issue
2. **Check from different network**: Use mobile data vs WiFi to rule out network time issues
3. **Verify container timezone**:
   ```bash
   docker compose exec -T authentik_server cat /etc/timezone
   # Should show: UTC or Etc/UTC
   ```
4. **Check Docker daemon time**:
   ```bash
   docker info | grep -i time
   ```

### Container Time Issues (Rare)

If containers have wrong time:

```bash
# Restart Docker daemon (containers inherit host time)
sudo systemctl restart docker

# Recreate containers to inherit fresh time
docker compose down
docker compose up -d
```

---

## Expected Result

✅ After fixing client time and clearing cache:
- Warning disappears from Authentik System Status
- All authentication flows work normally
- Session management functions correctly
- TOTP/MFA codes validate properly

---

## Quick Fix Summary

**Most likely cause**: Your PC/phone time is incorrect

**Quick fix**:
1. Enable automatic time sync on your device
2. Hard refresh Authentik page (Ctrl+Shift+R)
3. Warning should disappear

**If persists**: Restart Authentik with `docker compose restart authentik_server`

---

**Last Updated**: 2025-10-07
**Server Status**: ✅ Time sync working correctly
**Action Required**: Check client device time settings
