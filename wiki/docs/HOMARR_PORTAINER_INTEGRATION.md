# Homarr + Portainer Integration Guide

**Unified Portal Architecture**: Homarr frontend + Portainer backend

## Quick Start

This guide walks you through creating a unified portal where users see Homarr dashboards powered by Portainer's container management backend.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│              User Experience Layer                  │
│                                                     │
│   ┌──────────────────────────────────────────┐    │
│   │         Homarr Dashboard Portal          │    │
│   │                                          │    │
│   │  🏠 Home  📊 Services  📈 Metrics  ⚙️   │    │
│   │                                          │    │
│   │  ┌────────┐ ┌────────┐ ┌──────────┐    │    │
│   │  │ ERPNext│ │  Apps  │ │Container │    │    │
│   │  │  POS   │ │Catalog │ │  Stats   │    │    │
│   │  └────────┘ └────────┘ └──────────┘    │    │
│   │                             ▲           │    │
│   └─────────────────────────────│───────────┘    │
│                                 │                 │
└─────────────────────────────────│─────────────────┘
                                  │
                          Portainer API
                                  │
┌─────────────────────────────────▼─────────────────┐
│                                                     │
│           Management Backend Layer                  │
│                                                     │
│   ┌──────────────────────────────────────────┐    │
│   │      Portainer Container Manager         │    │
│   │                                          │    │
│   │  🐳 Containers  📦 Images  🔧 Stacks    │    │
│   │                                          │    │
│   │  ┌────────────────────────────────┐    │    │
│   │  │   Docker Socket Integration    │    │    │
│   │  │                                │    │    │
│   │  │  • Start/Stop containers       │    │    │
│   │  │  • Monitor resources           │    │    │
│   │  │  • Deploy stacks              │    │    │
│   │  │  • Manage networks/volumes     │    │    │
│   │  └────────────────────────────────┘    │    │
│   └──────────────────────────────────────────┘    │
│                                                     │
└─────────────────────────────────────────────────────┘
                         │
                  Docker Engine
```

## Benefits

### For End Users
- **Single Portal**: One dashboard for all services
- **Visual Interface**: See all running containers at a glance
- **Quick Access**: Click-through to services
- **Resource Metrics**: Real-time CPU, memory, storage
- **Status Monitoring**: Container health indicators

### For Administrators
- **Full Control**: Complete Docker management via Portainer
- **SSO Authentication**: Unified login via Authentik
- **VPN Security**: Admin access requires Tailscale VPN
- **API Integration**: Homarr pulls data from Portainer API
- **Role Separation**: Users see dashboards, admins manage infrastructure

## Step-by-Step Setup

### Phase 1: Deploy Portainer (5 minutes)

1. **Start Portainer**:
   ```bash
   make up-portal
   # Or
   docker compose up -d portainer
   ```

2. **Wait for service to be healthy**:
   ```bash
   docker compose ps portainer
   # Wait for "healthy" status
   ```

3. **Connect to Tailscale VPN** (required for access):
   ```bash
   tailscale up
   tailscale status
   ```

4. **Access Portainer** (first 5 minutes only):
   ```
   https://portainer.securenexus.net
   ```

5. **Create admin account**:
   - Username: `admin`
   - Password: Choose strong password (save it!)
   - Click "Create user"

6. **Select "Get Started"** to connect to local Docker

### Phase 2: Configure Authentik SSO (10 minutes)

**In Authentik** (`https://sso.securenexus.net`):

1. **Create OAuth Provider**:
   - Navigate to: Applications → Providers → Create
   - Name: `Portainer OAuth Provider`
   - Type: `OAuth2/OpenID Provider`
   - Client Type: `Confidential`
   - Redirect URIs:
     ```
     https://portainer.securenexus.net
     https://portainer.securenexus.net/*
     ```
   - **Save and copy** Client ID and Client Secret

2. **Create Application**:
   - Navigate to: Applications → Applications → Create
   - Name: `Portainer`
   - Slug: `portainer`
   - Provider: Select `Portainer OAuth Provider`
   - Launch URL: `https://portainer.securenexus.net`
   - **Save**

3. **Assign Users/Groups**:
   - In application, go to Bindings tab
   - Create binding for `Admins` group
   - Save

**In Portainer** (`https://portainer.securenexus.net`):

