# SecureNexus Wiki

**Welcome to the SecureNexus Full Stack Infrastructure Wiki**

This wiki provides comprehensive documentation for the SecureNexus platform - a complete self-hosted infrastructure stack for multi-tenant accounting firm deployments.

---

## 📚 Quick Links

### Getting Started
- [System Overview](System-Overview.md) - Architecture and components
- [Quick Start Guide](Quick-Start.md) - Get up and running
- [Service Inventory](Service-Inventory.md) - All services and URLs

### Infrastructure
- [Authentik SSO](Authentik-SSO.md) - Identity and authentication
- [Multi-Tenant ERP](Multi-Tenant-ERP.md) - ERPNext deployments
- [DNS Management](DNS-Management.md) - CoreDNS and domain configuration
- [Monitoring Stack](Monitoring-Stack.md) - Prometheus, Grafana, Loki

### Client Management
- [Client Onboarding](Client-Onboarding.md) - Add new clients
- [Client Deployments](Client-Deployments.md) - Byrne, Dickinson, etc.
- [Branding & Theming](Branding-Theming.md) - Custom branding per client

### Operations
- [Backup & Recovery](Backup-Recovery.md) - Disaster recovery procedures
- [Troubleshooting](Troubleshooting.md) - Common issues and solutions
- [Maintenance Tasks](Maintenance-Tasks.md) - Regular operations
- [Scripts Reference](Scripts-Reference.md) - Automation tools

### Recent Updates
- [November 2025 Updates](November-2025-Updates.md) - Latest changes
- [Authentik 2025.10.1 Upgrade](Authentik-2025-10-Upgrade.md) - Recent upgrade
- [Change Log](Change-Log.md) - Complete history

---

## 🎯 Current System Status

**Updated:** November 6, 2025

### Health Metrics
- ✅ **Status:** 100% Operational
- ✅ **Containers:** 35+ running
- ✅ **Uptime:** 99.9%+
- ✅ **Security Grade:** A+
- ✅ **Monitoring Targets:** 19/19 up

### Active Clients
1. **Byrne Accounting** - byrne-accounts.org
   - ERP, POS, Website, Portal
2. **Dickinson Supplies** - dickson-supplies.com
   - ERP instance

### Recent Changes
- **Nov 6, 2025:** Authentik upgraded to 2025.10.1 (Redis removed)
- **Nov 1-6, 2025:** Multi-tenant ERP infrastructure deployed
- **Oct 2025:** Portainer, monitoring exporters added

---

## 🏗️ Architecture Overview

### Core Components
```
┌─────────────────────────────────────────┐
│         Traefik Reverse Proxy           │
│    (SSL, Routing, Load Balancing)       │
└─────────────────────────────────────────┘
              │
    ┌─────────┴─────────┬─────────────────┐
    │                   │                 │
┌───▼────┐      ┌──────▼──────┐   ┌─────▼──────┐
│Authentik│      │  ERPNext    │   │ Monitoring │
│  SSO    │      │ Multi-Tenant│   │   Stack    │
└─────────┘      └─────────────┘   └────────────┘
```

### Service Categories
- **Core:** Traefik, Docker Proxy, Tailscale, CrowdSec
- **Identity:** Authentik (PostgreSQL-based)
- **Portal:** Landing, Homarr, Client Portals
- **Monitoring:** Prometheus, Grafana, Loki, Uptime Kuma
- **DNS:** CoreDNS, etcd, MySQL
- **ERP:** Multi-tenant ERPNext instances
- **Email:** Mailcow (separate installation)

---

## 🚀 Common Tasks

### Deploy a New Client
```bash
./scripts/provision-client-complete.sh client-name client-domain.com
```
See: [Client Onboarding](Client-Onboarding.md)

### Create Backup
```bash
./scripts/backup-all.sh
```
See: [Backup & Recovery](Backup-Recovery.md)

### Check Service Health
```bash
docker compose ps
make ps
```

### View Logs
```bash
docker compose logs -f [service_name]
make logs
```

### Restart Service
```bash
make restart S=service_name
```

---

## 📖 Documentation Structure

### By Topic
- **Infrastructure:** Architecture, networking, security
- **Services:** Individual service configuration
- **Clients:** Per-client deployments and customization
- **Operations:** Day-to-day management
- **Development:** Contributing and extending

### By Format
- **Guides:** Step-by-step instructions
- **References:** Command listings, API docs
- **Troubleshooting:** Problem-solution pairs
- **Architecture:** Diagrams and design docs

---

## 🔐 Security

### Access Control
- **Admin Services:** VPN-only (Tailscale)
  - Grafana, Prometheus, Traefik dashboard
