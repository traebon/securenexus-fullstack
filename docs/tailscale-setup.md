# Tailscale VPN Client Setup

## Your Connection Details
- **Pre-auth Key**: `f716c416017f206642b4c641deeb5fe37f53da75c5b77a9b`
- **Headscale Server**: `https://vpn.securenexus.net`

## TODO(human): Choose Your Installation Method

### Option A: Install on This Linux Server (Recommended)
```bash
# Install Tailscale (requires sudo)
curl -fsSL https://tailscale.com/install.sh | sudo sh

# Connect to your Headscale server
sudo tailscale up --login-server=https://vpn.securenexus.net --authkey=f716c416017f206642b4c641deeb5fe37f53da75c5b77a9b

# Check connection status
tailscale status
```

### Option B: Install on Your Local Machine
#### Windows:
1. Download from https://tailscale.com/download/windows
2. Install and open Tailscale
3. Go to Settings → General → Custom Login Server
4. Set: `https://vpn.securenexus.net`
5. Use auth key: `f716c416017f206642b4c641deeb5fe37f53da75c5b77a9b`

#### macOS:
1. Download from https://tailscale.com/download/mac
2. Install and open Tailscale
3. In menu bar → Preferences → General → Custom Login Server
4. Set: `https://vpn.securenexus.net`
5. Use auth key: `f716c416017f206642b4c641deeb5fe37f53da75c5b77a9b`

### Option C: Alternative Testing (No Tailscale needed)
If you can't install Tailscale right now, you can:
1. Add to `/etc/hosts`: `127.0.0.1 grafana.securenexus.net prometheus.securenexus.net`
2. Access services locally (they'll work but show certificate warnings)

## After Connection
Once connected, you'll be able to access:
- **Grafana**: https://grafana.securenexus.net (VPN-only)
- **Prometheus**: https://prometheus.securenexus.net (VPN-only)
- **Traefik Dashboard**: https://traefik.securenexus.net (VPN-only)

## Verification Steps
1. Check if you get a VPN IP: `ip addr show tailscale0`
2. Test connectivity: `ping 100.64.0.1` (Headscale server IP)
3. Access admin services via browser