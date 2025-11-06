# PrivateNexus

**Private and Secure by Default**

> A self-hosted infrastructure control application built with privacy and security at its core, using open source technology.

---

## Overview

PrivateNexus is a cross-platform mobile and desktop application for managing self-hosted infrastructure. Inspired by privacy-focused solutions like SelfPrivacy, PrivateNexus provides a unified interface to control your clients, services, containers, backups, and monitoring - all while keeping your data private and under your control.

**Key Principles:**
- 🔒 **Private by Default** - All data stays on your infrastructure
- 🛡️ **Secure by Default** - Enterprise-grade security built-in
- 🌐 **Open Source First** - Built on proven open source technologies
- 🎯 **Self-Hosted** - Complete control over your infrastructure
- 📱 **Cross-Platform** - Mobile (iOS/Android) and Desktop (Linux/macOS/Windows)

---

## Features

### Client Management
- Create and manage multiple client deployments
- Client-specific branding and customization
- Complete data isolation per client
- One-command provisioning and deployment
- Multi-tenant architecture support

### Service Deployment
- Deploy ERPNext, portals, webmail, and custom services
- Automatic SSL certificate management
- DNS configuration and management
- SSO integration via Authentik OAuth 2.0
- Custom branding per service

### Container Monitoring
- Real-time container status and health
- Resource usage monitoring (CPU, memory, network, disk)
- Container logs and event streaming
- Start, stop, restart operations
- Health check monitoring

### Infrastructure Metrics
- System-wide resource monitoring
- Service-level metrics and analytics
- Real-time dashboards and graphs
- Prometheus integration
- Alert management and notifications

### Backup & Recovery
- Automated backup scheduling
- Manual backup creation
- Progress monitoring
- One-click restoration
- Backup retention policies

### DNS Management
- Dynamic DNS record creation
- Zone file management
- ACME challenge automation
- CoreDNS integration

### Alert Management
- Real-time alert notifications
- Alert severity levels
- Acknowledgement and resolution
- Alert history and analytics

---

## Technology Stack

### Frontend (Cross-Platform)
- **Framework:** Flutter 3.16+
- **Language:** Dart
- **State Management:** Riverpod
- **GraphQL Client:** graphql_flutter
- **UI Components:** Material Design 3
- **Platforms:** iOS, Android, Linux, macOS, Windows

### Backend (API Server)
- **Framework:** FastAPI 0.104+
- **Language:** Python 3.11+
- **GraphQL:** Strawberry 0.214+
- **ASGI Server:** Uvicorn
- **Database:** PostgreSQL + SQLAlchemy
- **Cache:** Redis
- **Docker SDK:** docker-py
- **OAuth:** Authlib
- **Testing:** pytest

### Infrastructure Integration
- **Reverse Proxy:** Traefik
- **Identity Provider:** Authentik
- **Monitoring:** Prometheus + Grafana
- **DNS:** CoreDNS + etcd
- **Container Runtime:** Docker
- **VPN:** Tailscale
- **Security:** CrowdSec

---

## Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PrivateNexus Mobile/Desktop App          │
│                         (Flutter)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │ GraphQL over HTTPS/WSS
                       │ OAuth 2.0 Authentication
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  PrivateNexus API Server                    │
│                  (FastAPI + Strawberry)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┬──────────────┐
         ▼             ▼             ▼              ▼
    ┌────────┐   ┌─────────┐   ┌─────────┐   ┌──────────┐
    │ Docker │   │Authentik│   │Prometheus│   │ CoreDNS  │
    │  API   │   │  OAuth  │   │ Metrics │   │   DNS    │
    └────────┘   └─────────┘   └─────────┘   └──────────┘
         │
         ▼
    ┌─────────────────────────────────────────────────────┐
    │          SecureNexus Infrastructure                 │
    │  (Traefik, Services, Containers, Monitoring)        │
    └─────────────────────────────────────────────────────┘
```

### Security Architecture

```
┌──────────────────┐
│  Mobile/Desktop  │
│       App        │
└────────┬─────────┘
         │ HTTPS + OAuth 2.0
         ▼
┌──────────────────┐     ┌─────────────────┐
│  Authentik SSO   │────▶│  User Database  │
│  OAuth Provider  │     │   PostgreSQL    │
└────────┬─────────┘     └─────────────────┘
         │ Access Token
         ▼
