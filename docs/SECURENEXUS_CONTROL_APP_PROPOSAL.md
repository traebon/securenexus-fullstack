# SecureNexus Control App - SelfPrivacy-Style Proposal

**Date:** November 6, 2025
**Inspired By:** SelfPrivacy (https://selfprivacy.org)
**Goal:** Create a mobile/desktop app to manage SecureNexus infrastructure

---

## Executive Summary

Build a **SecureNexus Control App** - a Flutter-based mobile and desktop application that allows administrators to deploy and manage multi-tenant accounting firm infrastructure through an intuitive interface, similar to SelfPrivacy but tailored for business service providers.

---

## What is SelfPrivacy? (Analysis)

### Architecture
- **Frontend:** Flutter/Dart app (Android, iOS, Linux, Windows, macOS)
- **Backend:** Python GraphQL API (strawberry-graphql)
- **Infrastructure:** NixOS for immutable, reproducible deployments
- **Communication:** GraphQL subscriptions for real-time updates

### Key Features
- One-click service deployment
- No console/CLI required
- Services: Email, Nextcloud, Bitwarden, Gitea, Jitsi, VPN
- Automated backups
- DNS management
- User management
- QR code sharing for access

### Philosophy
- Zero technical knowledge required
- Complete data ownership
- No telemetry or tracking
- Open source
- Privacy-focused

---

## SecureNexus Control App - Proposed Architecture

### Core Difference: Business Focus vs Personal Use

**SelfPrivacy:** Personal cloud services for individuals
**SecureNexus:** Multi-tenant business infrastructure for accounting firms

### Technology Stack

#### Frontend (Mobile/Desktop App)
```
- Framework: Flutter/Dart
- Platforms: iOS, Android, Windows, Linux, macOS
- State Management: Riverpod or Bloc
- HTTP Client: Dio with GraphQL support
- UI: Material Design 3 with custom branding
- Auth: JWT tokens via Authentik OAuth
```

#### Backend API
```
- Language: Python (FastAPI or Flask)
- API Style: GraphQL (strawberry-graphql or graphene)
- Database: PostgreSQL (existing Authentik DB)
- Cache: Redis (existing infrastructure)
- Authentication: Authentik OAuth/OIDC
- Authorization: Role-based (via Authentik groups)
```

#### Infrastructure Layer
```
- Current: Docker Compose (keep as-is)
- Future Option: Consider NixOS for reproducibility
- Orchestration: Your existing Traefik + Docker setup
- Secrets: Existing Docker secrets management
- Monitoring: Existing Prometheus/Grafana
```

---

## Feature Comparison

### SelfPrivacy Features
| Feature | Purpose |
|---------|---------|
| Deploy Services | One-click Nextcloud, Gitea, etc. |
| DNS Management | Automatic DNS configuration |
| Backup Management | Automated backup to separate location |
| User Management | Add/remove users for services |
| Server Status | Real-time health monitoring |
| QR Code Sharing | Easy credential sharing |

### SecureNexus Control App Features (Proposed)

| Feature | Purpose |
|---------|---------|
| **Client Provisioning** | Deploy new accounting firm client (ERP, portal, website) |
| **Service Management** | Start/stop/restart services per client |
| **User Management** | Create users, assign roles, manage SSO |
| **DNS Management** | View/edit DNS zones, add subdomains |
| **Monitoring Dashboard** | Real-time metrics, alerts, service health |
| **Backup Management** | Trigger backups, view status, restore |
| **Theme Customization** | Upload logos, set colors per client |
| **Client Portal** | Client self-service for their own ERP access |
| **Billing Integration** | Track usage, generate reports |
| **SSL Management** | View certificate status, force renewal |
| **Log Viewer** | Real-time log streaming per service |
| **Script Executor** | Run automation scripts from app |

---

## App Architecture Design

### High-Level Architecture

```
┌─────────────────────────────────────────┐
│      Flutter Mobile/Desktop App         │
│  (iOS, Android, Windows, Linux, macOS)  │
└─────────────────┬───────────────────────┘
                  │ GraphQL over HTTPS
                  │ (JWT Authentication)
                  │
┌─────────────────▼───────────────────────┐
│      SecureNexus GraphQL API            │
│         (Python FastAPI)                │
│  - Authentication (Authentik OAuth)     │
│  - Authorization (Role-based)           │
│  - Business Logic                       │
└─────────────────┬───────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐   ┌────▼────┐   ┌───▼────┐
│Docker │   │Authentik│   │Postgres│
│ API   │   │  API    │   │   DB   │
└───┬───┘   └─────────┘   └────────┘
    │
┌───▼────────────────────────────────────┐
│   Docker Containers (Traefik, ERP,     │
│   Monitoring, DNS, etc.)                │
└─────────────────────────────────────────┘
```

### API Endpoints (GraphQL Schema)

#### Queries
```graphql
type Query {
  # System
  systemStatus: SystemStatus!
  services: [Service!]!
  service(name: String!): Service

  # Clients
  clients: [Client!]!
  client(id: ID!): Client

  # Users
  users: [User!]!
  user(id: ID!): User
  groups: [Group!]!

  # Monitoring
  metrics(service: String, timeRange: String): [Metric!]!
  alerts: [Alert!]!
  logs(service: String, lines: Int): [LogEntry!]!

  # Backups
  backups: [Backup!]!
  backupStatus: BackupStatus!

  # DNS
  dnsZones: [DNSZone!]!
  dnsRecords(zone: String!): [DNSRecord!]!

  # SSL
  certificates: [Certificate!]!
}
```

#### Mutations
```graphql
type Mutation {
  # Client Management
  createClient(input: CreateClientInput!): Client!
  updateClient(id: ID!, input: UpdateClientInput!): Client!
  deleteClient(id: ID!): Boolean!

  # Service Control
  startService(name: String!): Service!
  stopService(name: String!): Service!
  restartService(name: String!): Service!

  # User Management
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!
  assignUserToGroup(userId: ID!, groupId: ID!): Boolean!

  # Backups
  createBackup: Backup!
  restoreBackup(id: ID!): Boolean!

  # DNS
  createDNSRecord(input: CreateDNSRecordInput!): DNSRecord!
  updateDNSRecord(id: ID!, input: UpdateDNSRecordInput!): DNSRecord!
  deleteDNSRecord(id: ID!): Boolean!

  # Branding
  uploadLogo(clientId: ID!, file: Upload!): String!
  updateTheme(clientId: ID!, theme: ThemeInput!): Theme!

  # Scripts
  executeScript(scriptName: String!, args: [String!]): ScriptResult!
}
```

#### Subscriptions
```graphql
type Subscription {
  # Real-time updates
  serviceStatusChanged: Service!
  logStream(service: String!): LogEntry!
  metricUpdated(service: String!): Metric!
  backupProgress: BackupProgress!
  alertCreated: Alert!
}
```

---

## Mobile App UI/UX Design

### Main Screens

#### 1. Dashboard
- System health overview
- Active clients count
- Service status grid (green/yellow/red)
- Recent alerts
- Quick actions (backup, restart service)

#### 2. Clients
- List of all clients
- Search and filter
- Status indicators
- Tap to view details
- + button to add new client

#### 3. Client Detail
- Client info (name, domain, status)
- Services for this client (ERP, portal, website)
- Users assigned to client
- Usage metrics
- Actions: restart, backup, settings

#### 4. Services
- All services across platform
- Filter by client or service type
- Start/stop/restart controls
- View logs
- Resource usage

#### 5. Users
- All SSO users
- Filter by group/client
- Add/edit/delete users
- Reset passwords
- View login history

#### 6. Monitoring
- Grafana-style graphs
- Service uptime
- Resource usage (CPU, memory, disk)
- Alert list
- Log viewer with search

#### 7. Backups
- Backup schedule
- Recent backups list
- Backup size and status
- Restore interface
- Backup now button

#### 8. DNS
- Zone list
- Record management
- Add/edit/delete records
- DNS health check

#### 9. Settings
- App preferences
- API endpoint configuration
- Authentication
- Notifications
- About/version

### UI Components

**Navigation:**
- Bottom navigation bar (5 tabs)
- Hamburger menu for additional options
- Floating action buttons for quick actions

**Design System:**
- Material Design 3
- Dark mode support
- Custom SecureNexus branding
- Color-coded status indicators
- Pull-to-refresh
- Swipe actions

---

## Implementation Phases

### Phase 1: Foundation (2-3 weeks)
**Backend API:**
- Set up Python FastAPI project
- Implement GraphQL schema (basic)
- Authentik OAuth integration
- Docker API client integration
- Basic queries (system status, services)

**Frontend App:**
- Flutter project setup
- Authentication flow
- Dashboard screen
- Service list screen
- GraphQL client setup

**Testing:**
- API endpoints working
- App can authenticate
- Can view system status

---

### Phase 2: Core Features (3-4 weeks)
**Backend:**
- Service control (start/stop/restart)
- Client management CRUD
- User management via Authentik API
- Metrics queries (Prometheus API)
- Log streaming

**Frontend:**
- Client management screens
- Service control interface
- User management
- Real-time updates (WebSocket)
- Error handling

**Testing:**
- Can manage clients from app
- Services respond to controls
- Metrics display correctly

---

### Phase 3: Advanced Features (3-4 weeks)
**Backend:**
- Backup management
- DNS management
- Script execution
- Branding/theme management
- Alert system

**Frontend:**
- Backup interface
- DNS management screens
- Script runner
- Theme customization
- Alert notifications

**Testing:**
- End-to-end workflows
- Performance optimization
- Security audit

---

### Phase 4: Polish & Deploy (2-3 weeks)
**Backend:**
- Rate limiting
- Caching optimization
- Error handling improvements
- API documentation

**Frontend:**
- UI polish
- Animations
- Offline support
- App store preparation
- User documentation

**Deployment:**
- API deployed as Docker service
- App builds (iOS, Android, Desktop)
- Beta testing with real users

---

## Technical Implementation Details

### Backend API (Python FastAPI)

**Project Structure:**
```
securenexus-api/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app
│   ├── schema.py            # GraphQL schema
│   ├── resolvers/           # GraphQL resolvers
│   │   ├── clients.py
│   │   ├── services.py
│   │   ├── users.py
│   │   ├── monitoring.py
│   │   └── backups.py
│   ├── services/            # Business logic
│   │   ├── docker.py        # Docker API client
│   │   ├── authentik.py     # Authentik API client
│   │   ├── prometheus.py    # Metrics queries
│   │   └── dns.py           # DNS management
│   ├── models/              # Data models
│   ├── auth/                # Authentication
│   └── utils/               # Helpers
├── Dockerfile
├── requirements.txt
└── README.md
```

**Key Dependencies:**
```python
# requirements.txt
fastapi==0.104.1
strawberry-graphql==0.214.0
uvicorn==0.24.0
python-jose==3.3.0  # JWT
docker==6.1.3
httpx==0.25.0  # HTTP client for Authentik
prometheus-client==0.19.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
redis==5.0.1
pydantic==2.5.0
```

**Example Resolver:**
```python
# app/resolvers/services.py
import strawberry
from typing import List
from app.services.docker import DockerService

@strawberry.type
class Service:
    name: str
    status: str
    image: str
    created: str
    ports: List[str]

@strawberry.type
class Query:
    @strawberry.field
    async def services(self) -> List[Service]:
        docker_client = DockerService()
        containers = await docker_client.list_containers()
        return [
            Service(
                name=c.name,
                status=c.status,
                image=c.image.tags[0],
                created=c.attrs['Created'],
                ports=[f"{p['PrivatePort']}/{p['Type']}"
                       for p in c.attrs['NetworkSettings']['Ports']]
            )
            for c in containers
        ]

@strawberry.type
class Mutation:
    @strawberry.field
    async def restart_service(self, name: str) -> Service:
        docker_client = DockerService()
        container = await docker_client.restart_container(name)
        return Service(...)  # Return updated service
```

---

### Frontend App (Flutter)

**Project Structure:**
```
securenexus_app/
├── lib/
│   ├── main.dart
│   ├── app.dart              # Root app widget
│   ├── config/               # App configuration
│   ├── core/
│   │   ├── graphql/          # GraphQL client
│   │   ├── auth/             # Authentication
│   │   └── theme/            # App theme
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   ├── clients/
│   │   ├── services/
│   │   ├── users/
│   │   ├── monitoring/
│   │   └── backups/
│   ├── shared/
│   │   ├── widgets/          # Reusable widgets
│   │   ├── models/           # Data models
│   │   └── utils/            # Helpers
│   └── l10n/                 # Localization
├── android/
├── ios/
├── linux/
├── windows/
├── macos/
├── pubspec.yaml
└── README.md
```

**Key Dependencies:**
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  riverpod: ^2.4.9
  flutter_riverpod: ^2.4.9

  # GraphQL
  graphql_flutter: ^5.1.2

  # HTTP & Auth
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  oauth2: ^2.0.2

  # UI
  material_design_3: ^3.0.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0

  # Charts & Graphs
  fl_chart: ^0.65.0

  # Utilities
  intl: ^0.18.1
  timeago: ^3.6.0
  url_launcher: ^6.2.2
```

**Example Screen:**
```dart
// lib/features/services/screens/services_screen.dart
class ServicesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Services'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => ref.refresh(servicesProvider),
          ),
        ],
      ),
      body: servicesAsync.when(
        data: (services) => ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return ServiceCard(
              service: service,
              onRestart: () => ref.read(servicesProvider.notifier)
                                  .restartService(service.name),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error: error),
      ),
    );
  }
}
```

---

## Deployment Architecture

### API Deployment (Docker)

```yaml
# Add to compose.yml
securenexus_api:
  build: ./securenexus-api
  image: securenexus/api:latest
  restart: unless-stopped
  networks: [proxy]
  environment:
    - DATABASE_URL=postgresql://...
    - REDIS_URL=redis://redis_cache:6379
    - AUTHENTIK_URL=https://sso.securenexus.net
    - AUTHENTIK_TOKEN=file:///run/secrets/api_authentik_token
    - DOCKER_HOST=tcp://docker-proxy:2375
    - JWT_SECRET=file:///run/secrets/api_jwt_secret
  secrets:
    - api_authentik_token
    - api_jwt_secret
  labels:
    - traefik.enable=true
    - traefik.http.routers.api.rule=Host(`api.securenexus.net`)
    - traefik.http.routers.api.entrypoints=websecure
    - traefik.http.routers.api.tls.certresolver=le
    - traefik.http.routers.api.middlewares=secure-headers@file,admin-vpn@file
    - traefik.http.services.api.loadbalancer.server.port=8000
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### App Distribution

