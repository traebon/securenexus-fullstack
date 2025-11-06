# Portainer Setup with SSO & Homarr Integration

**Status**: ✅ Configured and Ready to Deploy
**Access**: VPN-Only (Tailscale required)
**URL**: `https://portainer.${DOMAIN}`
**Integration**: Homarr Dashboard Portal

## Overview

Portainer Business Edition provides enterprise-grade Docker container management with SSO authentication via Authentik. It serves as the backend management system for Homarr, allowing users to view dashboards while administrators manage the infrastructure.

### Architecture

```
User → Homarr Portal → Portainer API
         ↓                 ↓
    Dashboard View    Admin Management
         ↓                 ↓
    Authentik SSO    Authentik SSO
```

**Key Features**:
- 🔐 Authentik OAuth SSO authentication
- 🔒 VPN-only access (Tailscale required)
- 📊 Integration with Homarr for unified portal
- 🐳 Full Docker container management
- 📈 Resource monitoring and metrics
- 👥 Team collaboration features
- 🔑 Role-based access control (RBAC)

## Deployment

### Prerequisites

1. **Core Services Running**:
   ```bash
   docker compose ps | grep -E "traefik|authentik|tailscale"
   ```
   - ✅ Traefik (reverse proxy)
   - ✅ Authentik (SSO provider)
   - ✅ Tailscale (VPN access)

2. **DNS Configuration**:
   ```bash
   # Add to DNS zone or hosts file
   portainer.securenexus.net   A   10.0.1.100
   ```

3. **VPN Connection** (for access):
   ```bash
   # Verify Tailscale is connected
   tailscale status
   ```

### Deploy Portainer

```bash
# Start Portainer with portal profile
make up-portal

# Or directly
docker compose up -d portainer

# Check status
docker compose ps portainer

# Follow logs
make portainer-logs
```

### Initial Access

**First-Time Setup** (before SSO):

1. Access Portainer (within 5 minutes of first start):
   ```
   https://portainer.securenexus.net
   ```

2. Create admin account:
   - Username: `admin`
   - Password: Choose a strong password
   - Click "Create user"

3. Skip Portainer license prompt (or enter if you have one)

4. Select "Get Started" to use the local Docker environment

**After SSO Configuration**, admin access is via Authentik only.

## Authentik SSO Configuration

### Step 1: Create OAuth Provider in Authentik

1. **Access Authentik Admin**:
   ```
   https://sso.securenexus.net/if/admin/
   ```

2. **Navigate to**: Applications → Providers → Create

3. **Provider Configuration**:
   - **Name**: `Portainer OAuth Provider`
   - **Type**: `OAuth2/OpenID Provider`
   - **Authentication flow**: `default-authentication-flow (Welcome to authentik!)`
   - **Authorization flow**: `default-provider-authorization-explicit-consent (Authorize Application)`

4. **Protocol Settings**:
   - **Client Type**: `Confidential`
   - **Client ID**: Auto-generated (copy this!)
   - **Client Secret**: Auto-generated (copy this!)
   - **Redirect URIs**:
     ```
     https://portainer.securenexus.net
     https://portainer.securenexus.net/*
     ```
   - **Signing Key**: `authentik Self-signed Certificate`

5. **Advanced Settings**:
   - **Scopes**: `openid`, `profile`, `email`
   - **Subject Mode**: `Based on the User's hashed ID`
   - **Include claims in ID Token**: ✅ Enabled

6. **Save** the provider and **copy** Client ID and Client Secret

### Step 2: Create Authentik Application

1. **Navigate to**: Applications → Applications → Create

2. **Application Details**:
   - **Name**: `Portainer`
   - **Slug**: `portainer`
   - **Provider**: Select `Portainer OAuth Provider` (created above)
   - **Launch URL**: `https://portainer.securenexus.net`
   - **Icon**: Upload Portainer logo (optional)

3. **UI Settings**:
   - **Description**: `Docker Container Management`
   - **Publisher**: `SecureNexus Infrastructure`
   - **Group**: `Infrastructure`

4. **Access Control**:
   - **Policy engine mode**: `any`
   - **Backchannel providers**: Leave empty

5. **Save** the application

### Step 3: Assign Users/Groups

1. **In the Portainer application**, go to **Bindings** tab