4. **Configure OAuth**:
   - Navigate to: Settings → Authentication → OAuth
   - Provider: `Custom`
   - Use SSO: ✅ Enabled

   Settings:
   ```
   Client ID: [From Authentik]
   Client Secret: [From Authentik]
   Authorization URL: https://sso.securenexus.net/application/o/authorize/
   Access Token URL: https://sso.securenexus.net/application/o/token/
   Resource URL: https://sso.securenexus.net/application/o/userinfo/
   Redirect URL: https://portainer.securenexus.net
   Scopes: openid profile email
   User Identifier: preferred_username
   ```

5. **Test OAuth** and **Save**

6. **Logout and test SSO login**

### Phase 3: Create Portainer API Token (3 minutes)

1. **In Portainer**, navigate to: User → admin (your profile)

2. **Scroll to "Access tokens"**

3. **Click "Add access token"**:
   - Description: `Homarr Integration`
   - Click "Add token"
   - **⚠️ Copy the token immediately!** (only shown once)

4. **Store token securely**:
   ```bash
   echo "ptr_YOUR_TOKEN_HERE" > secrets/portainer_api_token.txt
   chmod 600 secrets/portainer_api_token.txt
   ```

### Phase 4: Configure Homarr Integration (5 minutes)

1. **Access Homarr**: `https://portal.securenexus.net`

2. **Enter Edit Mode**:
   - Click settings icon (⚙️)
   - Click "Edit Mode" toggle

3. **Add Container Management Section**:

   **Option A: Docker Integration Widget** (Recommended)

   - Click "+" button to add widget
   - Search for "Docker" or "Docker Integration"
   - Configure:
     ```
     Name: Infrastructure Management
     Docker URL: http://portainer:9000
     API Token: [Paste token from secrets/portainer_api_token.txt]

     Display Settings:
     ✅ Show container count
     ✅ Show resource usage
     ✅ Show running services
     ✅ Enable click-through to Portainer
     ```

   **Option B: iFrame Widget** (Alternative)

   - Click "+" button
   - Select "iFrame" widget
   - Configure:
     ```
     Name: Portainer
     URL: https://portainer.securenexus.net
     Height: 600px
     ```

4. **Add Quick Link to Portainer**:
   - Click "+" → "Service" or "Bookmark"
   - Configure:
     ```
     Name: Portainer Admin
     URL: https://portainer.securenexus.net
     Icon: Upload Portainer logo or use emoji 🐳
     Category: Infrastructure
     ```

5. **Arrange Dashboard Layout**:
   - Drag widgets to desired positions
   - Suggested layout:
     ```
     ┌─────────────────────────────────────┐
     │  Quick Links        | Docker Stats  │
     │  • ERPNext          |  29 containers│
     │  • POS              |  27 running   │
     │  • Portainer Admin  |  2 stopped    │
     ├─────────────────────────────────────┤
     │  Services Status                    │
     │  [Container widgets for key apps]   │
     └─────────────────────────────────────┘
     ```

6. **Exit Edit Mode**: Click "Save" and toggle off "Edit Mode"

### Phase 5: Add Service Tiles (10 minutes)

Make your dashboard beautiful by adding tiles for each service:

**For each major service** (ERPNext, POS, Grafana, etc.):

1. **Add Service Widget**:
   - Click "+" → "Service"
   - Configure:
     ```
     Name: [Service Name]
     URL: https://[service].securenexus.net
     Icon: [Upload or select]
     Ping URL: https://[service].securenexus.net
     ```

2. **Configure Docker Integration** (using Portainer API):
   - In service widget settings:
   - Enable "Docker Container"
   - Container Name: `[exact container name]`
   - Portainer URL: `http://portainer:9000`
   - API Token: [Same token as before]

3. **This enables**:
   - ✅ Real-time status (running/stopped)
   - ✅ Resource usage (CPU, memory)
   - ✅ Quick actions (start/stop/restart)
   - ✅ Click-through to logs

**Repeat for all services**:
- erpnext-backend
- erpnext-worker
- grafana
- prometheus
- authentik_server
- traefik
- etc.

## Dashboard Layout Examples

### Example 1: Admin Dashboard

