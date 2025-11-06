# Byrne Accounts Multi-Tenant Client Portal Architecture

## Overview

This document describes the world-class multi-tenant architecture for Byrne Accounts, where each client gets their own secure, branded space with ERPNext, POS, and webmail access.

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    PUBLIC INTERNET                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: PUBLIC LANDING PAGE                               │
│  byrne-accounts.org                                         │
│  ├─ Homepage (services, about, contact)                     │
│  └─ "Client Portal" button → SSO Login                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼ (SSO Authentication via Authentik)
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: CLIENT PORTAL HUB                                 │
│  portal.byrne-accounts.org                                  │
│  ├─ Authenticated user dashboard                            │
│  ├─ Client selector (if user manages multiple clients)      │
│  ├─ Quick access cards:                                     │
│  │  ├─ ERPNext (business management)                        │
│  │  ├─ POS (point of sale)                                  │
│  │  ├─ Webmail (email)                                      │
│  │  └─ Reports & Analytics                                  │
│  └─ Activity feed & notifications                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  LAYER 3:   │ │  LAYER 3:   │ │  LAYER 3:   │
│  CLIENT A   │ │  CLIENT B   │ │  CLIENT C   │
│  SPACE      │ │  SPACE      │ │  SPACE      │
└─────────────┘ └─────────────┘ └─────────────┘
      │               │               │
      └───────────────┴───────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  CLIENT-SPECIFIC RESOURCES (Per Client)                     │
│  ├─ clientname.byrne-accounts.org (ERPNext subdomain)       │
│  ├─ Dedicated MariaDB database                              │
│  ├─ Custom branding (logo, colors, theme)                   │
│  ├─ Dedicated email domain: @clientname.com                 │
│  ├─ Isolated user accounts (no cross-client access)         │
│  ├─ POS with client's products/inventory                    │
│  └─ Encrypted data at rest                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Details

### Layer 1: Public Landing Page

**URL**: `https://byrne-accounts.org`

**Purpose**: Marketing and client acquisition

**Features**:
- Modern, professional design
- Service descriptions
- Pricing information
- Contact forms
- Security certifications display
- "Login to Client Portal" CTA button

**Technology**: Static HTML/CSS/JS served via Nginx

**Security**: Public access, HTTPS enforced, CrowdSec protection

---

### Layer 2: Client Portal Hub

**URL**: `https://portal.byrne-accounts.org`

**Purpose**: Authenticated dashboard for client access

**Features**:

#### Authentication
- SSO via Authentik
- Multi-factor authentication (MFA) support
- Session management (30-day remember me)
- Automatic logout after inactivity

#### Dashboard Components
1. **Client Selector**
   - For users managing multiple businesses
   - Dropdown to switch between client accounts
   - Displays active client context

2. **Service Cards**
   - ERPNext: Full business management
   - POS: Retail/sales transactions
   - Webmail: Email management
   - Reports: Analytics & insights

3. **Activity Feed**
   - Recent invoices
   - POS sales summary
   - Unread emails count
   - System notifications

4. **Quick Actions**
   - Create invoice
   - Make sale
   - View reports
   - Access settings

**Technology**:
- React.js or Vue.js SPA
- Backend API: Python Flask or Node.js
- Database: PostgreSQL (client mappings)
- Cache: Redis (session data)

**Security**:
- SSO required
- CSRF protection
- XSS prevention
- Rate limiting
- Audit logging

---

### Layer 3: Client-Specific Spaces

**URL Pattern**: `https://{clientname}.byrne-accounts.org`

**Examples**:
- `dickinson.byrne-accounts.org`
- `acme-corp.byrne-accounts.org`
- `janes-bakery.byrne-accounts.org`

**Per-Client Resources**:

#### 1. ERPNext Instance
- **URL**: `https://{clientname}.byrne-accounts.org`
- **Features**:
  - Full ERP functionality
  - Custom company branding
  - Client's chart of accounts
  - Inventory management
  - HR & payroll
  - CRM
  - Project management