2. **Create binding** for groups or users:
   - **Group Binding** (recommended):
     - Click "Create Group Binding"
     - Group: `Admins` (or create `Portainer Admins`)
     - Order: `0`
     - Save

   - **Individual User** (alternative):
     - Click "Create User Binding"
     - Select specific user
     - Order: `0`
     - Save

### Step 4: Configure Portainer OAuth

1. **Access Portainer** as admin: `https://portainer.securenexus.net`

2. **Navigate to**: Settings → Authentication

3. **Select**: `OAuth`

4. **OAuth Configuration**:
   - **Provider**: `Custom`
   - **Use SSO**: ✅ Enabled
   - **Hide internal authentication**: ☐ Disabled (keep for admin access)
   - **Automatic team membership**: ✅ Enabled (optional)

5. **OAuth Settings**:
   ```
   Client ID: [From Authentik Provider]
   Client Secret: [From Authentik Provider]

   Authorization URL: https://sso.securenexus.net/application/o/authorize/
   Access Token URL: https://sso.securenexus.net/application/o/token/
   Resource URL: https://sso.securenexus.net/application/o/userinfo/
   Redirect URL: https://portainer.securenexus.net

   Scopes: openid profile email
   ```

6. **User Identifier**: `preferred_username`

7. **Click**: "Test OAuth" to verify configuration

8. **Save** settings

## Homarr Integration

Homarr serves as the user-facing dashboard portal, while Portainer provides the backend management.

### Configure Portainer API Access

1. **Create API Access Token** in Portainer:
   - Navigate to: Settings → Users → admin
   - Scroll to "Access tokens"
   - Click "Add access token"
   - Description: `Homarr Integration`
   - Click "Add token"
   - **Copy the token immediately** (only shown once!)

2. **Store token securely**:
   ```bash
   echo "your-portainer-api-token" > secrets/portainer_api_token.txt
   chmod 600 secrets/portainer_api_token.txt
   ```

### Add Portainer to Homarr Dashboard

1. **Access Homarr**: `https://portal.securenexus.net`

2. **Enter Edit Mode**: Click the settings icon → "Edit Mode"

3. **Add Portainer Widget**:
   - Click "+" to add widget
   - Search for "Docker" or "Portainer"
   - Select "Docker Integration"

4. **Configure Widget**:
   ```
   Name: Infrastructure Management
   URL: https://portainer.securenexus.net
   API Key: [Your Portainer API token]

   Display Options:
   - Show container status
   - Show resource usage
   - Click to open Portainer
   ```

5. **Position Widget**: Drag to desired location

6. **Save Changes**: Exit edit mode

### Homarr Dashboard Layout (Recommended)

```
╔═══════════════════════════════════════════╗
║         SecureNexus Portal (Homarr)       ║
╠═══════════════╦═══════════════╦═══════════╣
║  Quick Links  ║   Services    ║  Metrics  ║
║               ║               ║           ║
║  ERPNext      ║  Infrastructure ║ CPU     ║
║  POS          ║  (Portainer)  ║ Memory   ║
║  Grafana      ║  29 containers║ Storage  ║
║  Uptime Kuma  ║  5 running    ║          ║
╠═══════════════╩═══════════════╩═══════════╣
║          Recent Activity & Logs           ║
╚═══════════════════════════════════════════╝
```

## Access Control

### VPN-Only Access

Portainer is configured with `admin-vpn@file` middleware, requiring Tailscale VPN connection.

**To Access Portainer**:

1. **Connect to Tailscale VPN**:
   ```bash
   # On your client machine
   tailscale up

   # Verify connection
   tailscale status
   ```

2. **Access URL**: `https://portainer.securenexus.net`

3. **Login** via Authentik SSO or admin credentials

**Without VPN**: Access is denied (403 Forbidden)

### User Roles in Portainer

**Administrator**:
- Full access to all Portainer features
- Manage users, teams, and settings
- Deploy and manage containers
- Access logs and console
- Configure integrations

**Standard User** (via SSO):
- View containers and services
- View logs (read-only)
- View resource usage
- Limited deployment capabilities

**Team Customization**:
Create teams in Portainer with specific permissions:
1. Navigate to: Users → Teams → Add team
2. Define team name and leader
3. Assign users to team
4. Set resource access policies

## Features Overview

### Container Management

**View Containers**:
- Container list with status
- Resource usage per container
- Quick actions (start, stop, restart, remove)
- Log viewer with search
- Terminal/console access