┌──────────────────┐
│  API Gateway     │
│    (Traefik)     │
│  + CrowdSec      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌─────────────────┐
│   GraphQL API    │────▶│  Redis Cache    │
│  (FastAPI)       │     └─────────────────┘
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Infrastructure   │
│  (Docker API,    │
│   Prometheus,    │
│   CoreDNS, etc)  │
└──────────────────┘
```

---

## Why Python? (Not Rust)

After comprehensive analysis, Python was chosen for the initial backend implementation:

### Development Speed
- **3-4x faster development** than Rust
- Quick iteration and prototyping
- Mature GraphQL ecosystem (Strawberry)
- Lower learning curve for team expansion

### Performance
- Python can handle **1,000+ req/sec** easily
- Your expected load: **5-10 req/sec**
- Mostly I/O-bound operations (Docker API, database)
- FastAPI benchmarks: **30,000+ req/sec**

### Ecosystem Maturity
- **FastAPI:** Best-in-class Python web framework
- **Strawberry:** Modern, type-safe GraphQL library
- **docker-py:** Official, mature Docker SDK
- **SQLAlchemy:** Industry-standard ORM
- Large talent pool for hiring

### Future Optimization Path
- Start with Python for rapid development
- Optimize hot paths with Rust later if needed
- Use PyO3 to compile Rust extensions for Python
- Full Rust rewrite possible after product-market fit

See `docs/PRIVATENEXUS_RUST_VS_PYTHON_ANALYSIS.md` for complete analysis.

---

## Licensing

PrivateNexus is **proprietary software** to avoid AGPL-3.0 copyleft restrictions that would require source code disclosure for network services.

### Inspiration vs. Fork

PrivateNexus is **inspired by** SelfPrivacy but is a **clean-room implementation**:
- No SelfPrivacy code was copied or modified
- Independent architecture and design
- Similar user experience goals
- No AGPL licensing obligations

### Open Source Dependencies

While PrivateNexus itself is proprietary, it is built on and integrates with open source technologies:
- Flutter (BSD-3-Clause)
- FastAPI (MIT)
- Strawberry GraphQL (MIT)
- Docker (Apache 2.0)
- Authentik (MIT)
- Traefik (MIT)
- Prometheus (Apache 2.0)
- PostgreSQL (PostgreSQL License)
- CoreDNS (Apache 2.0)
- And many more...

See `docs/SELFPRIVACY_LICENSING_ANALYSIS.md` for detailed licensing analysis.

---

## Project Structure

### Documentation

All project documentation is in the `docs/` directory:

```
docs/
├── PRIVATENEXUS_README.md                    # This file
├── PRIVATENEXUS_CONTROL_APP_MASTER_PLAN.md   # Complete project plan
├── PRIVATENEXUS_CONTROL_APP_ARCHITECTURE.md  # Technical architecture
├── PRIVATENEXUS_API_SPECIFICATION.md         # Complete GraphQL API spec
├── PRIVATENEXUS_RUST_VS_PYTHON_ANALYSIS.md   # Language evaluation
├── SELFPRIVACY_LICENSING_ANALYSIS.md         # Legal analysis
└── (Other SecureNexus infrastructure docs)
```

### Project Plan Documents

1. **Master Plan** (`PRIVATENEXUS_CONTROL_APP_MASTER_PLAN.md`)
   - Executive summary
   - Project scope and deliverables
   - 4-phase timeline (23 weeks)
   - Budget options ($220k / $62k / $5k)
   - Risk assessment
   - Success criteria

2. **Architecture** (`PRIVATENEXUS_CONTROL_APP_ARCHITECTURE.md`)
   - System architecture diagrams
   - Component descriptions
   - Data flow diagrams
   - GraphQL schema design
   - Security architecture
   - Database schema
   - Integration points

3. **API Specification** (`PRIVATENEXUS_API_SPECIFICATION.md`)
   - Complete GraphQL schema
   - All queries, mutations, subscriptions
   - Type definitions
   - Error handling
   - Rate limiting
   - Examples and use cases

4. **Language Analysis** (`PRIVATENEXUS_RUST_VS_PYTHON_ANALYSIS.md`)
   - Rust vs Python comparison
   - Performance benchmarks
   - Development speed analysis
   - Ecosystem maturity
   - Recommendation: Python first

5. **Licensing Analysis** (`SELFPRIVACY_LICENSING_ANALYSIS.md`)
   - AGPL-3.0 implications
   - Fork vs clean-room approach
   - Recommendation: Clean-room implementation

---

## Development Timeline

### Phase 1: Foundation (Weeks 1-6)
- API server setup (FastAPI + GraphQL)
- Authentication integration (Authentik OAuth)
- Docker API integration
- Flutter project setup
- Basic UI shell

### Phase 2: Core Features (Weeks 7-13)
- Client management (CRUD)
- Service deployment
- Container monitoring
- Real-time updates (WebSocket)
- Metrics dashboards

### Phase 3: Advanced Features (Weeks 14-18)
- Backup management
- DNS management
- Alert system
- Advanced monitoring
- Search and filtering

### Phase 4: Polish & Launch (Weeks 19-23)
- Performance optimization
- Security hardening
- Comprehensive testing
- Documentation
- Beta testing
- Production deployment

**Total Time:** 23 weeks (~5.5 months)

See `PRIVATENEXUS_CONTROL_APP_MASTER_PLAN.md` for detailed timeline.

---

## Budget Options

### Option 1: Professional Development Team
- **Cost:** $220,000
- **Team:** 4 developers + 1 designer
- **Timeline:** 23 weeks (on schedule)
- **Quality:** Production-ready, enterprise-grade
- **Support:** Full team support

### Option 2: Hybrid Approach (Recommended)
- **Cost:** $62,000
- **Team:** 1 senior dev + 1 junior dev + contractor
- **Timeline:** 30 weeks (~7 months)
- **Quality:** Good quality, some rough edges
- **Support:** Limited

### Option 3: Solo/DIY
- **Cost:** $5,000 (tools and services)
- **Team:** Solo developer (you)
- **Timeline:** 52 weeks (~1 year)
- **Quality:** MVP with limitations
- **Support:** Self-support

See `PRIVATENEXUS_CONTROL_APP_MASTER_PLAN.md` for detailed breakdown.

---

## Getting Started

### Prerequisites

**Backend:**
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Docker 24+

**Frontend:**
- Flutter 3.16+
- Dart 3.2+

**Infrastructure:**
- SecureNexus stack deployed
- Authentik OAuth configured
- Traefik reverse proxy
- CoreDNS for DNS

### Installation (Coming Soon)

```bash
# Clone repository
git clone https://github.com/yourusername/privatenexus.git
cd privatenexus

