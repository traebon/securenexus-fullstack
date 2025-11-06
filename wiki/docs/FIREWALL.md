# SecureNexus Firewall Configuration

## Current Firewall Status

- **UFW**: Installed but **NOT ACTIVE**
- **iptables**: Default Docker configuration (managed by Docker daemon)
- **Policy**: Default OUTPUT=ACCEPT (outbound traffic allowed)

## Required Inbound Ports

### Public Services (0.0.0.0)
| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| 22 | TCP | SSH | Server administration |
| 53 | TCP/UDP | DNS | CoreDNS authoritative nameserver |
| 80 | TCP | HTTP | Traefik (redirects to 443) |
| 443 | TCP | HTTPS | Traefik reverse proxy (all web services) |
| 587 | TCP | SMTP | Stalwart mail submission (VPN-restricted via middleware) |
| 853 | TCP | DNS-over-TLS | CoreDNS encrypted DNS |

### Admin/Monitoring Ports (should be VPN-only via Traefik middleware)
| Port | Service | Access Control |
|------|---------|----------------|
| 3001 | Uptime Kuma | Via Traefik + middleware |
| 8080 | Traefik Dashboard | Via Traefik + `admin-vpn` middleware |
| 8181 | Homepage Portal | Via Traefik + middleware |
| 9090 | Prometheus | Via Traefik + `admin-vpn` middleware |
| 9153 | CoreDNS Metrics | Internal only |

## Required Outbound Ports