**Deploy Containers**:
- Deploy from Docker Hub
- Deploy from custom registry
- Docker Compose deployment
- Stack deployment (multi-container apps)

### Resource Monitoring

**Dashboard Metrics**:
- Total containers (running/stopped)
- CPU usage per container
- Memory usage per container
- Network I/O statistics
- Storage usage

**Real-time Graphs**:
- CPU usage trends
- Memory consumption over time
- Network traffic
- Disk I/O

### Docker Compose Stacks

**Manage Stacks**:
- Deploy compose stacks via web UI
- Edit stack configurations
- View stack services
- Manage stack resources
- Update and redeploy stacks

**Stack Templates**:
- Create reusable templates
- Import from Git repositories
- Share templates across teams

### Image Management

**Docker Images**:
- View local images
- Pull from registries
- Build images from Dockerfiles
- Push to private registries
- Image vulnerability scanning (Business Edition)

### Network & Volume Management

**Networks**:
- Create Docker networks
- Manage network drivers
- Configure IP ranges
- Connect/disconnect containers

**Volumes**:
- Create and manage volumes
- View volume usage
- Backup/restore volumes
- Browse volume contents

## Security Features

### Authentication Methods

1. **Authentik OAuth SSO** (Primary):
   - Centralized authentication
   - MFA support via Authentik
   - Group-based access control

2. **Internal Authentication** (Fallback):
   - Local admin account
   - Used for initial setup
   - Backup access method

### Access Control

**RBAC (Role-Based Access Control)**:
- Predefined roles (Administrator, Standard User)
- Custom role creation
- Fine-grained permissions
- Resource-level access control

**Team-Based Access**:
- Organize users into teams
- Assign resources per team
- Team-specific registries
- Isolated environments

### Audit Logging

**Activity Logs**:
- User login/logout events
- Container operations
- Configuration changes
- Resource access logs

**Access Logs**:
```bash
# View Portainer logs
make portainer-logs

# Search for specific events
docker compose logs portainer | grep -i "authentication"
```

## Backup & Restore

### Backup Portainer Data

Portainer data is automatically included in system backups:

**Manual Backup**:
```bash
# Backup Portainer volume
docker run --rm \
  -v securenexus-fullstack_portainer-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar -czf /backup/portainer-backup-$(date +%Y%m%d).tar.gz -C /data .
```

**Backup Contents**:
- User accounts and teams
- OAuth configurations
- Docker endpoint settings
- Stack definitions
- Custom templates
- Access control policies

### Restore Portainer Data

```bash
# Stop Portainer
docker compose stop portainer

# Restore from backup
docker run --rm \
  -v securenexus-fullstack_portainer-data:/data \
  -v $(pwd)/backups:/backup \
  alpine sh -c "rm -rf /data/* && tar -xzf /backup/portainer-backup-YYYYMMDD.tar.gz -C /data"

# Start Portainer
docker compose up -d portainer
```

## Troubleshooting

### Issue 1: Cannot Access Portainer (403 Forbidden)

**Cause**: Not connected to Tailscale VPN

**Solution**:
```bash
# Connect to VPN
tailscale up

# Verify connection
tailscale status

# Check Tailscale IP
ip addr show tailscale0
```

### Issue 2: OAuth Login Fails

**Cause**: Misconfigured OAuth settings

**Solution**:
1. Verify Authentik provider configuration
2. Check Client ID and Secret match
3. Verify redirect URLs are correct
4. Test OAuth from Authentik side
5. Check Portainer logs for errors:
   ```bash
   make portainer-logs
   ```

### Issue 3: Admin Password Forgotten

**Solution**:
```bash
# Reset admin password
make portainer-reset

# Or manually
docker compose stop portainer
docker compose run --rm portainer --admin-password='NewSecurePassword123!'
docker compose up -d portainer
```

### Issue 4: Portainer Shows Old Containers

**Cause**: Needs to reconnect to Docker socket

**Solution**:
```bash
# Restart Portainer
docker compose restart portainer

# Or recreate environment in Portainer UI
# Navigate to: Environments → local → Update
```

### Issue 5: SSL Certificate Errors

**Cause**: Traefik certificate not ready

**Solution**:
```bash
# Check Traefik logs
docker compose logs traefik | grep portainer

# Check certificate status
ls -la acme/acme.json

# Force certificate renewal
docker compose restart traefik
```