- **Isolation**: Separate database per client
- **Customization**: Client-specific workflows & doctypes

#### 2. POS Awesome
- **URL**: `https://{clientname}.byrne-accounts.org/pos`
- **Features**:
  - Touch-friendly interface
  - Barcode scanning
  - Multiple payment methods
  - Receipt printing
  - Real-time inventory sync
  - Offline mode
- **Data**: Client's products only
- **Integration**: Syncs with ERPNext backend

#### 3. Webmail
- **URL**: `https://mail.{clientname}.com` OR `https://{clientname}.byrne-accounts.org/mail`
- **Features**:
  - IMAP/SMTP access
  - Web interface (Roundcube/SnappyMail)
  - Calendar & contacts
  - Mobile apps support
- **Domain**: Custom email domain per client
- **Storage**: Dedicated mailboxes

#### 4. Custom Branding
Each client space includes:
- **Logo**: Client's company logo
- **Color Scheme**: Primary/secondary brand colors
- **Custom CSS**: Tailored theme
- **Login Page**: Branded login screen
- **Email Templates**: Client's branding on emails
- **Reports**: Custom letterhead

---

## Data Isolation & Security

### Database Isolation

```
MariaDB Server
├─ byrne_internal (Byrne Accounts' own data)
├─ client_acme_corp (ACME Corp database)
├─ client_dickinson (Dickinson Supplies database)
└─ client_janes_bakery (Jane's Bakery database)
```

**Each client database includes**:
- ERPNext tables (completely isolated)
- User accounts (no cross-client access)
- Financial data
- Customer/supplier data
- Inventory records

### User Isolation

**Authentication Flow**:
1. User logs in via Authentik SSO
2. Authentik validates credentials + MFA
3. User redirected to Portal Hub
4. Portal Hub queries: "Which clients does this user belong to?"
5. User selects client (or auto-selected if only one)
6. Portal Hub issues client-scoped JWT token
7. JWT contains: `user_id`, `client_id`, `permissions[]`
8. ERPNext validates JWT and grants access to ONLY that client's data

**User Types**:

| Type | Access | Example |
|------|--------|---------|
| **Client Admin** | Full access to their client's space | Business owner |
| **Client Employee** | Limited access to their client's space | Cashier, accountant |
| **Byrne Admin** | Access to ALL client spaces (support) | Byrne Accounts staff |
| **Super Admin** | Infrastructure access | System administrator |

### Encryption

#### Data at Rest
- **Database**: MariaDB encryption at rest (AES-256)
- **Files**: Encrypted volumes for ERPNext file storage
- **Backups**: Encrypted backups (GPG or AES-256)

#### Data in Transit
- **HTTPS**: All traffic encrypted via TLS 1.3
- **Certificate**: Let's Encrypt wildcard cert
- **HSTS**: Enforced via Traefik middleware

#### Secrets Management
- **Passwords**: Hashed with bcrypt (Authentik)
- **API Keys**: Stored in Docker secrets
- **Database Passwords**: Rotated quarterly
- **Encryption Keys**: Stored in Vault or secrets manager

---

## Multi-Tenancy Implementation

### ERPNext Multi-Site Setup

Frappe Bench supports multi-site natively. Configuration:

```bash
# Site structure
/home/frappe/frappe-bench/sites/
├─ erp.byrne-accounts.org/        # Byrne's internal site
├─ dickinson.byrne-accounts.org/  # Client: Dickinson Supplies
├─ acme-corp.byrne-accounts.org/  # Client: ACME Corp
└─ janes-bakery.byrne-accounts.org/ # Client: Jane's Bakery
```

**Shared Resources**:
- Frappe/ERPNext application code
- Backend workers (process jobs for all sites)
- Redis cache & queue
- MariaDB server (separate DBs per site)

