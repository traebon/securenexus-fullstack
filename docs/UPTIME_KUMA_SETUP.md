# Uptime Kuma Monitoring Setup

**Access URL**: https://status.securenexus.net

## Initial Setup

If this is your first time accessing Uptime Kuma, you'll be prompted to create an admin account.

**Recommended credentials:**
- Username: `admin`
- Password: (use a strong password from `openssl rand -base64 32`)

## Monitoring Configuration

### Core Infrastructure Monitors

Add these monitors to track all your critical services:

#### 1. **Web Services (HTTPS)**

| Monitor Name | Type | URL | Interval |
|-------------|------|-----|----------|
| Landing Page | HTTP(s) | https://securenexus.net | 60s |
| Homepage Portal | HTTP(s) | https://portal.securenexus.net | 60s |
| Authentik SSO | HTTP(s) | https://auth.securenexus.net | 60s |
| Mailcow Webmail | HTTP(s) | https://mail.securenexus.net | 60s |
| Traefik Dashboard | HTTP(s) | https://traefik.securenexus.net | 120s |
| Grafana | HTTP(s) | https://grafana.securenexus.net | 120s |
| Prometheus | HTTP(s) | https://prometheus.securenexus.net | 120s |

**Settings for HTTPS monitors:**
- Method: GET
- Max Redirects: 10
- Valid Status Codes: 200-299
- Check Certificate: ✅ Enabled
- Ignore TLS/SSL errors: ❌ Disabled

#### 2. **DNS Services**

| Monitor Name | Type | Hostname | Server | Port |
|-------------|------|----------|--------|------|
| CoreDNS | DNS | securenexus.net | 137.74.40.208 | 53 |
| CoreDNS (DoT) | Port | - | 137.74.40.208 | 853 |

**Settings for DNS monitor:**
- Resolver Server: 137.74.40.208
- Record Type: A
- Expected Answer: 137.74.40.208

#### 3. **Mail Services**

| Monitor Name | Type | Host | Port | Description |
|-------------|------|------|------|-------------|
| SMTP | Port | mail.securenexus.net | 587 | Outbound mail |
| SMTPS | Port | mail.securenexus.net | 465 | Secure SMTP |
| IMAP | Port | mail.securenexus.net | 993 | Email access |
| POP3 | Port | mail.securenexus.net | 995 | Email access |

**Settings for Port monitors:**
- Interval: 120s
- Retry: 2 times
- Heartbeat Retry: 1

#### 4. **Docker & System**

| Monitor Name | Type | Docker Container | Expected Status |
|-------------|------|------------------|-----------------|
| Traefik Container | Docker | traefik | running |
| Authentik Server | Docker | authentik_server | running |
| Mailcow Postfix | Docker | mailcowdockerized-postfix-mailcow-1 | running |
| Prometheus | Docker | prometheus | running |
| Grafana | Docker | grafana | running |

**Settings for Docker monitors:**
- Docker Host: unix:///var/run/docker.sock
- Container: (select from list)

#### 5. **SSL Certificate Expiry**

| Monitor Name | Type | URL | Alert Before |
|-------------|------|-----|--------------|
| Main Domain SSL | HTTP(s) - Certificate Expiry | https://securenexus.net | 14 days |
| Mail SSL | HTTP(s) - Certificate Expiry | https://mail.securenexus.net | 14 days |
| Auth SSL | HTTP(s) - Certificate Expiry | https://auth.securenexus.net | 14 days |

#### 6. **Prometheus Integration**

Monitor Name: **Prometheus Metrics**
- Type: Prometheus
- Push URL: (will be shown in Uptime Kuma after creation)
- Interval: 60s

Add this to `monitoring/prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'uptime-kuma'
    static_configs:
      - targets: ['uptime-kuma:3001']
```

## Notification Channels

### Email Notifications (via Mailcow)

**Settings → Notifications → Add**
- Type: SMTP
- Friendly Name: Mailcow SMTP
- SMTP Host: mail.securenexus.net
- Port: 587
- Security: STARTTLS
- Username: smtp-user@securenexus.net
- Password: (from `secrets/smtp_password.txt`)
- From Email: alerts@securenexus.net
- To Email: admin@securenexus.net

### Discord Webhook (Optional)

**Settings → Notifications → Add**
- Type: Discord
- Friendly Name: Discord Alerts
- Discord Webhook URL: (your webhook URL)
- Message: `[{status}] {monitor-name} is {msg}`

### Slack (Optional)

