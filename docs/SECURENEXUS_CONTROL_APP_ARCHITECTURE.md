# SecureNexus Control App - Technical Architecture

**Version:** 1.0
**Date:** November 6, 2025
**Status:** Design Phase

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [System Components](#system-components)
3. [Data Flow](#data-flow)
4. [API Design](#api-design)
5. [Security Architecture](#security-architecture)
6. [Database Schema](#database-schema)
7. [Deployment Architecture](#deployment-architecture)
8. [Integration Points](#integration-points)

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Client Applications                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │   iOS    │  │ Android  │  │  Linux   │  │ Windows │ │
│  │   App    │  │   App    │  │Desktop   │  │ Desktop │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
│       │             │              │              │      │
│       └─────────────┴──────────────┴──────────────┘      │
│                         │                                │
│                    HTTPS/WSS                             │
│                         │                                │
└─────────────────────────┼────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────┐
│                 Traefik Reverse Proxy                     │
│              (SSL Termination, Routing)                   │
└─────────────────────────┬────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────┐
│              SecureNexus Control API                      │
│                  (FastAPI + GraphQL)                      │
│                                                           │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │   GraphQL   │  │     Auth     │  │   WebSocket    │  │
│  │   Endpoint  │  │  Middleware  │  │  Subscriptions │  │
│  └──────┬──────┘  └──────┬───────┘  └────────┬───────┘  │
│         │                │                    │          │
│         └────────────────┴────────────────────┘          │
│                          │                               │
│  ┌───────────────────────▼────────────────────────────┐  │
│  │            Business Logic Layer                     │  │
│  │  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │  │
│  │  │ Client  │ │ Service  │ │  User    │ │ Backup │ │  │
│  │  │ Manager │ │ Manager  │ │ Manager  │ │Manager │ │  │
│  │  └────┬────┘ └────┬─────┘ └────┬─────┘ └────┬───┘ │  │
│  └───────┼───────────┼────────────┼───────────┼──────┘  │
│          │           │            │           │         │
└──────────┼───────────┼────────────┼───────────┼─────────┘
           │           │            │           │
    ┌──────▼───┐   ┌──▼────┐   ┌───▼──────┐  ┌▼────────┐
    │PostgreSQL│   │ Docker│   │Authentik │  │  Redis  │
    │    DB    │   │  API  │   │   API    │  │  Cache  │
    └──────────┘   └──┬────┘   └──────────┘  └─────────┘
                      │
       ┌──────────────┼──────────────┐
       │              │              │
┌──────▼─────┐ ┌─────▼──────┐ ┌────▼──────┐
│  Traefik   │ │ Prometheus │ │  CoreDNS  │
│ Containers │ │   Metrics  │ │    DNS    │
└────────────┘ └────────────┘ └───────────┘
```

### Architecture Principles

1. **Separation of Concerns**
   - Clear boundaries between layers
   - Single responsibility per component
   - Loose coupling, high cohesion

2. **Scalability**
   - Stateless API (horizontal scaling)
   - Async operations for heavy tasks
   - Caching strategy at multiple levels

3. **Security First**
   - OAuth 2.0 authentication
   - JWT tokens with short expiration
   - Role-based access control (RBAC)
   - Audit logging for all operations

4. **Reliability**
   - Health checks at all levels
   - Graceful degradation
   - Retry logic with exponential backoff
   - Circuit breakers for external services

5. **Observability**
   - Structured logging
   - Distributed tracing
   - Metrics collection
   - Error tracking

---

## System Components

### 1. Flutter Mobile/Desktop App

**Purpose:** User interface for managing infrastructure

**Responsibilities:**
- User authentication
- UI rendering and navigation
- GraphQL query/mutation execution
- Real-time subscription handling
- Local state management
- Offline support (limited)
- Push notifications

**Technology:**
```yaml
Framework: Flutter 3.16+
Language: Dart 3.2+
State Management: Riverpod
GraphQL Client: graphql_flutter
Storage: flutter_secure_storage
```

**Key Features:**
- Material Design 3 UI
- Dark mode support
- Pull-to-refresh
- Swipe gestures
- Biometric authentication
- Offline caching

---

### 2. GraphQL API (FastAPI)

**Purpose:** Backend API serving client applications

**Responsibilities:**
- Request authentication & authorization
- GraphQL query/mutation resolution
- WebSocket subscription management
- Business logic orchestration
- Data validation
- Error handling
- Rate limiting

**Technology:**
```python
Framework: FastAPI 0.104+
GraphQL: strawberry-graphql 0.214+
ASGI Server: Uvicorn 0.24+
Database ORM: SQLAlchemy 2.0+
Caching: Redis
```

**Endpoints:**
```
POST /graphql         - GraphQL endpoint
GET  /graphql         - GraphQL Playground
WS   /graphql/ws      - GraphQL subscriptions
GET  /health          - Health check
GET  /metrics         - Prometheus metrics
GET  /docs            - Swagger documentation
```

---

### 3. Authentication Service (Authentik Integration)

**Purpose:** Handle user authentication and authorization

**Responsibilities:**
- OAuth 2.0 flow management
- JWT token validation
- User information retrieval
- Group membership checks
- Permission enforcement

**Integration:**
```
Protocol: OAuth 2.0 / OIDC
Token Type: JWT
Token Storage: Secure storage (client), Redis (server)
Token Expiry: 1 hour (access), 30 days (refresh)
```

**Flow:**
```
1. User opens app → Redirected to Authentik login
2. User authenticates → Authentik issues authorization code
3. App exchanges code → API validates and issues JWT
4. App includes JWT → API validates on each request
5. Token expires → App uses refresh token
```

---

### 4. Docker Management Service

**Purpose:** Interface with Docker API for container operations

**Responsibilities:**
- List containers
- Start/stop/restart containers
- View container logs
- Monitor resource usage
- Execute commands in containers
- Manage networks and volumes

**Technology:**
```python
Library: docker-py 6.1+
API Version: Docker Engine API v1.43
Connection: Via docker-proxy (secure)
```

**Operations:**
```python
# Container operations
containers.list()
container.start()
container.stop()
container.restart()
container.logs(stream=True)
container.stats()

# Image operations
images.list()
images.pull(tag)
images.prune()
```

---

### 5. Client Management Service

**Purpose:** Manage multi-tenant client environments

**Responsibilities:**
- Client CRUD operations
- Client provisioning workflow
- Service assignment
- User-client associations
- Resource allocation tracking
- Billing/usage tracking

**Data Model:**
```python
class Client:
    id: UUID
    name: str
    domain: str
    status: ClientStatus
    created_at: datetime
    services: List[Service]
    users: List[User]
    metadata: Dict[str, Any]
    billing_info: BillingInfo
```

**Workflows:**
```
Provision Client:
1. Validate input
2. Generate secrets
3. Create database entries
4. Execute provisioning script
5. Create DNS records
6. Generate SSL certificates
7. Deploy services
8. Configure SSO
9. Apply branding
10. Notify administrators
```

---

### 6. Service Management Service

**Purpose:** Control and monitor application services

**Responsibilities:**
- Service status monitoring
- Health check aggregation
- Performance metrics collection
- Service lifecycle management
- Configuration management

**Service Types:**
```
- ERP (ERPNext)
- Portal (Client portal)
- Website (Corporate site)
- Monitoring (Prometheus, Grafana)
- DNS (CoreDNS)
- Email (Mailcow)
```

---

### 7. Monitoring Integration Service

**Purpose:** Collect and display infrastructure metrics

**Responsibilities:**
- Prometheus query execution
- Metrics aggregation
- Alert management
- Dashboard data preparation
- Historical data retrieval

**Metrics Collected:**
```
System:
- CPU usage
- Memory usage
- Disk I/O
- Network traffic

Services:
- Container health
- Response times
- Request rates
- Error rates

Business:
- Active clients
- Service uptime
- User activity
```

---

### 8. Backup Management Service

**Purpose:** Handle backup and restore operations

**Responsibilities:**
- Trigger manual backups
- Schedule automated backups
- Monitor backup status
- List backup history
- Restore from backup
- Verify backup integrity

**Operations:**
```
Backup Workflow:
1. Pre-backup validation
2. Stop dependent services
3. Create database dumps
4. Archive volumes
5. Copy configuration
6. Encrypt sensitive data
7. Upload to storage
8. Restart services
9. Verify backup
10. Update status
```

---

### 9. DNS Management Service

**Purpose:** Manage DNS records for clients

**Responsibilities:**
- Zone management
- Record CRUD operations
- DNS health checks
- DNSSEC management
- Zone file validation

**Integration:**
```
Backend: CoreDNS + etcd
Operations:
- List zones
- Get/set records (A, CNAME, MX, TXT)
- Bulk operations
- Zone transfer
- Health checks
```

---

### 10. Audit Logging Service

**Purpose:** Track all system operations for compliance

**Responsibilities:**
- Log all API operations
- User action tracking
- Security event logging
- Compliance reporting
- Log retention management

**Log Format:**
```json
{
  "timestamp": "2025-11-06T18:00:00Z",
  "user_id": "user-123",
  "action": "client.create",
  "resource": "client-456",
  "ip_address": "203.0.113.1",
  "user_agent": "SecureNexus/1.0",
  "result": "success",
  "details": {...}
}
```

---

## Data Flow

### Request Flow (Query)

```
1. User Action in App
   ↓
2. GraphQL Query Generated
   ↓
3. HTTP Request to API
   ↓
4. Traefik SSL Termination & Routing
   ↓
5. FastAPI Receives Request
   ↓
6. JWT Token Validation
   ↓
7. Permission Check (RBAC)
   ↓
8. GraphQL Resolver Execution
   ↓
9. Business Logic Layer
   ↓
10. Data Fetching (DB/Docker/External API)
    ↓
11. Response Assembly
    ↓
12. JSON Response to Client
    ↓
13. UI Update in App
```

### Real-Time Update Flow (Subscription)

```
1. App Opens WebSocket Connection
   ↓
2. GraphQL Subscription Registered
   ↓
3. Event Occurs (e.g., container status change)
   ↓
4. Event Published to Redis Pub/Sub
   ↓
5. API Receives Event
   ↓
6. Subscription Filter Applied
   ↓
7. Event Sent Over WebSocket
   ↓
8. App Receives Update
   ↓
9. UI Updated Reactively
```

### Client Provisioning Flow

```
User Action: "Create Client"
   ↓
App: Collect client info (name, domain, etc.)
   ↓
API: Validate input
   ↓
API: Create database record (status: provisioning)
   ↓
API: Publish event → WebSocket update to app
   ↓
Background Task: Execute provision script
   ├→ Generate secrets
   ├→ Create volumes
   ├→ Deploy containers
   ├→ Configure DNS
   ├→ Request SSL certs
   ├→ Setup SSO
   └→ Apply branding
   ↓
API: Update status (status: active)
   ↓
API: Publish completion event → WebSocket
   ↓
App: Show success notification
```

---

## API Design

### GraphQL Schema (High-Level)

```graphql
# Root Types
type Query {
  # System
  systemStatus: SystemStatus!
  services: [Service!]!
  service(id: ID!): Service

  # Clients
  clients(filter: ClientFilter): [Client!]!
  client(id: ID!): Client

  # Users
  users(filter: UserFilter): [User!]!
  user(id: ID!): User
  groups: [Group!]!

  # Monitoring
  metrics(query: MetricsQuery!): MetricsResult!
  alerts(status: AlertStatus): [Alert!]!
  logs(filter: LogFilter!): LogResult!

  # Backups
  backups(clientId: ID): [Backup!]!
  backupStatus(id: ID!): BackupStatus!

  # DNS
  dnsZones: [DNSZone!]!
  dnsRecords(zone: String!): [DNSRecord!]!
}

type Mutation {
  # Client Management
  createClient(input: CreateClientInput!): Client!
  updateClient(id: ID!, input: UpdateClientInput!): Client!
  deleteClient(id: ID!): Boolean!

  # Service Control
  startService(id: ID!): Service!
  stopService(id: ID!): Service!
  restartService(id: ID!): Service!

  # User Management
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!

  # Backups
  createBackup(clientId: ID!): Backup!
  restoreBackup(id: ID!): RestoreResult!

  # DNS
  createDNSRecord(input: CreateDNSRecordInput!): DNSRecord!
  updateDNSRecord(id: ID!, input: UpdateDNSRecordInput!): DNSRecord!
  deleteDNSRecord(id: ID!): Boolean!

  # Scripts
  executeScript(name: String!, args: [String!]): ScriptResult!
}

type Subscription {
  # Real-time updates
  serviceStatusChanged(filter: ServiceFilter): Service!
  clientStatusChanged(clientId: ID): Client!
  logStream(serviceId: ID!): LogEntry!
  metricUpdated(query: MetricsQuery!): Metric!
  alertCreated: Alert!
  backupProgress(backupId: ID!): BackupProgress!
}
```

### Common Types

```graphql
# System
type SystemStatus {
  uptime: Int!
  version: String!
  containerCount: Int!
  clientCount: Int!
  cpuUsage: Float!
  memoryUsage: Float!
  diskUsage: Float!
  health: HealthStatus!
}

enum HealthStatus {
  HEALTHY
  DEGRADED
  UNHEALTHY
}

# Service
type Service {
  id: ID!
  name: String!
  type: ServiceType!
  status: ServiceStatus!
  image: String!
  created: DateTime!
  ports: [Port!]!
  resourceUsage: ResourceUsage!
  health: HealthCheck!
  logs: String
}

enum ServiceType {
  ERP
  PORTAL
  WEBSITE
  MONITORING
  DNS
  EMAIL
  DATABASE
  CACHE
}

enum ServiceStatus {
  RUNNING
  STOPPED
  RESTARTING
  ERROR
}

# Client
type Client {
  id: ID!
  name: String!
  domain: String!
  status: ClientStatus!
  services: [Service!]!
  users: [User!]!
  createdAt: DateTime!
  updatedAt: DateTime!
  metadata: JSON
}

enum ClientStatus {
  PROVISIONING
  ACTIVE
  SUSPENDED
  DELETED
}

# User
type User {
  id: ID!
  username: String!
  email: String!
  fullName: String!
  groups: [Group!]!
  clients: [Client!]!
  lastLogin: DateTime
  isActive: Boolean!
}

type Group {
  id: ID!
  name: String!
  permissions: [Permission!]!
  members: [User!]!
}
```

---

## Security Architecture

### Authentication Flow

```
┌─────────┐                                    ┌──────────┐
│  App    │                                    │Authentik │
└────┬────┘                                    └─────┬────┘
     │                                               │
     │ 1. Redirect to /authorize                    │
     ├──────────────────────────────────────────────>│
     │                                               │
     │              2. User Login                    │
     │                                               │
     │ 3. Authorization Code                         │
     │<──────────────────────────────────────────────┤
     │                                               │
     │                       ┌─────────┐             │
     │ 4. Exchange Code      │   API   │             │
     ├──────────────────────>│         │             │
     │                       └────┬────┘             │
     │                            │                  │
     │                            │ 5. Validate Code │
     │                            ├──────────────────>│
     │                            │                  │
     │                            │ 6. User Info     │
     │                            │<─────────────────┤
     │                            │                  │
     │ 7. JWT Access+Refresh      │                  │
     │<───────────────────────────┤                  │
     │                            │                  │
```

### Token Structure

**Access Token (JWT):**
```json
{
  "sub": "user-123",
  "email": "user@example.com",
  "name": "John Doe",
  "groups": ["admin", "client-byrne"],
  "permissions": ["read:clients", "write:services"],
  "exp": 1699383600,
  "iat": 1699380000
}
```

**Refresh Token:**
- Opaque token stored in Redis
- 30-day expiration
- One-time use (rotated on refresh)
- Revocable

### Authorization (RBAC)

**Roles:**
```
Super Admin:
  - Full system access
  - Can manage all clients
  - Can create/delete admins

Client Admin:
  - Manage assigned clients
  - Cannot access other clients
  - Can manage client users

Client User:
  - View own client only
  - Limited operations
  - Read-only access

Developer:
  - Full read access
  - Limited write access
  - For debugging/support
```

**Permission Checks:**
```python
@require_permission("write:clients")
async def create_client(info, input: CreateClientInput):
    # Check if user can create clients
    user = info.context.user
    if not user.has_permission("write:clients"):
        raise PermissionError("Insufficient permissions")

    # Additional check: can only create for own organization
    if input.org_id != user.org_id and not user.is_super_admin:
        raise PermissionError("Cannot create client for other organization")

    # Proceed with creation
    return await client_service.create(input)
```

### API Security

**Rate Limiting:**
```python
# Per-user limits
@rate_limit(requests=100, period=60)  # 100 req/min
async def query_resolver():
    pass

# Per-IP limits (unauthenticated)
@rate_limit(requests=10, period=60, by="ip")
async def login():
    pass
```

**Input Validation:**
```python
from pydantic import BaseModel, validator

class CreateClientInput(BaseModel):
    name: str
    domain: str

    @validator('domain')
    def validate_domain(cls, v):
        if not is_valid_domain(v):
            raise ValueError('Invalid domain format')
        return v.lower()
```

**SQL Injection Protection:**
- Use ORM (SQLAlchemy) for all queries
- Parameterized queries
- No raw SQL with user input

**XSS Protection:**
- Sanitize all user inputs
- Content-Security-Policy headers
- Escape output in templates

---

## Database Schema

### Core Tables

**clients:**
```sql
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'provisioning',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_clients_domain ON clients(domain);
```

**services:**
```sql
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    container_id VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'stopped',
    config JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_services_client ON services(client_id);
CREATE INDEX idx_services_status ON services(status);
```

**user_clients:**
```sql
CREATE TABLE user_clients (
    user_id VARCHAR(255) NOT NULL,  -- From Authentik
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, client_id)
);

CREATE INDEX idx_user_clients_user ON user_clients(user_id);
```

**audit_logs:**
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255) NOT NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    result VARCHAR(20) NOT NULL,
    details JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
```

---

## Deployment Architecture

### Docker Compose Configuration

```yaml
# Add to existing compose.yml
services:
  securenexus_api:
    build: ./securenexus-api
    image: securenexus/control-api:latest
    restart: unless-stopped
    networks: [proxy]
    environment:
      - DATABASE_URL=${API_DATABASE_URL}
      - REDIS_URL=redis://redis_cache:6379
      - AUTHENTIK_URL=https://sso.securenexus.net
      - AUTHENTIK_CLIENT_ID=${API_AUTHENTIK_CLIENT_ID}
      - AUTHENTIK_CLIENT_SECRET_FILE=/run/secrets/api_authentik_secret
      - DOCKER_HOST=tcp://docker-proxy:2375
      - JWT_SECRET_FILE=/run/secrets/api_jwt_secret
      - LOG_LEVEL=INFO
    secrets:
      - api_authentik_secret
      - api_jwt_secret
    labels:
      - traefik.enable=true
      - traefik.http.routers.api.rule=Host(`api.securenexus.net`)
      - traefik.http.routers.api.entrypoints=websecure
      - traefik.http.routers.api.tls.certresolver=le
      - traefik.http.routers.api.middlewares=secure-headers@file
      - traefik.http.services.api.loadbalancer.server.port=8000
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    depends_on:
      - authentik_db
      - redis_cache
      - docker-proxy

secrets:
  api_authentik_secret:
    file: ./secrets/api_authentik_secret.txt
  api_jwt_secret:
    file: ./secrets/api_jwt_secret.txt
```

---

## Integration Points

### 1. Docker API Integration

**Connection:**
```python
import docker

client = docker.DockerClient(base_url='tcp://docker-proxy:2375')
```

**Operations:**
```python
# List containers
containers = client.containers.list(all=True)

# Control container
container = client.containers.get('container-id')
container.start()
container.stop()
container.restart()

# Stream logs
for line in container.logs(stream=True, follow=True):
    yield line.decode('utf-8')

# Get stats
stats = container.stats(stream=False)
```

### 2. Authentik API Integration

**Endpoints Used:**
```
GET  /api/v3/core/users/           - List users
GET  /api/v3/core/users/{id}/      - Get user
POST /api/v3/core/users/           - Create user
PATCH /api/v3/core/users/{id}/     - Update user
GET  /api/v3/core/groups/          - List groups
POST /api/v3/core/groups/{id}/users/ - Add user to group
```

**Authentication:**
```python
import httpx

headers = {
    "Authorization": f"Bearer {authentik_token}"
}

async with httpx.AsyncClient() as client:
    response = await client.get(
        f"{authentik_url}/api/v3/core/users/",
        headers=headers
    )
```

### 3. Prometheus API Integration

**Query Execution:**
```python
async def get_cpu_usage(service_name: str) -> float:
    query = f'rate(container_cpu_usage_seconds_total{{name="{service_name}"}}[5m])'
    response = await prometheus_client.query(query)
    return response['data']['result'][0]['value'][1]
```

### 4. Redis Pub/Sub for Real-Time Updates

**Publisher (API):**
```python
import redis

redis_client = redis.Redis(host='redis_cache')

# Publish event
redis_client.publish('service:status', json.dumps({
    'service_id': 'service-123',
    'status': 'running'
}))
```

**Subscriber (WebSocket handler):**
```python
async def subscribe_to_updates():
    pubsub = redis_client.pubsub()
    pubsub.subscribe('service:status')

    for message in pubsub.listen():
        if message['type'] == 'message':
            yield json.loads(message['data'])
```

---

**Document Version:** 1.0
**Last Updated:** November 6, 2025
**Status:** Design Phase
**Next Review:** After prototype implementation