- **Client Services:** SSO via Authentik
  - ERP, Portals, Applications
- **Public Services:** CrowdSec protection
  - Landing page, Status page

### Secrets Management
- All secrets in `./secrets/` directory
- Docker secrets for container access
- Never committed to git
- Regular rotation policy

### Firewall
- UFW with deny-by-default
- 13 open ports (SSH, HTTP, HTTPS, SMTP, DNS, etc.)
- CrowdSec intrusion detection
- Rate limiting at multiple layers

---

## 🛠️ Development

### Making Changes
1. Create backup first
2. Test in staging (if available)
3. Update documentation
4. Commit with descriptive message
5. Monitor after deployment

### File Structure
```
securenexus-fullstack/
├── compose.yml           # Main service definitions
├── config/              # Service configurations
├── docs/                # Comprehensive documentation
├── scripts/             # Automation tools (30+)
├── monitoring/          # Prometheus, Grafana configs
├── dns/                 # DNS zones and configuration
├── secrets/             # Secrets (not in git)
├── wiki/                # This wiki
└── [client-dirs]/       # Per-client resources
```

---

## 📞 Support Resources

### Internal Documentation
- `docs/` - 100+ pages of comprehensive guides
- `CLAUDE.md` - Project overview for AI assistance
- `README.md` - Quick start and overview

### External Resources
- [Authentik Docs](https://docs.goauthentik.io)
- [ERPNext Docs](https://docs.erpnext.com)
- [Traefik Docs](https://doc.traefik.io/traefik/)
- [Frappe Framework](https://frappeframework.com)

### Community
- Authentik Discord
- ERPNext Forum
- Frappe Forum

---

## 🎓 Learning Resources

### New to SecureNexus?
1. Read [System Overview](System-Overview.md)
2. Follow [Quick Start Guide](Quick-Start.md)
3. Review [Service Inventory](Service-Inventory.md)
4. Practice with [Common Tasks](#-common-tasks)

### Deploying Your First Client?
1. Read [Client Onboarding](Client-Onboarding.md)
2. Review [Multi-Tenant ERP](Multi-Tenant-ERP.md)
3. Understand [Branding & Theming](Branding-Theming.md)
4. Use automation scripts

### Troubleshooting Issues?
1. Check [Troubleshooting](Troubleshooting.md)
2. Review service logs
3. Consult [Scripts Reference](Scripts-Reference.md)
4. Check documentation in `docs/`

---

## 📊 Monitoring & Metrics

### Dashboards
- **Grafana:** https://grafana.securenexus.net (VPN-only)
- **Prometheus:** https://prometheus.securenexus.net (VPN-only)
- **Uptime Kuma:** https://status.securenexus.net
- **Homarr:** https://portal.securenexus.net

### Key Metrics
- Container health and resource usage
- Service response times
- Database connections and performance
- DNS query rates
- SSL certificate expiration
- Backup status

---

## 📝 Contributing

### Documentation
- Keep wiki up to date
- Document all changes
- Include examples and screenshots
- Link related pages

### Code
- Follow existing patterns
- Add comments for complex logic
- Update CLAUDE.md for major changes
- Create backup before testing

### Commits
- Descriptive commit messages
- Group related changes
- Include "Co-Authored-By: Claude" for AI assistance
- Reference issue numbers if applicable

---

## 🔄 Recent Activity

### Latest Commits
- **6812be6** - Multi-tenant ERP infrastructure (61 files, 19,137+ lines)
- **710b61a** - Authentik 2025.10.1 upgrade + November changelog
- **007d110** - ERPNext multi-site infrastructure
- **62f706b** - Portainer container management
- **d4082fd** - Comprehensive ERPNext changelog

### This Week
- Authentik upgraded to 2025.10.1
- Redis dependency completely removed
- 40+ documentation files created
- 30+ automation scripts added
- 2 production clients deployed

---

## 🎯 Roadmap

### Short Term (Next 30 Days)
- [ ] Onboard 2-3 additional clients
- [ ] Set up off-site backup replication
- [ ] Implement ERP monitoring alerts
- [ ] Create network architecture diagram
- [ ] Centralized logging for ERP

### Long Term (Next 90 Days)
- [ ] Scale to 10+ client deployments
- [ ] Automated disaster recovery testing
- [ ] Geographic redundancy
- [ ] Advanced analytics platform
- [ ] Kubernetes evaluation

---

**Wiki Last Updated:** November 6, 2025
**System Version:** Production v2.0
**Documentation Status:** ✅ Comprehensive

*For the latest updates, see [Change Log](Change-Log.md)*