### Critical for Operation
| Port | Protocol | Destination | Purpose |
|------|----------|-------------|---------|
| 443 | TCP | plugins.traefik.io | Traefik plugin downloads |
| 443 | TCP | acme-v02.api.letsencrypt.org | SSL certificate generation (Let's Encrypt) |
| 443 | TCP | github.com | Docker image pulls, updates |
| 443 | TCP | Various | Docker Hub, package managers |
| 53 | UDP | 8.8.8.8, 1.1.1.1 | DNS resolution |

### Optional Services
| Port | Destination | Purpose |
|------|-------------|---------|
| 443 | api.crowdsec.net | CrowdSec CAPI (if using standalone mode) |
| 443 | hub.docker.com | Docker image registry |

## Firewall Configuration Examples

### UFW (Uncomplicated Firewall)

```bash
# Enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (configure before enabling UFW!)
sudo ufw allow 22/tcp comment 'SSH'

# Allow DNS
sudo ufw allow 53/tcp comment 'DNS'
sudo ufw allow 53/udp comment 'DNS'
sudo ufw allow 853/tcp comment 'DNS-over-TLS'

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp comment 'HTTP (Traefik)'
sudo ufw allow 443/tcp comment 'HTTPS (Traefik)'

# Allow SMTP submission (note: further restricted by Traefik middleware)
sudo ufw allow 587/tcp comment 'SMTP Submission'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

### iptables (Advanced)

```bash
# Flush existing rules (CAUTION: will drop connections)
sudo iptables -F
sudo iptables -X

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow DNS
sudo iptables -A INPUT -p tcp --dport 53 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 853 -j ACCEPT

# Allow HTTP/HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow SMTP submission
sudo iptables -A INPUT -p tcp --dport 587 -j ACCEPT

# Save rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

## Docker Network Considerations

Docker automatically manages iptables rules for container networking:
- Creates `DOCKER` chain for container exposure
- Manages NAT for published ports
- Handles inter-container communication on bridge networks

**IMPORTANT**: Firewall rules should be applied to the **host**, not within containers. Docker bypasses UFW by default.

### Making UFW Work with Docker

Add to `/etc/ufw/after.rules` before the `*filter` section:

```
# Allow Docker containers to communicate
-A ufw-user-forward -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ufw-user-forward -i docker0 -o eth0 -j ACCEPT
-A ufw-user-forward -i docker0 -o docker0 -j ACCEPT
```

Or configure Docker to not modify iptables by adding to `/etc/docker/daemon.json`:

```json
{
  "iptables": false
}
```
⚠️ **Warning**: Disabling Docker's iptables management requires manual NAT rules for containers.

## Security Middleware Layers

SecureNexus uses Traefik middleware for application-level access control:

1. **admin-vpn@file**: IP allowlist (Headscale VPN 100.64.0.0/10)
2. **sso@file**: Authentik OIDC authentication (currently broken)
3. **secure-headers@file**: HTTP security headers
4. **submission-vpn@file**: SMTP submission restricted to VPN IPs

These middlewares provide defense-in-depth even if firewall rules are misconfigured.

## Current Network Access

```
Public Internet
      ↓
Firewall (ports 22, 53, 80, 443, 587, 853)
      ↓
Traefik (reverse proxy on ports 80/443)
      ↓
Middleware Chains (VPN, SSO, headers)
      ↓
Backend Services (Docker network 'proxy')
```

### Services Exposed via Traefik HTTPS (443)
- Landing page: `securenexus.net`
- Homepage portal: `portal.securenexus.net`
- Authentik SSO: `authentik.securenexus.net` (broken)
- Grafana: `grafana.securenexus.net` (VPN-only)
- Prometheus: `prometheus.securenexus.net` (VPN-only)
- Traefik Dashboard: `traefik.securenexus.net` (VPN-only)
- Headscale VPN: `vpn.securenexus.net` (VPN + SSO)
- Uptime Kuma: `status.securenexus.net`
- CoreDNS Admin: `dns.securenexus.net` (VPN-only)

## Known Issues

1. **Traefik Plugin Downloads Failing**
   - Error: `unable to download plugin github.com/darkweak/souin`
   - Network connectivity to plugins.traefik.io is working
   - Plugins temporarily disabled (souin cache, rewritebody, crowdsec bouncer)
   - May be API rate limiting or transient service issue

2. **No Active Firewall**
   - UFW is configured but not enabled
   - Relying on Docker's default iptables rules
   - **Recommendation**: Enable UFW with proper rules

3. **SMTP Port Exposure**
   - Port 587 is publicly accessible at network level
   - Middleware `submission-vpn@file` restricts to VPN IPs
   - Consider firewall-level restriction for defense-in-depth

## Recommendations

1. **Enable UFW** with configuration above
2. **Add Headscale VPN subnet to firewall** for admin ports
3. **Consider fail2ban** for SSH brute force protection
4. **Monitor Traefik logs** for suspicious access patterns
5. **Rotate secrets** periodically (postgres, redis, API keys)
6. **Fix CrowdSec integration** when plugin downloads work

## Testing Firewall Rules

```bash
# Test from external host
nc -zv your-server-ip 22   # Should succeed (SSH)
nc -zv your-server-ip 443  # Should succeed (HTTPS)
nc -zv your-server-ip 3306 # Should fail (MySQL)
nc -zv your-server-ip 5432 # Should fail (PostgreSQL)

# Test DNS
dig @your-server-ip securenexus.net
dig +tcp @your-server-ip securenexus.net

# Test HTTPS services
curl -I https://securenexus.net
curl -I https://status.securenexus.net
```

## Monitoring & Logging

### Traefik Access Logs
```bash
docker compose logs traefik -f
```

### Firewall Logs (UFW)
```bash
sudo tail -f /var/log/ufw.log
```

### Check Active Connections
```bash
ss -tulnp
netstat -tulnp | grep LISTEN
```

## Emergency Access Recovery

If locked out after enabling firewall:

1. **Physical/KVM access**: Login directly to console
2. **Cloud provider console**: Use web-based terminal
3. **Disable UFW**: `sudo ufw disable`
4. **Reset iptables**: `sudo iptables -F && sudo iptables -P INPUT ACCEPT`

Always test firewall changes with an **existing SSH session open** before logging out!
