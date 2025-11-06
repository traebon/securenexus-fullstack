# Headscale VPN Setup Guide

## Overview
Your Headscale VPN coordinator is running at `https://vpn.securenexus.net`

- **VPN Network:** 100.64.0.0/10 (CGNAT range)
- **Magic DNS:** Enabled at `mesh.securenexus.net`
- **User:** admin

## Client Installation

### Linux
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### macOS
```bash
brew install tailscale
```

### Windows
Download from: https://tailscale.com/download/windows

### iOS/Android
Install "Tailscale" from App Store / Play Store

## Connecting a Client

### Method 1: Using Pre-Auth Key (Easiest)

**Your Pre-Auth Key:** `9c8b4cb1e4b50bda5392ddf3a98ee0eeb050c7ef4594a332`
- Expires: 24 hours from creation (2025-10-03 05:39:39 UTC)
- Reusable: Yes

1. On your client device, connect using:
```bash
sudo tailscale up --login-server https://vpn.securenexus.net --authkey 9c8b4cb1e4b50bda5392ddf3a98ee0eeb050c7ef4594a332
```

### Method 2: Manual Registration

1. Start Tailscale and point to your Headscale server:
```bash
sudo tailscale up --login-server https://vpn.securenexus.net
```

2. Copy the registration URL shown

3. On the Headscale server, register the node:
```bash
docker compose exec headscale headscale nodes register --user admin --key MACHINE_KEY
```

## Managing Your VPN

### List Connected Nodes
```bash
docker compose exec headscale headscale nodes list
```

### Create New Pre-Auth Key
```bash
docker compose exec headscale headscale preauthkeys create --user admin --reusable --expiration 24h
```

### List Pre-Auth Keys
```bash
docker compose exec headscale headscale preauthkeys list --user admin
```

### Delete a Node
```bash
docker compose exec headscale headscale nodes delete --identifier NODE_ID
```

### Create Additional Users
```bash
docker compose exec headscale headscale users create USERNAME
```

## Access Control

Edit `/home/tristian/securenexus-fullstack/headscale/acl.hujson` to control which nodes can access each other.

Current policy: All nodes in the same user can communicate with each other.

## VPN-Only Services

The following services are only accessible via Headscale VPN:

- **Grafana:** https://grafana.securenexus.net
- **Prometheus:** https://prometheus.securenexus.net
- **Alertmanager:** https://alerts.securenexus.net
- **Headscale Admin:** https://vpn.securenexus.net

These use the `admin-vpn` middleware which only allows IPs from `100.64.0.0/10`.

## Troubleshooting

### Check Headscale Logs
```bash
docker compose logs headscale --tail 50
```

### Check Client Status
```bash
sudo tailscale status
```

### Test Connectivity
```bash
ping 100.64.0.1  # Should ping the Headscale server's VPN IP
```

### Verify VPN IP Range
```bash
ip addr show tailscale0  # Linux
ifconfig utun3           # macOS
```

## Security Notes

- Pre-auth keys expire after 24 hours by default
- Use `--reusable false` for one-time keys
- VPN traffic uses WireGuard protocol (encrypted)
- DERP relay servers from Tailscale used for NAT traversal