```
╔═══════════════════════════════════════════════════╗
║     SecureNexus Infrastructure Portal (Homarr)    ║
╠══════════════════════╦════════════════════════════╣
║  🚀 Quick Access     ║  🐳 Docker Status          ║
║                      ║                            ║
║  ERPNext            ║  Total: 29 containers      ║
║  POS Awesome        ║  Running: 27               ║
║  Grafana            ║  Stopped: 2                ║
║  Prometheus         ║  CPU: 45%                  ║
║  Portainer Admin    ║  Memory: 8.2GB / 16GB      ║
║  Uptime Kuma        ║  Storage: 125GB / 500GB    ║
║                      ║                            ║
╠══════════════════════╩════════════════════════════╣
║            🔧 Active Services                     ║
║  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  ║
║  │Traefik│ │Authen│ │ ERP  │ │Grafa│ │Prome │  ║
║  │  ✅   │ │tik ✅│ │Next ✅│ │na ✅│ │theus│  ║
║  │45% CPU│ │8% CPU│ │12%CPU│ │5% CPU│ │✅   │  ║
║  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘  ║
╚═══════════════════════════════════════════════════╝
```

### Example 2: User Dashboard

```
╔═══════════════════════════════════════════════════╗
║          Byrne Accounting Portal (Homarr)         ║
╠══════════════════════╦════════════════════════════╣
║  📊 Applications     ║  📈 System Health          ║
║                      ║                            ║
║  Accounting (ERP)   ║  All Systems Operational   ║
║  Point of Sale      ║  ✅ Services: 27/29        ║
║  Client Portal      ║  ✅ Uptime: 99.9%          ║
║  Document Manager   ║  ✅ Performance: Good      ║
║  Reports            ║                            ║
║                      ║  [Resource usage chart]    ║
╠══════════════════════╩════════════════════════════╣
║          📋 Recent Activity                       ║
║  • Invoice #1024 created (2 min ago)             ║
║  • Payment received (15 min ago)                 ║
║  • New client added (1 hour ago)                 ║
╚═══════════════════════════════════════════════════╝
```

## Advanced Configuration

### Custom Widgets

**Create custom Docker container widget**:

1. **In Homarr Edit Mode**, add "Custom API" widget

2. **Configure API endpoint**:
   ```javascript
   URL: https://portainer.securenexus.net/api/endpoints/1/docker/containers/json
   Headers: {
     "X-API-Key": "ptr_YOUR_TOKEN"
   }
   Method: GET
   ```

3. **Parse response** to display:
   - Container names
   - Status (running/stopped)
   - CPU/Memory usage
   - Uptime

### Homarr Auto-Discovery

Enable automatic service discovery in Homarr:

1. **Settings → Integrations → Docker**

2. **Configure**:
   ```
   Docker Socket: /var/run/docker.sock
   Auto-discover services: ✅ Enabled
   Filter by label: traefik.enable=true
   ```

3. **This automatically adds**:
   - All Traefik-enabled services
   - Correct URLs from Traefik labels
   - Service icons (if available)
   - Health checks

### Portainer Stacks for Homarr

Deploy new services directly from Homarr (via Portainer API):

1. **Create deployment template** in Portainer:
   - Navigate to: App Templates → Custom Templates
   - Create template for common apps

2. **In Homarr**, add "Deploy" button:
   - Links to Portainer stack deployment
   - Pre-filled with template
   - One-click deploy for new services

## User Workflows

### End User Workflow

1. **Access Portal**: `https://portal.securenexus.net`
2. **Login via Authentik SSO**
3. **View Dashboard**:
   - See all available services
   - Check system status
   - Click service to access
4. **No backend access needed**

### Administrator Workflow

1. **Access Portal**: `https://portal.securenexus.net`
2. **Login via Authentik SSO**
3. **View Dashboard** (same as users)
4. **For Management**:
   - Click "Portainer Admin" link
   - Connect to Tailscale VPN (if not connected)
   - Access `https://portainer.securenexus.net`
   - Full Docker management capabilities

### Deploying New Service (Admin)

1. **Via Portainer**:
   - Access Portainer
   - Navigate to Stacks
   - Add new stack or deploy container
   - Configure Traefik labels
   - Deploy

2. **Auto-appears in Homarr**:
   - If using auto-discovery
   - Or manually add service widget

## Monitoring & Alerts

### Integrate Uptime Kuma

Add Uptime Kuma monitoring visible in Homarr:

1. **In Uptime Kuma** (`https://status.securenexus.net`):
   - Add monitors for all services
   - Configure alerting

2. **In Homarr**:
   - Add "Uptime Kuma" widget
   - Configure:
     ```
     Uptime Kuma URL: https://status.securenexus.net
     API Token: [From Uptime Kuma Settings]
     Show: All monitors
     ```

3. **Dashboard shows**:
   - Service uptime percentages
   - Current status (up/down)
   - Response times
   - Incident history