# Backend setup
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your configuration
uvicorn app.main:app --reload

# Frontend setup
cd ../frontend
flutter pub get
flutter run
```

---

## Configuration

### Environment Variables

**Backend (.env):**
```bash
# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/privatenexus

# Redis
REDIS_URL=redis://localhost:6379/0

# OAuth
AUTHENTIK_URL=https://auth.yourdomain.com
OAUTH_CLIENT_ID=your-client-id
OAUTH_CLIENT_SECRET=your-client-secret

# Docker
DOCKER_HOST=unix:///var/run/docker.sock

# Security
SECRET_KEY=your-secret-key
CORS_ORIGINS=https://app.yourdomain.com
```

**Frontend (config.dart):**
```dart
class Config {
  static const String apiUrl = 'https://api.yourdomain.com/graphql';
  static const String wsUrl = 'wss://api.yourdomain.com/graphql';
  static const String oauthAuthUrl = 'https://auth.yourdomain.com/application/o/authorize/';
  static const String oauthTokenUrl = 'https://auth.yourdomain.com/application/o/token/';
  static const String clientId = 'your-client-id';
  static const List<String> scopes = [
    'openid',
    'profile',
    'email',
    'privatenexus:read',
    'privatenexus:write',
  ];
}
```

---

## API Documentation

### GraphQL Endpoint

**Production:** `https://api.privatenexus.net/graphql`
**GraphiQL Playground:** `https://api.privatenexus.net/graphql` (in browser)

### Authentication

All API requests require OAuth 2.0 authentication via Authentik:

```http
Authorization: Bearer <access_token>
```

### Example Query

```graphql
query GetClients {
  clients(pagination: { first: 10 }) {
    edges {
      node {
        id
        name
        domain
        status
        services {
          id
          name
          type
          status
        }
      }
    }
    totalCount
  }
}
```

### Example Mutation

```graphql
mutation CreateClient($input: CreateClientInput!) {
  createClient(input: $input) {
    client {
      id
      name
      domain
      status
    }
    errors {
      field
      message
    }
  }
}
```

### Example Subscription

```graphql
subscription ContainerEvents {
  containerEvents {
    type
    container {
      id
      name
      status
    }
    timestamp
  }
}
```

See `docs/PRIVATENEXUS_API_SPECIFICATION.md` for complete API documentation.

---

## Security

### Authentication & Authorization
- OAuth 2.0 via Authentik SSO
- JWT access tokens (15-minute expiry)
- Refresh tokens (7-day expiry)
- Role-based access control (RBAC)
- Scope-based permissions

### Network Security
- HTTPS-only communication
- TLS 1.3 minimum
- Certificate pinning (mobile apps)
- VPN access option (Tailscale)
- CrowdSec intrusion detection

### API Security
- Rate limiting (1,000 req/hour authenticated)
- Input validation
- Output sanitization
- CORS restrictions
- SQL injection prevention
- XSS protection

### Data Security
- Encrypted database connections
- Encrypted backups
- Secret management via Docker secrets
- No sensitive data in logs
- Regular security audits

### Infrastructure Security
- A+ security grade (SecureNexus infrastructure)
- Regular updates and patches
- Automated backup rotation
- Disaster recovery procedures
- Monitoring and alerting

---

## Performance

### Expected Performance