**iOS:**
- Apple Developer account required
- TestFlight for beta testing
- App Store distribution

**Android:**
- Google Play Console
- Play Store distribution
- APK direct distribution option

**Desktop (Linux/Windows/macOS):**
- GitHub Releases
- Direct download from website
- Snap/Flatpak for Linux
- DMG for macOS
- MSI/EXE for Windows

---

## Security Considerations

### API Security
- ✅ OAuth 2.0 via Authentik
- ✅ JWT tokens with short expiration
- ✅ Role-based access control (RBAC)
- ✅ Rate limiting per user/IP
- ✅ HTTPS only (TLS 1.3)
- ✅ CORS properly configured
- ✅ Input validation and sanitization
- ✅ SQL injection protection (ORM)
- ✅ Audit logging

### App Security
- ✅ Secure storage for tokens
- ✅ Certificate pinning
- ✅ Biometric authentication
- ✅ Auto-logout on inactivity
- ✅ Encrypted local cache
- ✅ No sensitive data in logs

### Docker API Access
- ✅ Via docker-proxy (not direct socket)
- ✅ Read-only operations where possible
- ✅ Operations scoped to authorized clients
- ✅ Audit trail for all actions

---

## Comparison: SelfPrivacy vs SecureNexus App

| Feature | SelfPrivacy | SecureNexus App |
|---------|-------------|-----------------|
| **Target User** | Individual (personal use) | Business admin (service provider) |
| **Purpose** | Deploy personal services | Manage multi-tenant clients |
| **Infrastructure** | NixOS (immutable) | Docker Compose (flexible) |
| **Services** | Nextcloud, Gitea, Jitsi | ERPNext, Portainer, custom apps |
| **Complexity** | Simple (1 user, 1 server) | Complex (multi-client, isolation) |
| **Provisioning** | Automated NixOS config | Script-based with templates |
| **Business Logic** | Minimal | Client billing, usage tracking |
| **Authentication** | Built-in simple auth | Authentik SSO (enterprise) |
| **Monitoring** | Basic health checks | Full Prometheus/Grafana |
| **Target Scale** | 1-10 services | 10-100+ services |

