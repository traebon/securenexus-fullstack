# CoreDNS Migration from PowerDNS

## Summary of Changes

This document outlines the migration from PowerDNS to CoreDNS with all requested plugins enabled.

### What Changed

1. **Removed PowerDNS Stack**:
   - Removed: pdns-db, pdns, pdns_admin, pdns_exporter, dns_sync services
   - Removed volumes: pdns-db, pda-db
   - Removed secrets: pdns_db_password, pda_db_password, pdns_api_key, pda_secret_key, pda_oidc_secret

2. **Added CoreDNS Stack**:
   - **CoreDNS**: Modern, plugin-based DNS server
   - **etcd**: Distributed key-value store for dynamic DNS records
   - **MySQL**: Database backend for manually managed zones
   - **dns-updater**: Automatic DNS record creation based on container labels
   - **etcd-browser**: Optional web UI for viewing etcd data
   - **acme_webhook**: Updated webhook for ACME DNS-01 challenges

3. **New Volumes**:
   - etcd-data: Stores etcd database
   - mysql-data: Stores MySQL database for CoreDNS

4. **New Secrets**:
   - mysql_password: For MySQL database
   - coredns_api_key: For future API authentication

### CoreDNS Plugins Enabled

All requested plugins are now active in the Corefile:

- **acl**: Access control lists for filtering queries
- **cache**: Response caching for improved performance (30s TTL)
- **dnssec**: Automatic DNSSEC signing of zones
- **etcd**: Dynamic DNS records from etcd backend
- **health**: Health check endpoint on port 8080
- **loadbalance**: Round-robin load balancing for multiple A/AAAA records
- **mysql**: MySQL backend for manually managed zones
- **mdns**: Multicast DNS for .local discovery
- **tls**: DNS-over-TLS support on port 853
- **prometheus**: Metrics export on port 9153
- **forward**: Upstream DNS forwarding
- **loop**: Loop detection
- **reload**: Auto-reload configuration every 30s
- **ready**: Readiness endpoint

### Features

1. **Automatic DNS Management**:
   - Containers with label `coredns.name=myservice` automatically get DNS records
   - Records are created/deleted as containers start/stop
   - No manual intervention required

2. **Multiple DNS Protocols**:
   - Standard DNS (port 53)
   - DNS-over-TLS (port 853)
   - DNS-over-HTTPS (port 443) - configured in Corefile

3. **Dual Backend System**:
   - **etcd**: For dynamic, automatically managed records
   - **MySQL**: For static, manually managed zones

4. **ACME DNS-01 Support**:
   - Webhook service updates etcd for Let's Encrypt challenges
   - Traefik can obtain SSL certificates via DNS validation

5. **Monitoring**:
   - Prometheus metrics at http://coredns:9153/metrics
   - Health endpoint at http://coredns:8080/health
   - etcd metrics at http://etcd:2379/metrics

### How to Use

1. **Generate new secrets**:
   ```bash
   make secrets
   ```

2. **Start DNS services**:
   ```bash
   make up-dns
   # or
   docker compose --profile dns up -d
   ```

3. **Auto-create DNS records**:
   Add label to any container:
   ```yaml
   labels:
     - "coredns.name=myapp"  # Creates myapp.yourdomain.com
   ```

4. **Manual DNS records** (via MySQL):
   ```sql
   INSERT INTO records (zone_name, name, type, ttl, content) VALUES
     ('yourdomain.com', 'custom', 'A', 300, '192.168.1.100');
   ```

5. **View etcd records** (optional):
   Access etcd Browser at: https://etcd-ui.yourdomain.com

### Monitoring

Import these Grafana dashboards:
- CoreDNS: Dashboard ID 12326
- etcd: Dashboard ID 3076

Prometheus is already configured to scrape both CoreDNS and etcd metrics.

### Migration Notes

- DNS port remains 5353 (same as PowerDNS setup)
- ACME DNS-01 challenges work seamlessly with Traefik
- All containers with `coredns.name` labels will get DNS records automatically
- DNSSEC signing is automatic for all zones

### Troubleshooting

1. **Check CoreDNS logs**:
   ```bash
   docker compose logs -f coredns
   ```

2. **Verify etcd is working**:
   ```bash
   docker compose exec etcd etcdctl endpoint health
   ```

3. **Test DNS resolution**:
   ```bash
   dig @localhost -p 5353 dns.yourdomain.com
   ```

4. **Check automatic DNS updates**:
   ```bash
   docker compose logs -f dns-updater
   ```

5. **View etcd records**:
   ```bash
   docker compose exec etcd etcdctl get /coredns --prefix
   ```