**Site-Specific**:
- Database
- Files (uploaded documents, images)
- Custom apps (client-specific extensions)
- Site configuration (`site_config.json`)

### Traefik Routing

Dynamic routing based on subdomain:

```yaml
# Traefik routes each subdomain to same backend
# Frappe Bench uses HTTP Host header to determine which site to serve

labels:
  # Wildcard routing for all client subdomains
  - "traefik.http.routers.erp-clients.rule=HostRegexp(`{subdomain:[a-z0-9-]+}.byrne-accounts.org`)"
  - "traefik.http.routers.erp-clients.entrypoints=websecure"
  - "traefik.http.routers.erp-clients.tls.certresolver=le"
  - "traefik.http.routers.erp-clients.middlewares=sso@file,secure-headers@file"
```

**How it works**:
1. Request arrives: `https://dickinson.byrne-accounts.org/`
2. Traefik matches rule and forwards to `erpnext-backend:8000`
3. Traefik passes `Host: dickinson.byrne-accounts.org` header
4. Frappe Bench reads `Host` header
5. Frappe serves site: `sites/dickinson.byrne-accounts.org/`

### Client Provisioning Workflow

**Automated Provisioning** (when new client signs up):

```bash
# Script: provision-client.sh
./scripts/provision-client.sh \
  --client-name "ACME Corp" \
  --subdomain "acme-corp" \
  --admin-email "admin@acmecorp.com" \
  --plan "professional"
```

**What happens**:
1. ✅ Create DNS record: `acme-corp.byrne-accounts.org`
2. ✅ Create ERPNext site: `bench new-site acme-corp.byrne-accounts.org`
3. ✅ Install apps: `bench --site acme-corp.byrne-accounts.org install-app posawesome`
4. ✅ Create Authentik user group: `acme-corp-users`
5. ✅ Create admin user in Authentik
6. ✅ Set up email domain: `@acmecorp.com` (Mailcow virtual domain)
7. ✅ Apply client branding (logo upload, color scheme)
8. ✅ Send welcome email with login credentials
9. ✅ Add to billing system (subscription tracking)

**Result**: Client can immediately log in and start using their system.

---

## Portal Hub Implementation

### Technology Stack

**Frontend**:
- Framework: **Vue 3** or **React 18**
- UI Components: **Tailwind CSS** + **Headless UI**
- State Management: **Pinia** (Vue) or **Zustand** (React)
- Build Tool: **Vite**

**Backend API**:
- Framework: **FastAPI** (Python) or **Express.js** (Node)
- Authentication: **Authentik OAuth2/OIDC**
- Database: **PostgreSQL** (portal metadata)
- Cache: **Redis** (sessions, activity feed)

**Deployment**:
- Container: Docker image
- Reverse Proxy: Traefik
- Domain: `portal.byrne-accounts.org`

### API Endpoints

```
GET  /api/user/profile          # Get current user info
GET  /api/user/clients          # List clients user can access
POST /api/user/select-client    # Switch active client context
GET  /api/dashboard/summary     # Get dashboard data (sales, invoices, etc.)
GET  /api/dashboard/activity    # Recent activity feed
GET  /api/dashboard/notifications # Unread notifications
POST /api/sso/login             # SSO login initiation
GET  /api/sso/callback          # SSO callback handler
POST /api/sso/logout            # Logout (invalidate session)
```

### Database Schema (Portal Hub)

