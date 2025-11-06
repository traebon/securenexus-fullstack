# PrivateNexus API Specification

**Version:** 1.0.0
**Date:** November 6, 2025
**Protocol:** GraphQL over HTTP/WebSocket
**Authentication:** OAuth 2.0 via Authentik

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [GraphQL Schema](#graphql-schema)
4. [Queries](#queries)
5. [Mutations](#mutations)
6. [Subscriptions](#subscriptions)
7. [Types](#types)
8. [Enums](#enums)
9. [Error Handling](#error-handling)
10. [Rate Limiting](#rate-limiting)
11. [Examples](#examples)

---

## Overview

The PrivateNexus API provides a unified GraphQL interface for managing self-hosted infrastructure. The API is designed with privacy and security as core principles, using open source technologies throughout.

**Base URL:** `https://api.privatenexus.net/graphql`
**WebSocket URL:** `wss://api.privatenexus.net/graphql`

**Key Features:**
- Type-safe GraphQL API
- Real-time updates via subscriptions
- OAuth 2.0 authentication
- Comprehensive error handling
- Rate limiting and abuse prevention
- Private and secure by default

---

## Authentication

### OAuth 2.0 Flow

PrivateNexus uses OAuth 2.0 with Authentik as the identity provider.

**Authorization Endpoint:**
`https://auth.privatenexus.net/application/o/authorize/`

**Token Endpoint:**
`https://auth.privatenexus.net/application/o/token/`

**Scopes:**
- `privatenexus:read` - Read access to infrastructure data
- `privatenexus:write` - Write access to modify infrastructure
- `privatenexus:admin` - Administrative operations
- `openid` - OpenID Connect authentication
- `profile` - User profile information
- `email` - User email address

### Request Authentication

Include the access token in the Authorization header:

```http
Authorization: Bearer <access_token>
```

### Token Refresh

```http
POST /application/o/token/
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&
refresh_token=<refresh_token>&
client_id=<client_id>
```

---

## GraphQL Schema

### Complete Schema Definition

```graphql
# Root Query Type
type Query {
  # User & System
  me: User!
  systemInfo: SystemInfo!

  # Clients
  clients(filter: ClientFilter, pagination: PaginationInput): ClientConnection!
  client(id: ID!): Client

  # Services
  services(clientId: ID!, filter: ServiceFilter, pagination: PaginationInput): ServiceConnection!
  service(id: ID!): Service

  # Containers
  containers(serviceId: ID!, filter: ContainerFilter): [Container!]!
  container(id: ID!): Container

  # Metrics
  metrics(target: MetricsTarget!, timeRange: TimeRange!): MetricsData!

  # Backups
  backups(clientId: ID!, pagination: PaginationInput): BackupConnection!
  backup(id: ID!): Backup

  # Alerts
  alerts(severity: AlertSeverity, state: AlertState): [Alert!]!
  alert(id: ID!): Alert

  # SSL Certificates
  certificates(clientId: ID): [Certificate!]!
  certificate(domain: String!): Certificate

  # DNS Records
  dnsRecords(zone: String!, filter: DNSRecordFilter): [DNSRecord!]!
  dnsRecord(id: ID!): DNSRecord

  # Logs
  logs(query: LogQuery!): LogConnection!
}

# Root Mutation Type
type Mutation {
  # Client Management
  createClient(input: CreateClientInput!): ClientMutationPayload!
  updateClient(id: ID!, input: UpdateClientInput!): ClientMutationPayload!
  deleteClient(id: ID!): DeletePayload!

  # Service Management
  createService(input: CreateServiceInput!): ServiceMutationPayload!
  updateService(id: ID!, input: UpdateServiceInput!): ServiceMutationPayload!
  deleteService(id: ID!): DeletePayload!
  startService(id: ID!): ServiceMutationPayload!
  stopService(id: ID!): ServiceMutationPayload!
  restartService(id: ID!): ServiceMutationPayload!

  # Container Management
  startContainer(id: ID!): ContainerMutationPayload!
  stopContainer(id: ID!): ContainerMutationPayload!
  restartContainer(id: ID!): ContainerMutationPayload!

  # Backup Management
  createBackup(clientId: ID!, description: String): BackupMutationPayload!
  restoreBackup(id: ID!): BackupMutationPayload!
  deleteBackup(id: ID!): DeletePayload!

  # DNS Management
  createDNSRecord(input: CreateDNSRecordInput!): DNSRecordMutationPayload!
  updateDNSRecord(id: ID!, input: UpdateDNSRecordInput!): DNSRecordMutationPayload!
  deleteDNSRecord(id: ID!): DeletePayload!

  # Certificate Management
  renewCertificate(domain: String!): CertificateMutationPayload!

  # Alert Management
  acknowledgeAlert(id: ID!): AlertMutationPayload!
  resolveAlert(id: ID!): AlertMutationPayload!
}

# Root Subscription Type
type Subscription {
  # Container Events
  containerEvents(serviceId: ID): ContainerEvent!

  # Service Status
  serviceStatusChanged(clientId: ID): ServiceStatusEvent!

  # Metrics Updates
  metricsUpdated(target: MetricsTarget!): MetricsData!

  # Alert Events
  alertTriggered(severity: AlertSeverity): Alert!

  # Backup Progress
  backupProgress(backupId: ID!): BackupProgressEvent!

  # Log Stream
  logStream(query: LogQuery!): LogEntry!
}
```

---

## Queries

### User & System

#### me
Get current authenticated user information.

```graphql
query Me {
  me {
    id
    username
    email
    fullName
    role
    permissions
    createdAt
    lastLogin
  }
}
```

#### systemInfo
Get system information and health status.

```graphql
query SystemInfo {
  systemInfo {
    version
    uptime
    totalContainers
    runningContainers
    totalClients
    cpuUsage
    memoryUsage
    diskUsage
    health
  }
}
```

---

### Clients

#### clients
List all clients with filtering and pagination.

```graphql
query Clients($filter: ClientFilter, $pagination: PaginationInput) {
  clients(filter: $filter, pagination: $pagination) {
    edges {
      node {
        id
        name
        domain
        status
        servicesCount
        createdAt
        updatedAt
      }
      cursor
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
    totalCount
  }
}
```

**Variables:**
```json
{
  "filter": {
    "status": "ACTIVE",
    "search": "byrne"
  },
  "pagination": {
    "first": 10,
    "after": "cursor123"
  }
}
```

#### client
Get single client by ID.

```graphql
query Client($id: ID!) {
  client(id: $id) {
    id
    name
    domain
    status
    email
    services {
      id
      name
      type
      status
    }
    metrics {
      cpuUsage
      memoryUsage
      networkIn
      networkOut
    }
    createdAt
    updatedAt
  }
}
```

---

### Services

#### services
List services for a client.

```graphql
query Services($clientId: ID!, $filter: ServiceFilter) {
  services(clientId: $clientId, filter: $filter) {
    edges {
      node {
        id
        name
        type
        status
        url
        version
        healthStatus
        containers {
          id
          name
          status
        }
      }
    }
    totalCount
  }
}
```

#### service
Get single service by ID.

```graphql
query Service($id: ID!) {
  service(id: $id) {
    id
    name
    type
    status
    url
    version
    image
    ports
    environment
    healthStatus
    containers {
      id
      name
      status
      image
      created
      started
      uptime
      restartCount
      resources {
        cpuPercent
        memoryUsage
        memoryLimit
        networkRx
        networkTx
      }
    }
    metrics {
      cpuUsage
      memoryUsage
      requestRate
      errorRate
    }
    createdAt
    updatedAt
  }
}
```

---

### Containers

#### containers
List containers for a service.

```graphql
query Containers($serviceId: ID!) {
  containers(serviceId: $serviceId) {
    id
    name
    status
    state
    image
    created
    started
    uptime
    restartCount
    ports {
      private
      public
      type
    }
    resources {
      cpuPercent
      memoryUsage
      memoryLimit
      memoryPercent
      networkRx
      networkTx
      blockRead
      blockWrite
    }
    health {
      status
      failingStreak
      log {
        start
        end
        exitCode
        output
      }
    }
  }
}
```

#### container
Get single container by ID.

```graphql
query Container($id: ID!) {
  container(id: $id) {
    id
    name
    status
    state
    image
    created
    started
    finished
    uptime
    restartCount
    exitCode
    error
    ports {
      private
      public
      type
    }
    mounts {
      type
      source
      destination
      mode
      rw
    }
    networks {
      name
      ipAddress
      gateway
      macAddress
    }
    resources {
      cpuPercent
      memoryUsage
      memoryLimit
      memoryPercent
      networkRx
      networkTx
      blockRead
      blockWrite
      pids
    }
    health {
      status
      failingStreak
      log {
        start
        end
        exitCode
        output
      }
    }
    labels
    environment
    command
    entrypoint
  }
}
```

---

### Metrics

#### metrics
Get metrics for a target over a time range.

```graphql
query Metrics($target: MetricsTarget!, $timeRange: TimeRange!) {
  metrics(target: $target, timeRange: $timeRange) {
    target {
      type
      id
      name
    }
    timeRange {
      start
      end
      step
    }
    series {
      metric
      values {
        timestamp
        value
      }
    }
  }
}
```

**Variables:**
```json
{
  "target": {
    "type": "SERVICE",
    "id": "service_123"
  },
  "timeRange": {
    "start": "2025-11-06T00:00:00Z",
    "end": "2025-11-06T23:59:59Z",
    "step": "5m"
  }
}
```

---

### Backups

#### backups
List backups for a client.

```graphql
query Backups($clientId: ID!, $pagination: PaginationInput) {
  backups(clientId: $clientId, pagination: $pagination) {
    edges {
      node {
        id
        type
        status
        size
        description
        createdAt
        completedAt
        expiresAt
      }
    }
    totalCount
  }
}
```

#### backup
Get single backup by ID.

```graphql
query Backup($id: ID!) {
  backup(id: $id) {
    id
    clientId
    type
    status
    size
    description
    manifest {
      databases
      volumes
      configs
      secrets
    }
    createdAt
    completedAt
    expiresAt
    error
  }
}
```

---

### Alerts

#### alerts
List active alerts.

```graphql
query Alerts($severity: AlertSeverity, $state: AlertState) {
  alerts(severity: $severity, state: $state) {
    id
    name
    severity
    state
    message
    labels
    annotations
    startsAt
    endsAt
    acknowledgedAt
    acknowledgedBy {
      id
      username
    }
    generatorURL
    fingerprint
  }
}
```

---

### SSL Certificates

#### certificates
List SSL certificates.

```graphql
query Certificates($clientId: ID) {
  certificates(clientId: $clientId) {
    id
    domain
    altNames
    issuer
    notBefore
    notAfter
    daysUntilExpiry
    autoRenew
    status
  }
}
```

---

### DNS Records

#### dnsRecords
List DNS records for a zone.

```graphql
query DNSRecords($zone: String!, $filter: DNSRecordFilter) {
  dnsRecords(zone: $zone, filter: $filter) {
    id
    zone
    name
    type
    ttl
    value
    priority
    weight
    port
    createdAt
    updatedAt
  }
}
```

---

### Logs

#### logs
Query logs with filtering.

```graphql
query Logs($query: LogQuery!) {
  logs(query: $query) {
    edges {
      node {
        timestamp
        level
        service
        container
        message
        labels
      }
    }
    totalCount
  }
}
```

**Variables:**
```json
{
  "query": {
    "services": ["authentik", "traefik"],
    "level": "ERROR",
    "timeRange": {
      "start": "2025-11-06T00:00:00Z",
      "end": "2025-11-06T23:59:59Z"
    },
    "limit": 100
  }
}
```

---

## Mutations

### Client Management

#### createClient
Create a new client.

```graphql
mutation CreateClient($input: CreateClientInput!) {
  createClient(input: $input) {
    client {
      id
      name
      domain
      status
      createdAt
    }
    errors {
      field
      message
    }
  }
}
```

**Variables:**
```json
{
  "input": {
    "name": "Acme Corp",
    "domain": "acme.com",
    "email": "admin@acme.com",
    "services": ["ERP", "PORTAL"]
  }
}
```

#### updateClient
Update existing client.

```graphql
mutation UpdateClient($id: ID!, $input: UpdateClientInput!) {
  updateClient(id: $id, input: $input) {
    client {
      id
      name
      domain
      email
      updatedAt
    }
    errors {
      field
      message
    }
  }
}
```

#### deleteClient
Delete a client (soft delete).

```graphql
mutation DeleteClient($id: ID!) {
  deleteClient(id: $id) {
    success
    message
    errors {
      field
      message
    }
  }
}
```

---

### Service Management

#### createService
Deploy a new service for a client.

```graphql
mutation CreateService($input: CreateServiceInput!) {
  createService(input: $input) {
    service {
      id
      name
      type
      status
      url
    }
    errors {
      field
      message
    }
  }
}
```

**Variables:**
```json
{
  "input": {
    "clientId": "client_123",
    "type": "ERP",
    "name": "ERPNext Production",
    "domain": "erp.acme.com",
    "config": {
      "sso": true,
      "branding": {
        "logo": "https://acme.com/logo.png",
        "primaryColor": "#3b82f6"
      }
    }
  }
}
```

#### updateService
Update service configuration.

```graphql
mutation UpdateService($id: ID!, $input: UpdateServiceInput!) {
  updateService(id: $id, input: $input) {
    service {
      id
      name
      config
      updatedAt
    }
    errors {
      field
      message
    }
  }
}
```

#### startService
Start a service.

```graphql
mutation StartService($id: ID!) {
  startService(id: $id) {
    service {
      id
      status
    }
    errors {
      field
      message
    }
  }
}
```

#### stopService
Stop a service.

```graphql
mutation StopService($id: ID!) {
  stopService(id: $id) {
    service {
      id
      status
    }
    errors {
      field
      message
    }
  }
}
```

#### restartService
Restart a service.

```graphql
mutation RestartService($id: ID!) {
  restartService(id: $id) {
    service {
      id
      status
    }
    errors {
      field
      message
    }
  }
}
```

---

### Backup Management

#### createBackup
Create a manual backup.

```graphql
mutation CreateBackup($clientId: ID!, $description: String) {
  createBackup(clientId: $clientId, description: $description) {
    backup {
      id
      status
      createdAt
    }
    errors {
      field
      message
    }
  }
}
```

#### restoreBackup
Restore from a backup.

```graphql
mutation RestoreBackup($id: ID!) {
  restoreBackup(id: $id) {
    backup {
      id
      status
    }
    errors {
      field
      message
    }
  }
}
```

---

### DNS Management

#### createDNSRecord
Create a DNS record.

```graphql
mutation CreateDNSRecord($input: CreateDNSRecordInput!) {
  createDNSRecord(input: $input) {
    record {
      id
      zone
      name
      type
      value
    }
    errors {
      field
      message
    }
  }
}
```

**Variables:**
```json
{
  "input": {
    "zone": "acme.com",
    "name": "www",
    "type": "A",
    "value": "192.0.2.1",
    "ttl": 3600
  }
}
```

#### updateDNSRecord
Update a DNS record.

```graphql
mutation UpdateDNSRecord($id: ID!, $input: UpdateDNSRecordInput!) {
  updateDNSRecord(id: $id, input: $input) {
    record {
      id
      value
      ttl
      updatedAt
    }
    errors {
      field
      message
    }
  }
}
```

---

## Subscriptions

### containerEvents
Real-time container events.

```graphql
subscription ContainerEvents($serviceId: ID) {
  containerEvents(serviceId: $serviceId) {
    type
    container {
      id
      name
      status
      state
    }
    timestamp
  }
}
```

**Event Types:**
- `STARTED`
- `STOPPED`
- `RESTARTED`
- `DIED`
- `HEALTH_STATUS_CHANGED`
- `RESOURCE_THRESHOLD_EXCEEDED`

---

### serviceStatusChanged
Service status changes.

```graphql
subscription ServiceStatusChanged($clientId: ID) {
  serviceStatusChanged(clientId: $clientId) {
    service {
      id
      name
      status
      healthStatus
    }
    previousStatus
    timestamp
  }
}
```

---

### metricsUpdated
Real-time metrics updates.

```graphql
subscription MetricsUpdated($target: MetricsTarget!) {
  metricsUpdated(target: $target) {
    target {
      type
      id
      name
    }
    series {
      metric
      values {
        timestamp
        value
      }
    }
  }
}
```

---

### alertTriggered
Alert events.

```graphql
subscription AlertTriggered($severity: AlertSeverity) {
  alertTriggered(severity: $severity) {
    id
    name
    severity
    state
    message
    startsAt
  }
}
```

---

### backupProgress
Backup progress updates.

```graphql
subscription BackupProgress($backupId: ID!) {
  backupProgress(backupId: $backupId) {
    backupId
    status
    progress
    currentStep
    totalSteps
    message
    timestamp
  }
}
```

---

### logStream
Real-time log streaming.

```graphql
subscription LogStream($query: LogQuery!) {
  logStream(query: $query) {
    timestamp
    level
    service
    container
    message
    labels
  }
}
```

---

## Types

### User
```graphql
type User {
  id: ID!
  username: String!
  email: String!
  fullName: String
  role: UserRole!
  permissions: [String!]!
  createdAt: DateTime!
  lastLogin: DateTime
}
```

### SystemInfo
```graphql
type SystemInfo {
  version: String!
  uptime: Int!
  totalContainers: Int!
  runningContainers: Int!
  totalClients: Int!
  cpuUsage: Float!
  memoryUsage: Float!
  diskUsage: Float!
  health: HealthStatus!
}
```

### Client
```graphql
type Client {
  id: ID!
  name: String!
  domain: String!
  email: String!
  status: ClientStatus!
  services: [Service!]!
  servicesCount: Int!
  metrics: ClientMetrics
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

### Service
```graphql
type Service {
  id: ID!
  clientId: ID!
  client: Client!
  name: String!
  type: ServiceType!
  status: ServiceStatus!
  url: String
  version: String
  image: String
  ports: [String!]
  environment: JSON
  healthStatus: HealthStatus!
  containers: [Container!]!
  metrics: ServiceMetrics
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

### Container
```graphql
type Container {
  id: ID!
  serviceId: ID!
  service: Service!
  name: String!
  status: String!
  state: ContainerState!
  image: String!
  created: DateTime!
  started: DateTime
  finished: DateTime
  uptime: Int
  restartCount: Int!
  exitCode: Int
  error: String
  ports: [PortMapping!]
  mounts: [Mount!]
  networks: [NetworkSettings!]
  resources: ContainerResources
  health: ContainerHealth
  labels: JSON
  environment: [String!]
  command: [String!]
  entrypoint: [String!]
}
```

### ContainerResources
```graphql
type ContainerResources {
  cpuPercent: Float!
  memoryUsage: Int!
  memoryLimit: Int!
  memoryPercent: Float!
  networkRx: Int!
  networkTx: Int!
  blockRead: Int!
  blockWrite: Int!
  pids: Int!
}
```

### Alert
```graphql
type Alert {
  id: ID!
  name: String!
  severity: AlertSeverity!
  state: AlertState!
  message: String!
  labels: JSON!
  annotations: JSON!
  startsAt: DateTime!
  endsAt: DateTime
  acknowledgedAt: DateTime
  acknowledgedBy: User
  generatorURL: String
  fingerprint: String!
}
```

### Backup
```graphql
type Backup {
  id: ID!
  clientId: ID!
  client: Client!
  type: BackupType!
  status: BackupStatus!
  size: Int
  description: String
  manifest: BackupManifest
  createdAt: DateTime!
  completedAt: DateTime
  expiresAt: DateTime
  error: String
}
```

### Certificate
```graphql
type Certificate {
  id: ID!
  domain: String!
  altNames: [String!]
  issuer: String!
  notBefore: DateTime!
  notAfter: DateTime!
  daysUntilExpiry: Int!
  autoRenew: Boolean!
  status: CertificateStatus!
}
```

### DNSRecord
```graphql
type DNSRecord {
  id: ID!
  zone: String!
  name: String!
  type: DNSRecordType!
  ttl: Int!
  value: String!
  priority: Int
  weight: Int
  port: Int
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

---

## Enums

### UserRole
```graphql
enum UserRole {
  ADMIN
  MANAGER
  VIEWER
}
```

### ClientStatus
```graphql
enum ClientStatus {
  ACTIVE
  SUSPENDED
  DELETED
}
```

### ServiceType
```graphql
enum ServiceType {
  ERP
  PORTAL
  WEBMAIL
  CUSTOM
}
```

### ServiceStatus
```graphql
enum ServiceStatus {
  RUNNING
  STOPPED
  STARTING
  STOPPING
  ERROR
  UNKNOWN
}
```

### HealthStatus
```graphql
enum HealthStatus {
  HEALTHY
  DEGRADED
  UNHEALTHY
  UNKNOWN
}
```

### ContainerState
```graphql
enum ContainerState {
  CREATED
  RUNNING
  PAUSED
  RESTARTING
  REMOVING
  EXITED
  DEAD
}
```

### AlertSeverity
```graphql
enum AlertSeverity {
  CRITICAL
  WARNING
  INFO
}
```

### AlertState
```graphql
enum AlertState {
  FIRING
  ACKNOWLEDGED
  RESOLVED
}
```

### BackupType
```graphql
enum BackupType {
  FULL
  INCREMENTAL
  MANUAL
}
```

### BackupStatus
```graphql
enum BackupStatus {
  PENDING
  IN_PROGRESS
  COMPLETED
  FAILED
}
```

### CertificateStatus
```graphql
enum CertificateStatus {
  VALID
  EXPIRING_SOON
  EXPIRED
  REVOKED
}
```

### DNSRecordType
```graphql
enum DNSRecordType {
  A
  AAAA
  CNAME
  MX
  TXT
  NS
  SOA
  SRV
  CAA
}
```

---

## Error Handling

### Error Types

All errors follow a consistent structure:

```graphql
type Error {
  field: String
  message: String!
  code: ErrorCode!
}

enum ErrorCode {
  VALIDATION_ERROR
  NOT_FOUND
  UNAUTHORIZED
  FORBIDDEN
  INTERNAL_ERROR
  RATE_LIMIT_EXCEEDED
  SERVICE_UNAVAILABLE
}
```

### Error Response Example

```json
{
  "data": {
    "createClient": null
  },
  "errors": [
    {
      "message": "Validation failed",
      "extensions": {
        "code": "VALIDATION_ERROR",
        "field": "domain",
        "details": "Domain name is already in use"
      }
    }
  ]
}
```

### HTTP Status Codes

- `200 OK` - Successful GraphQL query/mutation (even if errors in response)
- `400 Bad Request` - Invalid GraphQL syntax
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - Insufficient permissions
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

---

## Rate Limiting

### Limits

- **Anonymous**: 100 requests/hour
- **Authenticated**: 1,000 requests/hour
- **Admin**: 10,000 requests/hour

### Headers

Response includes rate limit headers:

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 987
X-RateLimit-Reset: 1699296000
```

### Rate Limit Exceeded Response

```json
{
  "errors": [
    {
      "message": "Rate limit exceeded",
      "extensions": {
        "code": "RATE_LIMIT_EXCEEDED",
        "retryAfter": 3600
      }
    }
  ]
}
```

---

## Examples

### Complete Client Onboarding Flow

```graphql
# 1. Create client
mutation {
  createClient(input: {
    name: "Acme Corp"
    domain: "acme.com"
    email: "admin@acme.com"
    services: [ERP, PORTAL]
  }) {
    client {
      id
      name
      status
    }
  }
}

# 2. Create ERP service
mutation {
  createService(input: {
    clientId: "client_123"
    type: ERP
    name: "ERPNext Production"
    domain: "erp.acme.com"
    config: {
      sso: true
      branding: {
        logo: "https://acme.com/logo.png"
        primaryColor: "#3b82f6"
      }
    }
  }) {
    service {
      id
      url
      status
    }
  }
}

# 3. Monitor deployment progress
subscription {
  serviceStatusChanged(clientId: "client_123") {
    service {
      id
      name
      status
      healthStatus
    }
  }
}

# 4. Create DNS records
mutation {
  createDNSRecord(input: {
    zone: "acme.com"
    name: "erp"
    type: A
    value: "192.0.2.1"
    ttl: 3600
  }) {
    record {
      id
      name
      value
    }
  }
}

# 5. Verify service health
query {
  service(id: "service_456") {
    name
    status
    healthStatus
    url
    containers {
      id
      name
      status
      health {
        status
      }
    }
  }
}
```

### Real-time Monitoring Dashboard

```graphql
# Query current state
query DashboardData {
  systemInfo {
    totalContainers
    runningContainers
    cpuUsage
    memoryUsage
  }

  clients(pagination: { first: 10 }) {
    edges {
      node {
        id
        name
        status
        services {
          id
          name
          status
        }
      }
    }
  }

  alerts(state: FIRING) {
    id
    name
    severity
    message
  }
}

# Subscribe to updates
subscription DashboardUpdates {
  alertTriggered {
    id
    name
    severity
    message
  }

  serviceStatusChanged {
    service {
      id
      name
      status
    }
  }
}
```

### Backup and Restore

```graphql
# Create backup
mutation {
  createBackup(
    clientId: "client_123"
    description: "Pre-upgrade backup"
  ) {
    backup {
      id
      status
    }
  }
}

# Monitor progress
subscription {
  backupProgress(backupId: "backup_789") {
    status
    progress
    currentStep
    message
  }
}

# Restore backup
mutation {
  restoreBackup(id: "backup_789") {
    backup {
      id
      status
    }
  }
}
```

---

## Security Best Practices

1. **Always use HTTPS** - Never send requests over HTTP
2. **Rotate tokens regularly** - Refresh access tokens every 24 hours
3. **Use minimal scopes** - Request only necessary permissions
4. **Validate input** - Client-side validation before sending mutations
5. **Handle errors gracefully** - Never expose sensitive information
6. **Rate limit awareness** - Implement exponential backoff
7. **Secure storage** - Store tokens in secure storage (not localStorage)
8. **Monitor suspicious activity** - Watch for unauthorized access attempts

---

**Version:** 1.0.0
**Last Updated:** November 6, 2025
**Contact:** api@privatenexus.net
**Documentation:** https://docs.privatenexus.net