---

## Development Roadmap

### Milestones

**M1: Proof of Concept (4 weeks)**
- Basic API with system status
- Simple Flutter app (dashboard only)
- Authentication working
- Demo: View services and system health

**M2: Core Functionality (6 weeks)**
- Client CRUD operations
- Service control (start/stop/restart)
- User management
- Demo: Provision new client from app

**M3: Advanced Features (6 weeks)**
- Monitoring integration
- Backup management
- DNS management
- Demo: Full workflow from provision to backup

**M4: Production Ready (4 weeks)**
- Security hardening
- Performance optimization
- Documentation
- App store submissions
- Demo: Ready for beta users

**Total Timeline: 20 weeks (~5 months)**

---

## Cost Estimate

### Development Costs
- **Backend Developer:** 12 weeks × $100/hr × 40hr = $48,000
- **Flutter Developer:** 16 weeks × $90/hr × 40hr = $57,600
- **UI/UX Designer:** 4 weeks × $80/hr × 20hr = $6,400
- **QA/Testing:** 4 weeks × $60/hr × 20hr = $4,800
- **Total Development:** ~$117,000

### Infrastructure Costs
- API hosting: $50/month (included in existing)
- App store fees: $99/year (Apple) + $25 (Google one-time)
- CI/CD: $20/month (GitHub Actions)