```sql
-- Users (synced from Authentik)
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    authentik_id VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Clients (each client = one ERPNext site)
CREATE TABLE clients (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    subdomain VARCHAR(100) UNIQUE NOT NULL,  -- e.g., "acme-corp"
    erp_site VARCHAR(255) NOT NULL,          -- e.g., "acme-corp.byrne-accounts.org"
    email_domain VARCHAR(255),               -- e.g., "acmecorp.com"
    subscription_plan VARCHAR(50),           -- "basic", "professional", "enterprise"
    subscription_status VARCHAR(50),         -- "active", "suspended", "cancelled"
    branding_logo_url TEXT,
    branding_primary_color VARCHAR(7),       -- Hex color
    branding_secondary_color VARCHAR(7),
    created_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- User-Client Mapping (many-to-many)
CREATE TABLE user_clients (
    user_id UUID REFERENCES users(id),
    client_id UUID REFERENCES clients(id),
    role VARCHAR(50),  -- "admin", "manager", "employee", "viewer"
    is_default BOOLEAN DEFAULT false,  -- Default client for this user
    granted_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, client_id)
);

-- Activity Log (for dashboard feed)
CREATE TABLE activity_log (
    id UUID PRIMARY KEY,
    client_id UUID REFERENCES clients(id),
    user_id UUID REFERENCES users(id),
    activity_type VARCHAR(50),  -- "invoice_created", "sale_made", "user_added"
    description TEXT,
    metadata JSONB,  -- Additional data
    created_at TIMESTAMP DEFAULT NOW()
);

-- Sessions (for tracking active logins)
CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    client_id UUID REFERENCES clients(id),
    jwt_token TEXT,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Client Branding System

### Branding Configuration

Each client has a branding profile stored in the portal database:

```json
{
  "client_id": "uuid-acme-corp",
  "branding": {
    "logo": {
      "url": "https://cdn.byrne-accounts.org/logos/acme-corp.png",
      "dark_mode_url": "https://cdn.byrne-accounts.org/logos/acme-corp-dark.png"
    },
    "colors": {
      "primary": "#1e40af",    // Blue
      "secondary": "#10b981",  // Green
      "accent": "#f59e0b",     // Amber
      "background": "#ffffff",
      "text": "#1f2937"
    },
    "fonts": {
      "heading": "Inter, sans-serif",
      "body": "Inter, sans-serif"
    },
    "custom_css": "https://cdn.byrne-accounts.org/themes/acme-corp.css",
    "login_message": "Welcome to ACME Corp ERP",
    "footer_text": "© 2025 ACME Corp. Powered by Byrne Accounts.",
    "email_signature": "..."
  }
}
```

### Applying Branding to ERPNext

**Method 1: Custom Theme** (via ERPNext Website Theme doctype)

```bash
# Create theme via Frappe console
bench --site acme-corp.byrne-accounts.org console

# Python:
theme = frappe.get_doc({
    "doctype": "Website Theme",
    "theme": "ACME Corp Theme",
    "custom_scss": """
        :root {
            --primary-color: #1e40af;
            --text-color: #1f2937;
        }
        .navbar-brand img {
            content: url('https://cdn.byrne-accounts.org/logos/acme-corp.png');
        }
    """
})
theme.insert()
frappe.db.commit()
```

**Method 2: Site Config** (via `site_config.json`)

```json
{
  "brand_html": "<img src='https://cdn.byrne-accounts.org/logos/acme-corp.png' />",
  "app_logo_url": "https://cdn.byrne-accounts.org/logos/acme-corp.png",
  "app_name": "ACME Corp ERP"
}
```

**Method 3: Custom App** (for advanced branding)

Create a Frappe app: `acme_corp_branding`
- Hooks into ERPNext UI
- Overrides CSS, templates, and print formats
- Installed only on that client's site

---

## Security Architecture

### Authentication Flow

```
User → Byrne Accounts Website
    ↓
    Click "Client Portal"
    ↓
Portal Hub → Redirect to Authentik SSO
    ↓
Authentik → User Login + MFA
    ↓
Authentik → Issues OAuth2 token
    ↓
Portal Hub → Validates token with Authentik
    ↓
Portal Hub → Fetches user's client list from database
    ↓
Portal Hub → User selects client (if multiple)
    ↓
Portal Hub → Issues client-scoped JWT
    ↓
User clicks "Open ERPNext"
    ↓
ERPNext Site → Validates JWT
    ↓
ERPNext → Creates session for user
    ↓
