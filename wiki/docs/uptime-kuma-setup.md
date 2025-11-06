# Uptime Kuma Setup Guide

## Access

Once DNS propagation completes, access Uptime Kuma at:
**https://status.securenexus.net**

## Initial Setup

1. **Create Admin Account**: First visit will prompt for admin user creation
2. **Configure Settings**: Set timezone, language preferences

## Recommended Monitors

### Core Infrastructure
- **DNS Server**: `securenexus.net` (DNS query)
- **Main Website**: `https://securenexus.net` (HTTP)
- **Authentik**: `https://authentik.securenexus.net` (HTTP)
- **Grafana**: `https://grafana.securenexus.net` (HTTP)

### Internal Services (HTTP checks)
- **Traefik Dashboard**: `https://traefik.securenexus.net`
- **CoreDNS Health**: `http://coredns:8080/health` (if internal)
- **Prometheus**: `https://prometheus.securenexus.net`

### Advanced Monitors
- **Port Checks**: SMTP (587), DNS (53), HTTPS (443)
- **Keyword Monitoring**: Check for specific text on pages
- **Certificate Expiry**: Monitor SSL certificate validity

## Notification Setup

### Recommended Notification Channels
1. **Email**: For critical alerts
2. **Discord/Slack**: For team notifications
3. **Webhook**: Integration with existing systems

### Alert Policies
- **DNS Failure**: Immediate alert (0 minute delay)
- **HTTP Services**: 2-3 failures before alert (2-3 minutes)
- **Certificate Expiry**: 30 days warning, 7 days critical

## Status Page

Create a public status page for:
- Main services (website, auth, DNS)
- Incident history
- Maintenance schedules

## Integration with Existing Monitoring

Uptime Kuma complements your Prometheus/Grafana setup:
- **Uptime Kuma**: User-friendly status pages, external monitoring
- **Prometheus/Grafana**: Detailed metrics, internal monitoring, alerting

## Maintenance

- **Backups**: Data stored in Docker volume `uptime-kuma-data`
- **Updates**: Recreate container with latest image
- **Monitoring**: Watch container health via existing monitoring

## DNS Propagation Tracking

Create a specific monitor for `securenexus.net` DNS resolution to track when global propagation completes!