## Monitoring & Metrics

### Prometheus Integration (Optional)

Portainer can expose metrics for Prometheus:

1. **Enable metrics** in Portainer:
   - Settings → Metrics
   - Enable Prometheus metrics
   - Note the metrics endpoint

2. **Add to Prometheus**:
   ```yaml
   # monitoring/prometheus.yml
   scrape_configs:
     - job_name: 'portainer'
       static_configs:
         - targets: ['portainer:9090']
   ```

3. **Restart Prometheus**:
   ```bash
   docker compose restart prometheus
   ```

### Health Checks

**Built-in Health Check**:
```bash
# Check Portainer health
docker compose ps portainer

# Should show "healthy" status
```

**Manual Health Check**:
```bash
# Test API endpoint
curl -k https://portainer.securenexus.net/api/status

# Expected response: {"Version":"2.x.x"}
```

## Best Practices

### Security

1. **Always use VPN access** for Portainer (already configured)
2. **Enable MFA** in Authentik for all admin users
3. **Regularly review** access logs for suspicious activity
4. **Keep Portainer updated** to latest version
5. **Use teams and RBAC** for multi-user environments
6. **Backup Portainer data** regularly (automated)

### Management

1. **Use Stacks** for multi-container applications
2. **Label containers** for better organization
3. **Set resource limits** on containers
4. **Document** stack configurations
5. **Test deployments** before production
6. **Monitor resource usage** regularly

### Integration with Homarr

1. **Keep API token secure** (store in secrets/)
2. **Use read-only permissions** for Homarr integration
3. **Configure widget** to show key metrics only
4. **Link to Portainer** for detailed management
5. **Update dashboard** when adding new services

## Upgrading Portainer

### Update to Latest Version

```bash
# Pull latest image
docker compose pull portainer

# Recreate container
docker compose up -d portainer

# Verify version
docker compose exec portainer portainer --version
```

**Important**: Portainer EE requires a valid license for production use.

### Migration from CE to EE

If upgrading from Community Edition:

1. **Backup data** (automatic in system backups)
2. **Update image** in compose.yml to `portainer/portainer-ee:latest`
3. **Restart container**: `docker compose up -d portainer`
4. **Activate license** in Portainer UI

## Support Resources

### Documentation
- Portainer Docs: https://docs.portainer.io
- Portainer API: https://docs.portainer.io/api/
- Authentik OAuth: https://goauthentik.io/integrations/sources/oauth/

### Community
- Portainer Community: https://community.portainer.io
- Portainer Discord: https://discord.gg/portainer
- Portainer GitHub: https://github.com/portainer/portainer

### Quick Reference

**Access URLs**:
- Portainer: `https://portainer.securenexus.net`
- Homarr Portal: `https://portal.securenexus.net`
- Authentik SSO: `https://sso.securenexus.net`

**Common Commands**:
```bash
# Start Portainer
docker compose up -d portainer

# View logs
make portainer-logs

# Restart Portainer
docker compose restart portainer

# Reset admin password
make portainer-reset

# Check status
docker compose ps portainer

# Update Portainer
docker compose pull portainer && docker compose up -d portainer
```

**API Access**:
```bash
# Using API token
curl -H "X-API-Key: your-token" \
  https://portainer.securenexus.net/api/endpoints/1/docker/containers/json

# Get container list
curl -H "X-API-Key: your-token" \
  https://portainer.securenexus.net/api/endpoints/1/docker/containers/json | jq
```

## Conclusion

Portainer is now configured as the backend management system for your SecureNexus infrastructure:

- ✅ **Deployed** with VPN-only access
- ✅ **Secured** with Authentik OAuth SSO
- ✅ **Integrated** with Homarr dashboard
- ✅ **Monitored** with health checks
- ✅ **Backed up** automatically
- ✅ **Documented** for team use

**Users** access the friendly Homarr portal for dashboard views, while **administrators** use Portainer for comprehensive Docker management.

**Next Steps**:
1. Complete OAuth SSO configuration in Authentik
2. Configure Portainer OAuth settings
3. Add Portainer widget to Homarr dashboard
4. Create teams and assign users
5. Test SSO login flow
6. Document your custom workflows

---

**Document Version**: 1.0
**Last Updated**: October 18, 2025
**Status**: Production Ready