User accesses ERPNext with client-scoped permissions
```

### Authorization Model

**Role-Based Access Control (RBAC)**:

| Role | Portal Hub | ERPNext | POS | Webmail |
|------|------------|---------|-----|---------|
| **Client Admin** | Full dashboard | System Manager | Configure | Admin |
| **Manager** | View/Edit | Accounts Manager | View reports | User |
| **Employee** | View only | Sales User | Make sales | User |
| **Viewer** | View only | Guest | No access | No access |

**Permission Enforcement**:
- Portal Hub: Check `user_clients.role` before showing features
- ERPNext: Use Frappe's built-in Role Permission Manager
- JWT tokens include `role` claim for stateless auth

### Data Encryption

#### At Rest
- MariaDB: Enable `innodb_encrypt_tables = ON`
- File Storage: Encrypted Docker volumes (LUKS or dm-crypt)
- Backups: GPG-encrypted before storage

#### In Transit
- HTTPS everywhere (TLS 1.3)
- HSTS with preload
- Certificate pinning for admin clients

#### Application-Level
- Sensitive fields (SSN, bank accounts): Encrypted in ERPNext using custom encryption key
- Encryption key per client (stored in secrets manager)

---

## Scalability & Performance

### Current Capacity (Single Server)

| Metric | Capacity |
|--------|----------|
| Concurrent Users | 100-500 users |
| Client Sites | 10-50 sites |
| Database Size | 100GB-500GB |
| Requests/sec | 500-1000 req/s |

### Scaling Strategy

**Vertical Scaling** (0-20 clients):
- Increase server RAM (16GB → 64GB)
- Add more CPU cores
- Use NVMe SSD storage

**Horizontal Scaling** (20+ clients):
- **Database**: Separate MariaDB servers (client groups)
- **Application**: Multiple ERPNext backend containers (load balanced)
- **Cache**: Redis cluster (master-replica)
- **Storage**: S3-compatible object storage (MinIO, AWS S3)

**Performance Optimizations**:
- Redis cache for frequent queries
- CDN for static assets (logo, CSS, JS)
- Database connection pooling
- Background jobs via Celery workers
- Nginx caching for public pages

---

## Backup & Disaster Recovery

### Backup Strategy (Per Client)

**Daily Backups**:
```bash
# Automated via cron (2 AM daily)
bench --site acme-corp.byrne-accounts.org backup --with-files