### Alternative: DIY Development
- **You + Claude AI:** 6-12 months part-time
- **Cost:** Minimal (your time + Claude subscription)
- **Trade-off:** Slower but full control

---

## Next Steps

### Option 1: Full Development
1. Approve proposal and architecture
2. Set up development environment
3. Create project repositories
4. Start with Phase 1 (Foundation)
5. Iterative development with regular demos

### Option 2: Prototype First
1. Build minimal API (just system status)
2. Build minimal Flutter app (dashboard only)
3. Validate concept and UX
4. Decide whether to continue

### Option 3: Gradual Enhancement
1. Keep existing CLI/scripts as primary
2. Build web dashboard first (simpler than mobile)
3. Add API incrementally
4. Mobile app later if web works well

---

## Recommendation

**Start with Option 2: Prototype**

**Why:**
1. Validate the concept quickly (2-3 weeks)
2. Lower risk and cost
3. Learn Flutter/GraphQL in practice
4. Get user feedback early
5. Can pivot if needed

**Prototype Scope:**
- Simple GraphQL API (system status, services list)
- Flutter app with 2 screens (login, dashboard)
- Authentication via Authentik
- Hosted on your existing infrastructure

**If prototype succeeds:**
- Proceed to full development
- Add features incrementally
- Release beta to select users
- Iterate based on feedback

---

## Conclusion

Building a SecureNexus Control App similar to SelfPrivacy is **absolutely feasible** and would provide significant value for managing your multi-tenant infrastructure. The key differences are:

1. **Business focus** vs personal use
2. **Multi-tenant complexity** vs single-user simplicity
3. **Docker Compose** vs NixOS (less disruptive)
4. **Enterprise features** (billing, usage tracking, RBAC)

The Flutter + GraphQL + Python stack used by SelfPrivacy is excellent and would work well for SecureNexus. Starting with a prototype is the safest approach to validate the concept before committing to full development.

**Would you like to start with a prototype?** I can help build the foundation:
1. GraphQL API (Python FastAPI)
2. Basic Flutter app
3. Integration with your existing infrastructure
4. Demo in 2-3 weeks

---

**Proposal Created:** November 6, 2025
**Status:** Ready for Review
**Next Action:** Approve scope and start prototype