**API Server:**
- Latency: <50ms p50, <200ms p95
- Throughput: 1,000+ req/sec
- Concurrent connections: 1,000+
- WebSocket connections: 100+ simultaneous

**Mobile App:**
- Startup time: <2 seconds
- GraphQL query latency: <100ms
- Real-time updates: <500ms delay
- Offline support: View cached data

**Resource Usage:**
- API server: ~512MB RAM, <10% CPU
- Database: ~1GB RAM
- Redis: ~256MB RAM
- Total: ~2GB RAM for backend stack

### Optimization Strategies
- Database query optimization (indexes, connection pooling)
- Redis caching (query results, sessions)
- GraphQL DataLoader (batch queries)
- API response compression (gzip)
- Frontend lazy loading
- Image optimization
- Code splitting

---

## Testing

### Backend Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_clients.py

# Run integration tests
pytest tests/integration/
```

### Frontend Testing

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widgets/

# Integration tests
flutter drive --target=test_driver/app.dart
```

### End-to-End Testing

```bash
# Full system test
./scripts/e2e-test.sh
```

---

## Deployment

### Backend Deployment (Docker)

```yaml
# docker-compose.yml
version: '3.8'

services:
  privatenexus-api:
    image: privatenexus/api:latest
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/privatenexus
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=secure-password

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data

volumes:
  postgres-data:
  redis-data:
```

### Frontend Deployment

**iOS:**
```bash
flutter build ios --release
# Upload to App Store via Xcode
```

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
# Upload to Google Play Console
```

**Desktop:**
```bash
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

---

## Roadmap

### v1.0 (Launch) - Q2 2026
- ✅ Client management
- ✅ Service deployment
- ✅ Container monitoring
- ✅ Backup management
- ✅ DNS management
- ✅ Alert system
- ✅ Mobile apps (iOS/Android)
- ✅ Desktop apps (Linux/macOS/Windows)

### v1.1 - Q3 2026
- Multi-factor authentication (MFA)
- Advanced metrics and analytics
- Custom dashboards
- Webhook integrations
- API documentation portal
- In-app tutorials

### v1.2 - Q4 2026
- Kubernetes support
- Terraform integration
- Custom plugins/extensions
- Advanced RBAC
- Audit logging
- Compliance reports

### v2.0 - 2027
- Multi-region support
- High availability (HA) mode
- Disaster recovery automation
- AI-powered insights
- Predictive scaling
- Cost optimization

---

## Contributing

PrivateNexus is proprietary software. Contributions are currently limited to the internal development team.

For bug reports and feature requests, please contact: support@privatenexus.net

---

## Support

### Documentation
- Website: https://privatenexus.net
- Docs: https://docs.privatenexus.net
- API Reference: https://api.privatenexus.net/docs

### Community
- Email: support@privatenexus.net
- Discord: https://discord.gg/privatenexus (coming soon)
- Forum: https://forum.privatenexus.net (coming soon)

### Commercial Support
- Enterprise support plans available
- Custom development and integrations
- Training and onboarding
- SLA guarantees

Contact: enterprise@privatenexus.net

---

## Acknowledgments

### Inspiration
- **SelfPrivacy** - Privacy-focused self-hosting inspiration
- **Portainer** - Container management UI patterns
- **Grafana** - Metrics visualization approach

### Open Source Technologies
- **Flutter** - Cross-platform UI framework
- **FastAPI** - Modern Python web framework
- **Strawberry** - GraphQL library for Python
- **Authentik** - Identity provider
- **Traefik** - Reverse proxy and load balancer
- **Prometheus** - Monitoring and alerting
- **PostgreSQL** - Database
- **Docker** - Containerization platform
- **CoreDNS** - DNS server

And countless other open source projects that make PrivateNexus possible.

---

## License

PrivateNexus is proprietary software.

Copyright © 2025 PrivateNexus. All rights reserved.

Unauthorized copying, modification, distribution, or use of this software is strictly prohibited.

---

## Privacy Policy

PrivateNexus is **private by default**:

### Data Collection
- **We collect:** None. All data stays on your infrastructure.
- **We track:** Nothing. No analytics, no telemetry, no phone-home.
- **We store:** Nothing. We never see your data.

### Data Storage
- All data stored on your self-hosted infrastructure
- You control backup encryption and retention
- No third-party data sharing
- No cloud dependencies (unless you choose)

### Data Access
- Only you have access to your data
- OAuth authentication under your control
- Audit logs of all access attempts
- Revocable access tokens

**Your data, your infrastructure, your control.**

---

## Contact

**Website:** https://privatenexus.net
**Email:** info@privatenexus.net
**Documentation:** https://docs.privatenexus.net
**API Reference:** https://api.privatenexus.net

---

**PrivateNexus - Private and Secure by Default**

*Built with ❤️ using open source technologies*
