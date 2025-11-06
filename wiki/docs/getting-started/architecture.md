# System Architecture

Comprehensive architecture documentation for the SecureNexus Full Stack platform.

## High-Level Architecture

```mermaid
graph TB
    subgraph "External Access"
        Internet[Internet]
        DNS[DNS: securenexus.net]
    end

    subgraph "Edge Layer"
        Traefik[Traefik Reverse Proxy<br/>SSL Termination<br/>Load Balancing]
        CrowdSec[CrowdSec<br/>Intrusion Detection]
        Firewall[UFW Firewall<br/>13 Ports Open]
    end

    subgraph "Identity & Auth"
        Authentik[Authentik SSO<br/>OIDC Provider]
        AuthDB[(PostgreSQL)]
        Redis[Redis Cache]
    end

    subgraph "Business Apps"
        ERPNext[ERPNext<br/>Multi-Tenant ERP]
        ERPDB[(MariaDB)]
        Mail[Mailcow<br/>Email Server]
    end

    subgraph "Monitoring"
        Prometheus[Prometheus<br/>Metrics Collection]
        Grafana[Grafana<br/>Dashboards]
        Loki[Loki<br/>Log Aggregation]
        Uptime[Uptime Kuma<br/>Status Monitoring]
    end

    subgraph "Infrastructure"
        DNS_Core[CoreDNS<br/>Authoritative DNS]
        ETCD[(etcd<br/>DNS Records)]
        Tailscale[Tailscale VPN<br/>Admin Access]
    end

    subgraph "Portal"
        Homarr[Homarr Portal<br/>Service Dashboard]
        Portainer[Portainer<br/>Container Management]
    end

    Internet --> DNS
    DNS --> Firewall
    Firewall --> Traefik
    Traefik --> CrowdSec

    CrowdSec --> Authentik
    CrowdSec --> ERPNext
    CrowdSec --> Mail
    CrowdSec --> Homarr

    Authentik --> AuthDB
    Authentik --> Redis

    ERPNext --> ERPDB
    ERPNext --> Mail

    Tailscale -.->|Admin Only| Grafana
    Tailscale -.->|Admin Only| Prometheus
    Tailscale -.->|Admin Only| Portainer

    Prometheus --> ERPNext
    Prometheus --> Traefik
    Prometheus --> Mail

    DNS_Core --> ETCD

    Grafana --> Prometheus
    Grafana --> Loki

    style Internet fill:#667eea
    style Traefik fill:#10b981
    style Authentik fill:#3b82f6
    style ERPNext fill:#f59e0b
    style Grafana fill:#8b5cf6
```

## Service Profiles

Services are organized into Docker Compose profiles for staged deployment:

### Core Profile

Essential infrastructure services that must start first:

- **docker-proxy**: Secure Docker API access for Traefik
- **traefik**: Reverse proxy and SSL termination
- **souin_redis**: Redis cache for HTTP caching
- **tailscale**: VPN service for admin access
- **crowdsec**: Intrusion detection service
- **crowdsec_bouncer**: Traefik bouncer integration

**Start Command**: `make up-core`

### Identity Profile

Authentication and SSO services:

- **authentik_db**: PostgreSQL database for Authentik
- **redis_cache**: Redis cache for session storage
- **authentik_server**: Main Authentik web server
- **authentik_worker**: Background job processor

**Dependencies**: Requires `core` profile
**Start Command**: `make up-identity`

### Portal Profile

User-facing portal and static sites:

- **landing**: Main landing page
- **homarr**: Service dashboard portal
- **wellknown**: `.well-known` directory server
- **brand-static**: Custom branding assets

**Dependencies**: Requires `core` profile
**Start Command**: `make up-portal`

### Monitoring Profile

Observability and monitoring stack:

- **prometheus**: Metrics collection and storage
- **blackbox**: Blackbox exporter for probing
- **loki**: Log aggregation
- **promtail**: Log shipping agent
- **grafana**: Visualization dashboards
- **cadvisor**: Container metrics
- **node-exporter**: System metrics
- **uptime-kuma**: Uptime monitoring