### Prometheus Metrics in Homarr

Display Prometheus metrics directly in dashboard:

1. **Add "Prometheus" widget**

2. **Configure queries**:
   ```promql
   # Container CPU usage
   rate(container_cpu_usage_seconds_total{name=~"erpnext.*"}[5m])

   # Container memory
   container_memory_usage_bytes{name=~"erpnext.*"}

   # Container count
   count(container_last_seen)
   ```

3. **Display as**:
   - Gauge charts
   - Line graphs
   - Stat panels

## Security Considerations

### Access Levels

**Public Access** (No authentication):
- None - all services require auth

**Authenticated Users** (via Authentik):
- Homarr dashboard (read-only)
- Service access (per-service auth)
- Resource metrics viewing

**VPN + Admin** (Tailscale + Authentik):
- Full Portainer access
- Container management
- System configuration
- Deployment capabilities

### API Token Security

**Protect Portainer API token**:

```bash
# Store securely
chmod 600 secrets/portainer_api_token.txt

# Limit token permissions in Portainer
# Use read-only token for Homarr if possible

# Rotate tokens periodically
# Portainer → Settings → Users → Access Tokens → Revoke old, create new
```

### Network Isolation

All services communicate via internal Docker network:

```
Homarr → Portainer API: Internal (proxy network)
User → Homarr: HTTPS via Traefik
Admin → Portainer: HTTPS via Traefik (VPN-only)
```

## Troubleshooting

### Homarr Can't Connect to Portainer

**Check API token**:
```bash
# Verify token is valid
curl -H "X-API-Key: $(cat secrets/portainer_api_token.txt)" \
  https://portainer.securenexus.net/api/status
```

**Check network connectivity**:
```bash
# From inside Homarr container
docker compose exec homarr wget -O- http://portainer:9000/api/status
```

### Container Stats Not Showing in Homarr

**Verify Portainer API access**:
```bash
# Test containers endpoint
curl -H "X-API-Key: $(cat secrets/portainer_api_token.txt)" \
  https://portainer.securenexus.net/api/endpoints/1/docker/containers/json | jq
```

**Check Homarr configuration**:
- Verify Docker integration enabled
- Check API token is correct
- Verify Portainer URL matches

### Services Not Auto-Discovered

**Ensure Docker socket access**:
```yaml
# In compose.yml for homarr
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

**Check Traefik labels**:
```bash
# Verify labels exist
docker inspect erpnext-backend | jq '.[0].Config.Labels' | grep traefik
```

## Maintenance

### Update Portainer

```bash
docker compose pull portainer
docker compose up -d portainer
```

**Note**: API token remains valid after updates

### Update Homarr

```bash
docker compose pull homarr
docker compose up -d homarr
```

**Note**: Dashboard configuration is persisted in volume

### Backup Integration Data

```bash
# Portainer data (includes API tokens)
docker run --rm \
  -v securenexus-fullstack_portainer-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar -czf /backup/portainer.tar.gz -C /data .

# Homarr data (includes dashboard config)
docker run --rm \
  -v securenexus-fullstack_homarr-data:/appdata \
  -v $(pwd)/backups:/backup \
  alpine tar -czf /backup/homarr.tar.gz -C /appdata .
```

## Best Practices

1. **Use VPN-only access** for Portainer administration
2. **Create read-only API tokens** for Homarr when possible
3. **Regularly update** both Portainer and Homarr
4. **Monitor API token usage** in Portainer activity logs
5. **Document custom widgets** and configurations
6. **Test disaster recovery** procedures periodically
7. **Train users** on dashboard navigation
8. **Keep sensitive data** out of dashboard (use links instead)

## Conclusion

You now have a powerful, unified portal:

- ✅ **Homarr**: User-friendly dashboard frontend
- ✅ **Portainer**: Robust container management backend
- ✅ **Authentik**: Centralized SSO authentication
- ✅ **Tailscale**: Secure VPN access for admins
- ✅ **Integrated**: Seamless data flow between systems

**Users see beautiful dashboards** with real-time service status.
**Admins have full control** via Portainer's comprehensive interface.
**Everyone uses SSO** for consistent, secure authentication.

---

**Next Steps**:
1. Complete Portainer OAuth configuration
2. Create API token for Homarr
3. Configure Homarr widgets
4. Customize dashboard layout
5. Train users on portal navigation
6. Document your specific workflows

**Support**: See `docs/PORTAINER_SETUP.md` for detailed Portainer configuration.