# Stored: /backup/clients/acme-corp/daily/
```

**Weekly Full Backup**:
- Database dump
- Files (uploaded documents)
- Site config
- Custom apps

**Monthly Archive**:
- Compressed + encrypted backup
- Stored off-site (AWS S3, Backblaze B2)

**Retention Policy**:
- Daily: 7 days
- Weekly: 4 weeks
- Monthly: 12 months

### Disaster Recovery

**Recovery Time Objective (RTO)**: 4 hours
**Recovery Point Objective (RPO)**: 24 hours (last night's backup)

**Recovery Procedure**:
1. Provision new server
2. Install Docker + compose stack
3. Restore MariaDB database from backup
4. Restore site files
5. Restore Authentik users
6. Update DNS to new server IP
7. Verify all clients can log in

---

## Monitoring & Analytics

### System Monitoring

**Metrics** (via Prometheus):
- Container health (all services)
- Database performance (MariaDB)
- API response times
- Error rates
- SSO login success/failure

**Logs** (via Loki):
- Application logs (ERPNext, Portal Hub)
- Nginx access logs
- Security events (failed logins, unauthorized access)

**Dashboards** (Grafana):
- Multi-tenant overview (all clients)
- Per-client metrics (usage, storage, API calls)
- Security dashboard (login attempts, blocked IPs)

### Business Analytics (Per Client)

Provide clients with analytics dashboards:
- Sales trends
- Top-selling products
- Customer acquisition
- Revenue forecasts
- Inventory turnover

**Implementation**: ERPNext Reports + Custom dashboards

---

## Billing & Subscription Management

### Subscription Plans

| Plan | Price | Users | Storage | Features |
|------|-------|-------|---------|----------|
| **Basic** | £49/mo | 5 users | 10GB | ERP, Webmail |
| **Professional** | £99/mo | 20 users | 50GB | + POS, Custom reports |
| **Enterprise** | £249/mo | Unlimited | 200GB | + Custom apps, Priority support |

### Billing System

**Track** (in Portal Hub database):
- Client subscription plan
- Monthly recurring charge
- Usage metrics (users, storage, API calls)
- Billing history

**Invoicing**:
- Auto-generate invoices (via ERPNext on YOUR internal site)
- Send via email
- Accept payments (Stripe, PayPal)

**Subscription Lifecycle**:
- **Active**: Full access
- **Grace Period** (7 days after missed payment): Warning banner, limited access
- **Suspended**: Read-only access, no new data
- **Cancelled**: Export data, then archive site

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- ✅ Set up multi-site ERPNext (DONE)
- ✅ Configure SSO with Authentik (DONE)
- ⬜ Design professional landing page
- ⬜ Build Portal Hub frontend
- ⬜ Create Portal Hub API

### Phase 2: Client Onboarding (Weeks 3-4)
- ⬜ Automated provisioning script
- ⬜ Client branding system
- ⬜ Webmail integration
- ⬜ User management interface

### Phase 3: Security & Compliance (Week 5)
- ⬜ Enable database encryption
- ⬜ Set up automated backups
- ⬜ Security audit & penetration testing
- ⬜ GDPR compliance features

### Phase 4: Go Live (Week 6)
- ⬜ Onboard first 3 pilot clients
- ⬜ Monitor performance & fix issues
- ⬜ Gather feedback
- ⬜ Open for general signups

---

## Compliance & Legal

### Data Protection (GDPR)

**Client Rights**:
- Right to access: API endpoint to export all their data
- Right to erasure: Delete client site + all data
- Right to portability: Export data in standard formats (JSON, CSV)

**Data Processing Agreement**:
- Byrne Accounts = Data Processor
- Client = Data Controller
- DPA signed before provisioning

### Terms of Service

**Client Agreement includes**:
- Acceptable use policy
- Data ownership (client owns their data)
- Service availability (99.5% uptime SLA)
- Support response times
- Termination clauses

---

## Support & Maintenance

### Client Support

**Channels**:
- Email: support@byrne-accounts.org
- Portal: In-app chat widget
- Phone: Business hours

**Response Times**:
- Basic: 48 hours
- Professional: 24 hours
- Enterprise: 4 hours (priority)

### System Maintenance

**Scheduled Maintenance**:
- Weekly: Sunday 2-4 AM (low-traffic window)
- Monthly: Security patches
- Quarterly: ERPNext version upgrades

**Notification**:
- 7 days advance notice via email
- In-app banner 24 hours before
- Status page: status.byrne-accounts.org

---

## Success Metrics

### Business KPIs

- **Client Acquisition**: 5 new clients/month
- **Churn Rate**: < 5% monthly
- **Revenue Growth**: 20% MoM
- **Customer Satisfaction**: NPS > 70

### Technical KPIs

- **Uptime**: 99.9%
- **Page Load Time**: < 2 seconds
- **API Response Time**: < 200ms (p95)
- **Error Rate**: < 0.1%

---

## Conclusion

This multi-tenant architecture provides:

✅ **Isolation**: Each client's data completely separated
✅ **Security**: Enterprise-grade encryption & SSO
✅ **Scalability**: Support 50+ clients on single server
✅ **Branding**: Custom themes per client
✅ **Integration**: ERPNext + POS + Webmail unified
✅ **Automation**: One-command client provisioning
✅ **Compliance**: GDPR-ready

**Next Step**: Implement Phase 1 (Portal Hub)