**Dependencies**: Requires `core` profile
**Start Command**: `make up-monitoring`

### DNS Profile

DNS infrastructure:

- **etcd**: Key-value store for DNS records
- **mysql-db**: MySQL database for CoreDNS plugin
- **coredns**: Authoritative DNS server
- **dns-updater**: Automatic DNS record updates
- **acme_webhook**: DNS-01 ACME challenge handler

**Dependencies**: Requires `core` profile
**Start Command**: `make up-dns`

## Network Architecture

All services communicate via the `proxy` Docker network:

```mermaid
graph LR
    subgraph "External"
        Client[Client Browser]
    end

    subgraph "proxy Network"
        Traefik[Traefik<br/>:80, :443]
        Service1[Authentik<br/>:9000]
        Service2[ERPNext<br/>:8000]
        Service3[Grafana<br/>:3000]
        DB1[(PostgreSQL<br/>:5432)]
        DB2[(MariaDB<br/>:3306)]
    end

    Client -->|HTTPS| Traefik
    Traefik -->|HTTP| Service1
    Traefik -->|HTTP| Service2
    Traefik -->|HTTP| Service3

    Service1 --> DB1
    Service2 --> DB2

    style Traefik fill:#10b981
    style Client fill:#667eea
```

### Internal DNS Resolution

Services use Docker's internal DNS (127.0.0.11) for container name resolution:

- `http://authentik_server:9000` - Authentik service
- `http://erpnext-backend:8000` - ERPNext service
- `authentik_db:5432` - PostgreSQL database
- `mariadb:3306` - MariaDB database

## Security Layers

### Middleware Chain

```mermaid
graph LR
    A[Client Request] --> B{Traefik Router}
    B --> C[redirect-to-https]
    C --> D[secure-headers]
    D --> E[crowdsec-fa]
    E --> F{Access Type}

    F -->|Public| G[Service]
    F -->|SSO| H[sso middleware]
    F -->|Admin| I[admin-vpn middleware]

    H --> G
    I --> J{VPN Check}
    J -->|Authorized| G
    J -->|Denied| K[403 Forbidden]

    style A fill:#667eea
    style G fill:#10b981
    style K fill:#ef4444
```

### Middleware Types

1. **redirect-to-https**: HTTP → HTTPS redirect
2. **secure-headers**: Security headers (HSTS, CSP, X-Frame-Options)
3. **crowdsec-fa**: CrowdSec intrusion prevention
4. **sso**: Authentik OIDC authentication
5. **admin-vpn**: Tailscale VPN-only access

### Service Access Control

| Service | Middleware Chain | Access Level |
|---------|-----------------|--------------|
| Homarr | secure-headers, crowdsec-fa | Public |
| ERPNext | secure-headers, crowdsec-fa | Public |
| Mailcow | secure-headers, crowdsec-fa | Public |
| Authentik | secure-headers, crowdsec-fa | Public |
| Grafana | secure-headers, admin-vpn | VPN Only |
| Prometheus | secure-headers, admin-vpn | VPN Only |
| Traefik Dashboard | secure-headers, admin-vpn | VPN Only |
| Portainer | secure-headers, admin-vpn | VPN Only |

## Data Flow

### User Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant T as Traefik
    participant A as Authentik
    participant S as Service
    participant D as PostgreSQL

    U->>T: Access service
    T->>A: Forward auth request
    A->>D: Check session
    D-->>A: Session data

    alt Session Valid
        A-->>T: Auth OK
        T->>S: Forward request
        S-->>U: Render page
    else No Session
        A-->>U: Redirect to login
        U->>A: Login credentials
        A->>D: Validate & create session
        D-->>A: Session token
        A-->>U: Redirect to service
        U->>T: Access service (with token)
        T->>S: Forward request
        S-->>U: Render page
    end
