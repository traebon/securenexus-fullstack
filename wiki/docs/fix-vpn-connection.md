# Fix VPN Connection Issues

## Problem
Tailscale is hanging when connecting because it can't resolve `vpn.securenexus.net`

## TODO(human): Choose a solution:

### Solution A: Local DNS Fix (Quickest)
```bash
# Add domain to hosts file
echo "127.0.0.1 vpn.securenexus.net" | sudo tee -a /etc/hosts

# Verify it resolves
ping -c 1 vpn.securenexus.net

# Try Tailscale connection again
sudo tailscale up --login-server=https://vpn.securenexus.net --authkey=f716c416017f206642b4c641deeb5fe37f53da75c5b77a9b
```

### Solution B: Use HTTP Instead (Alternative)
If HTTPS doesn't work, we can temporarily use HTTP:

```bash
# Try HTTP connection
sudo tailscale up --login-server=http://localhost:8080 --authkey=f716c416017f206642b4c641deeb5fe37f53da75c5b77a9b
```

### Solution C: Debug Connection
Check what's happening:

```bash
# Test DNS resolution
nslookup vpn.securenexus.net

# Test HTTPS connectivity
curl -k -v https://vpn.securenexus.net 2>&1 | head -20

# Check if Tailscale can see the server
sudo tailscale up --login-server=https://vpn.securenexus.net --authkey=f716c416017f206642b4c641deeb5fe37f53da75c5b77a9b --verbose
```

## After Connection Works
Once connected, verify with:
```bash
# Check Tailscale status
tailscale status

# Check your VPN IP
ip addr show tailscale0

# Test connection to server
./test-vpn-connection.sh
```

## If Still Stuck
Let me know:
1. Which solution you tried
2. Any error messages you see
3. Output of `tailscale status`