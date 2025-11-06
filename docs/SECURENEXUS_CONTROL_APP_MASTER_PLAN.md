# SecureNexus Control App - Master Project Plan

**Project Name:** SecureNexus Control App
**Project Code:** SNCA
**Version:** 1.0
**Date:** November 6, 2025
**Status:** Planning Phase
**Approach:** Clean Room Implementation (No AGPL Dependencies)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Vision & Objectives](#project-vision--objectives)
3. [Scope & Deliverables](#scope--deliverables)
4. [Technology Stack](#technology-stack)
5. [Project Phases](#project-phases)
6. [Timeline & Milestones](#timeline--milestones)
7. [Resource Requirements](#resource-requirements)
8. [Risk Assessment](#risk-assessment)
9. [Success Criteria](#success-criteria)
10. [Budget Estimates](#budget-estimates)

---

## Executive Summary

### Project Overview

SecureNexus Control App is a mobile and desktop application designed to simplify the management of multi-tenant accounting firm infrastructure. Inspired by SelfPrivacy's user experience but built from scratch, it will enable administrators to deploy and manage client environments through an intuitive interface without requiring terminal access or technical expertise.

### Key Differentiators

- **Business-Focused:** Designed for service providers managing multiple clients
- **Multi-Tenant:** Complete isolation between client environments
- **Enterprise-Grade:** SSO, RBAC, audit logging, compliance features
- **Proprietary Option:** Freedom to choose licensing model
- **Docker-Native:** Works with existing Docker Compose infrastructure

### Strategic Value

**Problem Solved:**
- Currently requires CLI/terminal for all operations
- Client provisioning takes 15-20 minutes of manual work
- No mobile access to infrastructure management
- High technical barrier for team members

**Solution Provided:**
- One-tap client provisioning
- Real-time infrastructure monitoring on mobile
- Service control from anywhere
- Intuitive UI for non-technical staff

**Business Impact:**
- Reduce provisioning time: 15 min → 2 min (87% reduction)
- Enable 24/7 monitoring and management
- Scale operations without additional technical staff
- Competitive advantage through superior tooling

---

## Project Vision & Objectives

### Vision Statement

*"Democratize multi-tenant infrastructure management through an intuitive mobile-first experience that empowers service providers to scale efficiently while maintaining complete control and security."*

### Primary Objectives

1. **Simplify Operations**
   - Reduce manual CLI operations by 90%
   - Enable non-technical staff to perform routine tasks
   - Provide instant visibility into system health

2. **Accelerate Growth**
   - Provision new clients in under 2 minutes
   - Scale to 10+ clients without additional overhead
   - Support team expansion with lower training costs

3. **Enhance Reliability**
   - Real-time monitoring and alerting
   - Proactive issue detection
   - Automated backup management

4. **Maintain Control**
   - Proprietary codebase (no AGPL restrictions)
   - Flexible licensing options
   - Protected competitive advantage

### Success Metrics

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| Client Provisioning Time | 15 min | 2 min | Phase 2 |
| CLI Operations per Week | 50+ | <5 | Phase 3 |
| Non-Technical Staff Usage | 0% | 80% | Phase 4 |
| Mobile Access | 0% | 100% | Phase 2 |
| Client Deployment Capacity | 1/week | 5/day | Phase 4 |

---

## Scope & Deliverables

### In Scope

#### Phase 1: Foundation (Weeks 1-3)
**Backend API:**
- [ ] GraphQL API server (Python FastAPI)
- [ ] Authentication via Authentik OAuth
- [ ] Docker API integration
- [ ] System status queries
- [ ] Service list/detail queries
- [ ] Basic CRUD operations

**Frontend App:**
- [ ] Flutter project setup
- [ ] Authentication flow
- [ ] Dashboard screen
- [ ] Service list screen
- [ ] Service detail screen
- [ ] Pull-to-refresh

**Infrastructure:**
- [ ] API Docker container
- [ ] Traefik integration
- [ ] SSL certificates
- [ ] Documentation

**Deliverable:** Working prototype demonstrating core concept

---

#### Phase 2: Core Features (Weeks 4-10)
**Backend API:**
- [ ] Client management (CRUD)
- [ ] Service control (start/stop/restart)
- [ ] User management (Authentik integration)
- [ ] Metrics queries (Prometheus)
- [ ] Log streaming
- [ ] Real-time subscriptions (WebSocket)

**Frontend App:**
- [ ] Client list/detail screens
- [ ] Service control interface
- [ ] User management screens
- [ ] Monitoring dashboard
- [ ] Log viewer
- [ ] Real-time updates

**Business Logic:**
- [ ] Client provisioning workflow
- [ ] Service health checks
- [ ] Alert notifications
- [ ] Role-based permissions

**Deliverable:** Production-ready core application

---

#### Phase 3: Advanced Features (Weeks 11-18)
**Backend API:**
- [ ] Backup management
- [ ] DNS management (CoreDNS integration)
- [ ] Script execution
- [ ] Theme/branding management
- [ ] Usage tracking
- [ ] Audit logging

**Frontend App:**
- [ ] Backup interface
- [ ] DNS management screens
- [ ] Script runner
- [ ] Theme customization
- [ ] Usage reports
- [ ] Audit log viewer

**Integrations:**
- [ ] Prometheus metrics
- [ ] Grafana dashboards
- [ ] Loki logs
- [ ] Uptime Kuma
- [ ] Mailcow API

**Deliverable:** Feature-complete application

---

#### Phase 4: Polish & Production (Weeks 19-23)
**Backend:**
- [ ] Performance optimization
- [ ] Rate limiting
- [ ] Caching strategy
- [ ] Error handling
- [ ] API documentation (Swagger)

**Frontend:**
- [ ] UI/UX polish
- [ ] Animations
- [ ] Offline support
- [ ] Push notifications
- [ ] Multi-language support

**DevOps:**
- [ ] CI/CD pipelines
- [ ] Automated testing
- [ ] Monitoring setup
- [ ] Backup procedures

**Distribution:**
- [ ] iOS App Store submission
- [ ] Google Play Store submission
- [ ] Desktop installers (Windows, macOS, Linux)
- [ ] User documentation
- [ ] Video tutorials

**Deliverable:** Publicly available application

---

### Out of Scope (Future Phases)

- White-label reseller program
- Multi-region support
- HA/cluster management
- Advanced billing integration
- Client self-service portal
- Kubernetes support
- AI-powered recommendations

---

## Technology Stack

### Backend API

**Language & Framework:**
```
Language: Python 3.11+
Framework: FastAPI 0.104+
API Style: GraphQL (strawberry-graphql)
ASGI Server: Uvicorn
```

**Key Dependencies:**
```python
fastapi==0.104.1           # Web framework
strawberry-graphql==0.214  # GraphQL server
uvicorn==0.24.0            # ASGI server
python-jose==3.3.0         # JWT handling
docker==6.1.3              # Docker API client
httpx==0.25.0              # Async HTTP client
sqlalchemy==2.0.23         # Database ORM
psycopg2-binary==2.9.9     # PostgreSQL driver
redis==5.0.1               # Caching
pydantic==2.5.0            # Data validation
prometheus-client==0.19.0  # Metrics
```

**Why This Stack:**
- FastAPI: Modern, fast, automatic docs
- Strawberry: Type-safe GraphQL with Python types
- Docker SDK: Native Python library for Docker
- SQLAlchemy: Robust ORM for PostgreSQL
- Async support: Better performance for I/O operations

---

### Frontend App

**Framework & Language:**
```
Framework: Flutter 3.16+
Language: Dart 3.2+
Platforms: iOS, Android, Windows, Linux, macOS
```

**Key Dependencies:**
```yaml
# State Management
riverpod: ^2.4.9
flutter_riverpod: ^2.4.9

# GraphQL Client
graphql_flutter: ^5.1.2

# HTTP & Authentication
dio: ^5.4.0
flutter_secure_storage: ^9.0.0
oauth2: ^2.0.2

# UI Components
material_design_3: ^3.0.0
flutter_svg: ^2.0.9
cached_network_image: ^3.3.0

# Charts & Visualization
fl_chart: ^0.65.0
syncfusion_flutter_charts: ^24.1.41

# Utilities
intl: ^0.18.1
timeago: ^3.6.0
url_launcher: ^6.2.2
package_info_plus: ^5.0.1
device_info_plus: ^9.1.1
```

**Why Flutter:**
- Single codebase for all platforms
- Native performance
- Beautiful Material Design 3 UI
- Strong ecosystem
- Hot reload for fast development

---

### Infrastructure

**Deployment:**
```
Container: Docker
Orchestration: Docker Compose
Reverse Proxy: Traefik (existing)
SSL/TLS: Let's Encrypt (existing)
```

**Data Storage:**
```
Primary DB: PostgreSQL 16 (existing Authentik DB)
Cache: Redis 7 (existing)
Metrics: Prometheus (existing)
Logs: Loki (existing)
```

**Authentication:**
```
SSO Provider: Authentik (existing)
Protocol: OAuth 2.0 / OIDC
Token Type: JWT
```

**Development Tools:**
```
Version Control: Git
CI/CD: GitHub Actions or GitLab CI
Testing: pytest (backend), flutter test (frontend)
Linting: ruff (Python), dart analyze (Flutter)
```

---

## Project Phases

### Phase 1: Foundation & Prototype (Weeks 1-3)

**Goals:**
- Prove the concept works
- Validate technology choices
- Establish development patterns
- Create foundation for future work

**Key Activities:**

**Week 1: Setup & Planning**
- [ ] Create project repositories (backend, frontend)
- [ ] Set up development environments
- [ ] Configure CI/CD pipelines
- [ ] Design database schema
- [ ] Create initial GraphQL schema
- [ ] Plan authentication flow

**Week 2: Backend Development**
- [ ] Implement FastAPI application
- [ ] Set up Strawberry GraphQL
- [ ] Integrate Authentik OAuth
- [ ] Create Docker API client wrapper
- [ ] Implement basic queries (system status, services)
- [ ] Add health check endpoints
- [ ] Write unit tests

**Week 3: Frontend Development**
- [ ] Create Flutter project structure
- [ ] Implement authentication flow
- [ ] Build dashboard screen
- [ ] Build service list screen
- [ ] Integrate GraphQL client
- [ ] Add pull-to-refresh
- [ ] Test on iOS, Android, Desktop

**Deliverables:**
- Working API with basic queries
- Mobile app with authentication and dashboard
- Docker container for API
- Technical documentation

**Success Criteria:**
- App can authenticate via Authentik
- App displays system status
- App shows list of Docker services
- Code quality: >80% test coverage
- Performance: API response <200ms

---

### Phase 2: Core Features (Weeks 4-10)

**Goals:**
- Implement essential management features
- Enable client provisioning from app
- Add service control capabilities
- Implement user management

**Key Activities:**

**Weeks 4-5: Client Management**
- [ ] Design client data model
- [ ] Implement client CRUD API
- [ ] Build client list screen
- [ ] Build client detail screen
- [ ] Add client creation wizard
- [ ] Implement validation

**Weeks 6-7: Service Control**
- [ ] Service start/stop/restart API
- [ ] Real-time status updates (WebSocket)
- [ ] Service logs streaming
- [ ] Service metrics display
- [ ] Container resource usage
- [ ] Health check monitoring

**Weeks 8-9: User Management**
- [ ] Authentik API integration
- [ ] User CRUD operations
- [ ] Group management
- [ ] Role assignment
- [ ] Permission checks
- [ ] User list/detail screens

**Week 10: Testing & Refinement**
- [ ] Integration testing
- [ ] Performance testing
- [ ] Bug fixes
- [ ] UI/UX improvements
- [ ] Documentation updates

**Deliverables:**
- Client management functionality
- Service control interface
- User management system
- Real-time updates
- Updated documentation

**Success Criteria:**
- Can provision new client from app
- Can control services (start/stop/restart)
- Can manage users and permissions
- Real-time updates work reliably
- No critical bugs

---

### Phase 3: Advanced Features (Weeks 11-18)

**Goals:**
- Add enterprise features
- Implement monitoring and alerting
- Enable DNS and backup management
- Add customization options

**Key Activities:**

**Weeks 11-12: Monitoring Integration**
- [ ] Prometheus API integration
- [ ] Metrics display (CPU, memory, disk)
- [ ] Alert management
- [ ] Grafana dashboard embedding
- [ ] Custom metric queries
- [ ] Performance graphs

**Weeks 13-14: Backup Management**
- [ ] Backup trigger API
- [ ] Backup status monitoring
- [ ] Restore functionality
- [ ] Backup schedule management
- [ ] Backup size/history display
- [ ] Automated backup testing

**Weeks 15-16: DNS Management**
- [ ] CoreDNS API integration
- [ ] DNS zone management
- [ ] Record CRUD operations
- [ ] DNS health checks
- [ ] Zone file validation
- [ ] Bulk operations

**Weeks 17-18: Customization & Extras**
- [ ] Theme/branding upload
- [ ] Script execution
- [ ] Usage tracking
- [ ] Audit logging
- [ ] Email notifications
- [ ] Webhook support

**Deliverables:**
- Monitoring dashboard
- Backup management
- DNS management
- Theme customization
- Audit logging

**Success Criteria:**
- Real-time metrics display
- Can trigger and monitor backups
- Can manage DNS records
- Can customize client branding
- All actions logged

---

### Phase 4: Polish & Production (Weeks 19-23)

**Goals:**
- Production-ready quality
- App store distribution
- Complete documentation
- Training materials

**Key Activities:**

**Week 19: Performance Optimization**
- [ ] Backend performance tuning
- [ ] Database query optimization
- [ ] Caching strategy
- [ ] Rate limiting
- [ ] Load testing
- [ ] Memory profiling

**Week 20: UI/UX Polish**
- [ ] Animations and transitions
- [ ] Loading states
- [ ] Error handling
- [ ] Empty states
- [ ] Accessibility
- [ ] Dark mode refinement

**Week 21: Production Readiness**
- [ ] Security audit
- [ ] Penetration testing
- [ ] Error logging (Sentry)
- [ ] Performance monitoring
- [ ] Backup procedures
- [ ] Disaster recovery plan

**Week 22: Distribution**
- [ ] iOS App Store submission
- [ ] Google Play submission
- [ ] Desktop installers
- [ ] Release notes
- [ ] Marketing materials
- [ ] Landing page

**Week 23: Documentation & Training**
- [ ] User documentation
- [ ] Admin guide
- [ ] API documentation
- [ ] Video tutorials
- [ ] Training sessions
- [ ] Support procedures

**Deliverables:**
- Production-ready application
- App store listings
- Desktop installers
- Complete documentation
- Training materials
- Support infrastructure

**Success Criteria:**
- Apps approved in stores
- Performance metrics met
- Security audit passed
- Documentation complete
- Team trained
- Support procedures established

---

## Timeline & Milestones

### High-Level Timeline

```
Phase 1: Foundation (3 weeks)     ████████░░░░░░░░░░░░░░░░░░░
Phase 2: Core Features (7 weeks)  ░░░░░░░░███████████████░░░░░
Phase 3: Advanced (8 weeks)       ░░░░░░░░░░░░░░░░███████████░
Phase 4: Production (5 weeks)     ░░░░░░░░░░░░░░░░░░░░░░█████

Total Duration: 23 weeks (~5.5 months)
```

### Milestone Schedule

| Milestone | Week | Date (Est.) | Deliverable |
|-----------|------|-------------|-------------|
| **M1: Kickoff** | 0 | Nov 11, 2025 | Project plan approved |
| **M2: Prototype** | 3 | Dec 2, 2025 | Working prototype demo |
| **M3: Alpha** | 10 | Jan 20, 2026 | Core features complete |
| **M4: Beta** | 18 | Mar 16, 2026 | Feature complete |
| **M5: RC** | 22 | Apr 13, 2026 | Release candidate |
| **M6: Launch** | 23 | Apr 20, 2026 | Public release |

### Detailed Gantt Chart

```
Nov 2025    Dec 2025    Jan 2026    Feb 2026    Mar 2026    Apr 2026
|-----------|-----------|-----------|-----------|-----------|-----------|

Setup       ███
Backend     ░░░██████
Frontend    ░░░░░░░███████
Testing     ░░░░░░░░░░░███

Client Mgmt     ░░░░░███████
Service Ctrl    ░░░░░░░░░███████
User Mgmt       ░░░░░░░░░░░░░███████
Testing         ░░░░░░░░░░░░░░░░░███

Monitoring          ░░░░░░░░░░░░░░███████
Backup Mgmt         ░░░░░░░░░░░░░░░░░███████
DNS Mgmt            ░░░░░░░░░░░░░░░░░░░░███████
Customization       ░░░░░░░░░░░░░░░░░░░░░░░███████

Performance                 ░░░░░░░░░░░░░░░░░░░░███
UI Polish                   ░░░░░░░░░░░░░░░░░░░░░░███
Production                  ░░░░░░░░░░░░░░░░░░░░░░░░███
Distribution                ░░░░░░░░░░░░░░░░░░░░░░░░░░███
Documentation               ░░░░░░░░░░░░░░░░░░░░░░░░░░░███
```

---

## Resource Requirements

### Human Resources

**Core Team (Recommended):**

1. **Backend Developer** (Full-time)
   - Skills: Python, FastAPI, GraphQL, Docker
   - Duration: 20 weeks
   - Focus: API development, integrations

2. **Frontend Developer** (Full-time)
   - Skills: Flutter, Dart, Mobile UI/UX
   - Duration: 18 weeks
   - Focus: Mobile/desktop app

3. **UI/UX Designer** (Part-time, 50%)
   - Skills: Mobile design, Material Design 3
   - Duration: 8 weeks
   - Focus: Screens, flows, visual design

4. **QA Engineer** (Part-time, 50%)
   - Skills: Testing, automation
   - Duration: 8 weeks
   - Focus: Testing, bug tracking

5. **Project Manager** (Part-time, 25%)
   - Skills: Agile, technical PM
   - Duration: 23 weeks
   - Focus: Coordination, timeline

**Alternative: Solo + AI Assistant:**
- You + Claude AI
- Part-time (20 hours/week)
- Duration: 40 weeks (9-10 months)
- Lower cost, more flexibility

---

### Technical Resources

**Development:**
- 2x Development machines (if hiring team)
- GitHub/GitLab subscription (Pro)
- CI/CD minutes (GitHub Actions)
- Test devices (iOS, Android)

**Infrastructure:**
- API hosting (included in existing)
- Database storage (included in existing)
- CDN for app assets ($20/month)
- Error tracking (Sentry, $26/month)
- Analytics (Mixpanel, free tier)

**Distribution:**
- Apple Developer Account ($99/year)
- Google Play Developer ($25 one-time)
- Code signing certificates ($200/year)

**Tools:**
- Design tools (Figma, $15/month)
- Project management (Linear, $10/month)
- Communication (Slack, $8/user/month)

---

### Budget Summary

**Option 1: Professional Team**
```
Backend Developer:   20 weeks × $100/hr × 40hr = $80,000
Frontend Developer:  18 weeks × $90/hr × 40hr  = $64,800
UI/UX Designer:      8 weeks × $80/hr × 20hr   = $12,800
QA Engineer:         8 weeks × $60/hr × 20hr   = $9,600
Project Manager:     23 weeks × $80/hr × 10hr  = $18,400
                                         Total:   $185,600

Infrastructure & Tools:                          $5,000
Contingency (15%):                              $28,590
                                    Grand Total: $219,190
```

**Option 2: Solo + AI (Your Time)**
```
Your Time:           40 weeks × 20hr = 800 hours
Claude Subscription: $20/month × 10 months    = $200
Tools & Services:                              = $2,000
Infrastructure:                                = $3,000
                                        Total:  = $5,200

(Plus opportunity cost of your time)
```

**Option 3: Hybrid**
```
Your Time (planning, oversight): 200 hours
Contract Developer (implementation): 15 weeks × $90/hr × 40hr = $54,000
Tools & Services:                                               $3,500
Infrastructure:                                                 $4,000
                                                       Total:   $61,500
```

---

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Docker API complexity | Medium | High | Prototype early, use existing library |
| GraphQL performance | Low | Medium | Implement caching, use DataLoader |
| Flutter platform issues | Low | Medium | Test on real devices early |
| Authentication integration | Medium | Medium | Follow Authentik docs, test thoroughly |
| Real-time updates scale | Medium | High | Use Redis pub/sub, load test |

### Business Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Feature creep | High | High | Strict scope control, phased approach |
| Timeline slippage | Medium | Medium | Buffer time, regular check-ins |
| Budget overrun | Medium | High | Fixed-price contracts, track carefully |
| User adoption | Low | High | Early beta testing, training |
| Competition | Low | Medium | Move fast, protect IP |

### Legal/Compliance Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Licensing issues | Low | High | Clean room implementation, legal review |
| Data privacy | Medium | High | GDPR compliance, data encryption |
| Security vulnerabilities | Medium | High | Security audit, penetration testing |
| App store rejection | Low | Medium | Follow guidelines, pre-submission review |

---

## Success Criteria

### Technical Success

**Phase 1 (Prototype):**
- [ ] API responds in <200ms
- [ ] App works on iOS and Android
- [ ] Authentication flow complete
- [ ] Can view system status
- [ ] 80%+ test coverage

**Phase 2 (Core Features):**
- [ ] Can provision client in <2 minutes
- [ ] Service control 100% reliable
- [ ] Real-time updates <1s latency
- [ ] 90%+ test coverage
- [ ] Zero critical bugs

**Phase 3 (Advanced):**
- [ ] Metrics display real-time
- [ ] Backup/restore tested
- [ ] DNS management works reliably
- [ ] All features documented
- [ ] Performance benchmarks met

**Phase 4 (Production):**
- [ ] Apps approved in stores
- [ ] Security audit passed
- [ ] Load tested (100 concurrent users)
- [ ] Documentation complete
- [ ] Support procedures in place

### Business Success

**Adoption Metrics:**
- 80% of team using app within 1 month
- 5+ clients provisioned via app within 2 months
- 90% reduction in CLI operations within 3 months
- Positive feedback from beta users

**Operational Metrics:**
- Client provisioning: <2 minutes
- Mean time to respond to alerts: <5 minutes
- System uptime: >99.5%
- User satisfaction: >4.5/5 stars

**Financial Success:**
- Project delivered within budget
- ROI positive within 6 months (time savings)
- Enables scaling to 20+ clients without hiring

---

## Next Steps

### Immediate Actions (This Week)

1. **Approve Project Plan**
   - [ ] Review this document
   - [ ] Approve scope and budget
   - [ ] Commit to timeline
   - [ ] Assign resources

2. **Set Up Infrastructure**
   - [ ] Create Git repositories
   - [ ] Set up development environments
   - [ ] Configure CI/CD
   - [ ] Provision test devices

3. **Kick Off Development**
   - [ ] Hold kickoff meeting
   - [ ] Assign initial tasks
   - [ ] Set up communication channels
   - [ ] Begin Phase 1 work

### Week 1 Checklist

- [ ] Repository created (backend, frontend)
- [ ] Development environment configured
- [ ] Initial architecture documented
- [ ] Team onboarded (if applicable)
- [ ] First standup scheduled
- [ ] Sprint 1 planned

---

## Appendices

### A. Related Documentation
- [Technical Architecture](SECURENEXUS_CONTROL_APP_ARCHITECTURE.md)
- [API Specification](SECURENEXUS_CONTROL_APP_API_SPEC.md)
- [Frontend Specification](SECURENEXUS_CONTROL_APP_FRONTEND_SPEC.md)
- [Deployment Guide](SECURENEXUS_CONTROL_APP_DEPLOYMENT.md)
- [Licensing Analysis](SELFPRIVACY_LICENSING_ANALYSIS.md)

### B. Decision Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-11-06 | Use FastAPI + GraphQL | Modern, type-safe, good DX |
| 2025-11-06 | Flutter for frontend | Cross-platform, native performance |
| 2025-11-06 | Clean room implementation | Avoid AGPL restrictions |
| 2025-11-06 | OAuth via Authentik | Leverage existing SSO |
| 2025-11-06 | Docker Compose deployment | Consistent with infrastructure |

### C. Assumptions
- Existing infrastructure remains stable
- Authentik API will be available
- Docker API doesn't have breaking changes
- Team/developer available as scheduled
- No major scope changes during development

### D. Constraints
- Must work with existing Docker Compose setup
- Cannot disrupt current operations
- Must integrate with Authentik (no alternative SSO)
- Budget limited to approved amount
- Timeline target: Q2 2026 launch

---

**Document Version:** 1.0
**Last Updated:** November 6, 2025
**Status:** Draft - Pending Approval
**Next Review:** After prototype completion (Week 3)