```

### SSL Certificate Flow

```mermaid
sequenceDiagram
    participant T as Traefik
    participant L as Let's Encrypt
    participant E as etcd
    participant C as CoreDNS

    Note over T: New domain detected
    T->>L: Request certificate (HTTP-01 or DNS-01)

    alt HTTP-01 Challenge
        L->>T: HTTP challenge
        T-->>L: Challenge response
    else DNS-01 Challenge
        L->>T: DNS challenge
        T->>E: Create TXT record
        E->>C: Serve TXT record
        C-->>L: DNS query response
    end

    L-->>T: Issue certificate
    T->>T: Store in acme.json
    Note over T: Auto-renew 30 days before expiry
```

## Storage Architecture

### Persistent Volumes

```
/var/lib/docker/volumes/
├── authentik_db/          # PostgreSQL data
├── mariadb/               # ERPNext database
├── redis-cache/           # Session cache
├── etcd-data/             # DNS records
├── prometheus-data/       # Metrics (30-day retention)
├── grafana-data/          # Dashboards & configs
├── loki-data/             # Logs
├── uptime-kuma/           # Uptime data
└── traefik-acme/          # SSL certificates
```

### Configuration Files

```
/home/tristian/securenexus-fullstack/
├── config/
│   ├── traefik.yml                    # Static config
│   └── dynamic/
│       ├── traefik_dynamic.yml        # Middlewares, routes
│       └── souin.yml                  # HTTP cache config
├── dns/
│   ├── Corefile                       # CoreDNS config
│   └── zones/
│       └── securenexus.net.zone       # Zone file
├── monitoring/
│   ├── prometheus.yml                 # Scrape configs
│   ├── alert_rules.yml                # Alert rules
│   └── dashboards/                    # Grafana dashboards
└── secrets/                           # Credentials
```

## Deployment Architecture

### Staged Deployment Sequence

```mermaid
graph TD
    A[Prerequisites] --> B[Generate Secrets]
    B --> C[Configure .env]
    C --> D[Setup Firewall]
    D --> E[Deploy Core Profile]

    E --> F[Deploy Identity Profile]
    E --> G[Deploy Portal Profile]
    E --> H[Deploy Monitoring Profile]
    E --> I[Deploy DNS Profile]

    F --> J[Configure Authentik]
    G --> K[Customize Homarr]
    H --> L[Setup Grafana]
    I --> M[Update DNS Records]

    J --> N[Production Ready]
    K --> N
    L --> N
    M --> N

    style A fill:#667eea
    style N fill:#10b981
```

## High Availability Considerations

While the current deployment is single-server, the architecture supports future HA expansion:

### Database Replication

- **PostgreSQL**: Can be configured with streaming replication
- **MariaDB**: Supports Galera cluster for multi-master
- **etcd**: Built-in clustering support

### Load Balancing

- **Traefik**: Can run multiple instances behind external load balancer
- **Authentik**: Stateless workers can scale horizontally
- **ERPNext**: Supports multiple backend containers with sticky sessions

### Backup & Recovery

See [Disaster Recovery](../security/overview.md#disaster-recovery) for:
- Automated backup rotation (7 daily / 4 weekly / 12 monthly)
- Database dumps
- Volume snapshots
- Configuration backups

## Resource Requirements

### Minimum Specifications

- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 100 GB SSD
- **Network**: 100 Mbps

### Recommended Specifications

- **CPU**: 8 cores
- **RAM**: 16 GB
- **Disk**: 250 GB NVMe SSD
- **Network**: 1 Gbps

### Per-Service Resource Limits

| Service | CPU Limit | Memory Limit | Memory Reservation |
|---------|-----------|--------------|-------------------|
| Prometheus | No limit | 2 GB | 1 GB |
| Grafana | No limit | 512 MB | 256 MB |
| MariaDB | No limit | 2 GB | 1 GB |
| PostgreSQL | No limit | 1 GB | 512 MB |
| ERPNext | No limit | 3 GB | 1.5 GB |

## Next Steps

- **[Infrastructure Details](../infrastructure/overview.md)**: Deep dive into DNS, VPN, firewall
- **[Security Architecture](../security/overview.md)**: Security hardening and policies
- **[Monitoring Setup](../monitoring/overview.md)**: Metrics, logs, and alerts