**Settings → Notifications → Add**
- Type: Slack
- Friendly Name: Slack Alerts
- Webhook URL: (your webhook URL)

## Status Pages

Create a public status page for your services:

**Settings → Status Pages → Add**
- Name: SecureNexus Services
- Slug: services
- Theme: Auto
- Public: ✅ Enabled

**Add monitors to status page:**
- Landing Page
- Homepage Portal
- Mailcow Webmail
- DNS Service

**Access**: https://status.securenexus.net/status/services

## Monitoring Groups

Organize monitors into logical groups:

### Group 1: Public Services
- Landing Page
- Homepage Portal
- Mailcow Webmail
- DNS

### Group 2: Admin Services (VPN)
- Traefik Dashboard
- Grafana
- Prometheus
- Authentik

### Group 3: Infrastructure
- CoreDNS
- Docker Containers
- SSL Certificates

### Group 4: Mail Stack
- SMTP
- IMAP
- POP3
- Mail Web UI

## Alert Rules

Configure alerts for different severity levels:

### Critical (Immediate notification)
- Any public web service down > 2 minutes
- Mail services down > 5 minutes
- DNS service down > 2 minutes
- SSL certificate expires < 7 days

### Warning (Notification after delay)
- Admin services down > 5 minutes
- SSL certificate expires < 14 days
- Container restarts detected

### Info (Daily summary)
- Uptime statistics
- Performance metrics
- Certificate expiry dates

## Maintenance Mode

When performing maintenance:
1. Go to monitor → Edit
2. Enable "Maintenance Mode"
3. Set duration
4. Notifications will be paused

## Quick Setup Commands

```bash
# Get SMTP password for notifications
cat secrets/smtp_password.txt

# Check Uptime Kuma logs
docker compose logs -f uptime-kuma

# Restart Uptime Kuma
docker compose restart uptime-kuma

# Backup Uptime Kuma database
docker cp securenexus-fullstack-uptime-kuma-1:/app/data/kuma.db ./backups/kuma-$(date +%Y%m%d).db

# Restore Uptime Kuma database
docker cp ./backups/kuma-backup.db securenexus-fullstack-uptime-kuma-1:/app/data/kuma.db
docker compose restart uptime-kuma
```

## Integration with Grafana

You can display Uptime Kuma metrics in Grafana:

1. **Install JSON API datasource** in Grafana
2. **Add datasource**: http://uptime-kuma:3001/metrics
3. **Import dashboard**: Use community dashboard ID for Uptime Kuma

## Best Practices

1. **Monitor spacing**: Don't check too frequently (60-120s is good)
2. **Retries**: Enable 2-3 retries to avoid false positives
3. **Grouping**: Organize monitors by service category
4. **Status page**: Create public status page for transparency
5. **Notifications**: Configure multiple channels for redundancy
6. **Maintenance**: Use maintenance mode during planned downtime
7. **Backups**: Backup kuma.db weekly (included in backup-all.sh)

## Troubleshooting

### Monitor shows "DOWN" but service is working
- Check network connectivity from Uptime Kuma container
- Verify monitor configuration (URL, port, etc.)
- Check for firewall rules blocking checks
- Review Uptime Kuma logs

### Notifications not sending
- Test notification channel in Settings
- Check SMTP credentials
- Verify email server logs: `docker compose -f mail/mailcow-dockerized/docker-compose.yml logs postfix-mailcow`

### High memory usage
- Reduce monitoring frequency
- Limit number of monitors
- Clean up old heartbeat data (Settings → Maintenance)

## API Access

Uptime Kuma has a REST API for automation:

```bash
# Get monitors
curl -H "Authorization: Bearer YOUR_API_KEY" https://status.securenexus.net/api/monitors

# Add monitor via API
curl -X POST -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"type":"http","name":"Test","url":"https://example.com"}' \
     https://status.securenexus.net/api/monitors
```

Generate API key in Settings → Security.

## Security Recommendations

1. **Strong admin password**: Use `openssl rand -base64 32`
2. **Enable 2FA**: Settings → Security → Two-Factor Authentication
3. **Limit login attempts**: Enabled by default
4. **Regular backups**: Database backed up daily
5. **Monitor login activity**: Check Settings → Security Logs

## Next Steps

1. Access https://status.securenexus.net
2. Create admin account (if first time)
3. Add monitors for all services (see tables above)
4. Configure email notifications via Mailcow
5. Create public status page
6. Test notifications with "Test" button
7. Enable maintenance mode before system updates

---

**Last Updated**: October 7, 2025
**Status**: Ready for configuration
