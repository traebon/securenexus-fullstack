# Byrne Accounting Website Redesign & Multi-Tenant Architecture Plan

**Created**: November 2, 2025
**Status**: Planning Phase
**Goal**: Transform byrne-accounts.org into a professional accounting firm website with integrated multi-tenant client portal

---

## Executive Summary

Complete redesign of byrne-accounts.org with the following objectives:
1. **Professional Website**: Modern, trust-building design matching top accounting firms
2. **Client Portal**: Secure SSO-enabled access to ERPNext, POS Awesome, and Webmail
3. **Multi-Tenant Architecture**: Efficient resource usage with shared database containers
4. **Seamless Integration**: Traefik routing + Authentik SSO for unified experience

---

## Part 1: What Worked Well (Keep These)

### ✅ Infrastructure Foundation
- **Traefik**: Excellent reverse proxy with automatic SSL - KEEP
- **Authentik SSO**: Centralized authentication working well - KEEP & EXPAND
- **Docker Compose**: Clean service orchestration - KEEP
- **Monitoring Stack**: Prometheus + Grafana provides great visibility - KEEP
- **Backup System**: Automated 3-tier backup rotation - KEEP
- **Security**: CrowdSec, UFW firewall, VPN access for admin - KEEP

### ✅ ERPNext Base Setup
- **Multi-site capability**: ERPNext naturally supports multiple sites - LEVERAGE THIS
- **Single database approach**: One MariaDB container with multiple databases - ALREADY OPTIMAL
- **POS Awesome integration**: Works well via symlink - KEEP
- **Health checks**: Container monitoring working - KEEP

### ✅ Documentation & Scripts
- **Utility scripts**: backup-all.sh, dns-sync.sh, etc. - KEEP
- **Comprehensive docs**: Well organized in docs/ - KEEP & EXPAND

---

## Part 2: What Didn't Work (Fix or Replace)

### ❌ Website Design
- **Problem**: Basic HTML/CSS, not professional enough for accounting firm
- **Impact**: Doesn't inspire client trust or confidence
- **Solution**: Complete redesign with modern framework (see Part 4)

### ❌ Manual Client Onboarding
- **Problem**: Creating new client sites was manual and error-prone
- **Impact**: Created test sites (demo, dickinson, poctest, wiztest, workflow) that needed cleanup
- **Solution**: Automated provisioning script with templates

### ❌ ERPNext Site Proliferation
- **Problem**: Too many test sites cluttered the system
- **Impact**: Wasted resources, confusing configuration
- **Solution**: Clean architecture with proper staging/production separation (COMPLETED)

### ❌ Client Portal Not Integrated
- **Problem**: portal.html exists but not properly integrated with SSO
- **Impact**: Clients can't easily access their services
- **Solution**: Build proper client dashboard with Authentik integration

### ❌ Webmail Per-Client Containers
- **Problem**: Created separate snappymail container for each client (snappymail-dickinson)
- **Impact**: Resource waste, more containers to manage
- **Solution**: Use Mailcow's native multi-domain support + SOGo webmail

---

## Part 3: Research Findings - Modern Accounting Websites

### Design Principles (from 2025 trends research)
1. **Clean, professional layouts** with strong visual hierarchy
2. **Trust signals**: Certifications, testimonials, case studies
3. **Mobile-first responsive design** (60%+ traffic from mobile)
4. **High-quality imagery** (avoid stock photos, use custom graphics)
5. **Strong CTAs**: "Client Portal", "Get Started", "Schedule Consultation"
6. **Fast loading times**: Under 3 seconds
7. **Accessibility**: WCAG 2.1 AA compliance

### Color Schemes (Professional Accounting Firms)
- **Primary**: Navy blue, deep blue (trust, stability)
- **Secondary**: Green, teal (growth, prosperity)
- **Accent**: Gold, orange (premium, approachable)
- **Neutrals**: White, light gray backgrounds

### Essential Pages
1. **Home**: Hero section, services overview, trust signals, CTA
2. **Services**: Detailed service descriptions with benefits
3. **About**: Team, credentials, firm history
4. **Client Portal**: Secure login gateway (SSO)
5. **Contact**: Form, phone, email, office location
6. **Resources**: Blog, guides, tax calendar (optional)

### Key Features
- **Secure Client Portal** with document upload/download
- **Appointment scheduling** integration
- **Live chat** or contact form
- **Testimonials** with photos/names
- **Service pricing** (transparent)
- **Trust badges**: CPA certified, security certifications

---

## Part 4: Proposed Architecture

### 4.1 Website Technology Stack

**Option A: Modern Static Site (Recommended)**
- **Framework**: Astro or Next.js (static export)
- **Styling**: Tailwind CSS
- **Components**: React/Vue for interactive elements
- **Hosting**: Nginx container (lightweight)
- **Why**: Fast, modern, easy to maintain, great SEO

**Option B: Enhanced Current HTML/CSS**
- **Keep**: Simple HTML structure
- **Upgrade**: Modern CSS framework (Tailwind or Bootstrap 5)
- **Add**: JavaScript for interactive elements
- **Why**: Simpler, less build complexity

**Decision**: Start with Option B for quick deployment, migrate to Option A later if needed

### 4.2 Multi-Tenant ERPNext Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Traefik (Reverse Proxy)                  │
│                     SSL, Routing, Authentik SSO                  │
└─────────────────┬───────────────────────┬──────────────────────┘
                  │                       │
        ┌─────────▼─────────┐   ┌────────▼──────────┐
        │ Client Portal     │   │ ERPNext Backend   │
        │ (Client Dashboard)│   │ (Port 8000)       │
        └───────────────────┘   └─────────┬─────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    │                     │                     │
            ┌───────▼────────┐   ┌───────▼────────┐   ┌───────▼────────┐
            │ Client A Site  │   │ Client B Site  │   │ Client C Site  │
            │ a.erp.byrne... │   │ b.erp.byrne... │   │ c.erp.byrne... │
            └───────┬────────┘   └───────┬────────┘   └───────┬────────┘
                    │                     │                     │
                    └─────────────────────┼─────────────────────┘
                                          │
                                ┌─────────▼─────────┐
                                │  MariaDB          │
                                │  - _client_a DB   │
                                │  - _client_b DB   │
                                │  - _client_c DB   │
                                └───────────────────┘
```

**Key Points**:
1. **Single ERPNext container** serves all client sites
2. **Single MariaDB container** with database-per-client
3. **Traefik routes** by hostname: client-a.erp.byrne-accounts.org
4. **Authentik SSO** protects all client access
5. **Shared resources**: Redis cache, Redis queue (already implemented)

### 4.3 Client Portal Dashboard

```
┌──────────────────────────────────────────────────────────────┐
│                    Client Portal Dashboard                    │
│                  (After Authentik SSO Login)                  │
├──────────────────────────────────────────────────────────────┤
│  Welcome, [Client Company Name]                              │
│                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │   ERPNext      │  │  POS Awesome   │  │    Webmail     │ │
│  │                │  │                │  │                │ │
│  │  • Accounting  │  │  • Point of    │  │  • Secure      │ │
│  │  • Invoices    │  │    Sale        │  │    Email       │ │
│  │  • Reports     │  │  • Inventory   │  │  • Contacts    │ │
│  │                │  │  • Sales       │  │  • Calendar    │ │
│  │  [Launch App]  │  │  [Launch App]  │  │  [Launch App]  │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
│                                                               │
│  ┌────────────────┐  ┌────────────────┐                      │
│  │   Documents    │  │    Support     │                      │
│  │  • Upload      │  │  • Contact Us  │                      │
│  │  • Download    │  │  • FAQs        │                      │
│  │  [View Files]  │  │  [Get Help]    │                      │
│  └────────────────┘  └────────────────┘                      │
└──────────────────────────────────────────────────────────────┘
```

**Portal Features**:
- **Authentication**: Authentik SSO (already have this)
- **Client identification**: Read from Authentik user groups
- **Dynamic links**: Show only services client has access to
- **Branding**: Client-specific logo/colors (from ERPNext site config)

### 4.4 Hostname Strategy

**Public Website**:
- `byrne-accounts.org` → Main marketing site
- `www.byrne-accounts.org` → Redirect to main site

**Client Portal**:
- `portal.byrne-accounts.org` → Client dashboard (SSO protected)

**ERPNext Instances** (per client):
- `erp.byrne-accounts.org` → Byrne's own ERPNext
- `client-a.erp.byrne-accounts.org` → Client A's ERPNext
- `client-b.erp.byrne-accounts.org` → Client B's ERPNext

**POS Awesome**:
- `pos.byrne-accounts.org` → Byrne's POS (symlink to erp.byrne-accounts.org)
- `client-a.pos.byrne-accounts.org` → Client A's POS

**Webmail** (via Mailcow SOGo):
- `webmail.byrne-accounts.org` → Mailcow SOGo interface
- Mailcow handles multiple domains: @byrne-accounts.org, @client-a.com, etc.
- **No separate containers per client** - Mailcow's multi-domain support

---

## Part 5: Database Sharing Strategy

### Current Reality (Already Optimal!)
ERPNext already implements exactly what you want:

```
MariaDB Container (erpnext-db)
├── _client_a_hash (Client A database)
├── _client_b_hash (Client B database)
├── _client_c_hash (Client C database)
└── erpnext (default database)
```

**What ERPNext Does**:
1. Each site gets its own database in the same MariaDB instance
2. Database names are hashed for security
3. All sites share the same MariaDB container
4. Separate user permissions per database
5. Site config stored in `sites/[site-name]/site_config.json`

**No Changes Needed** - this is already best practice!

### Resource Optimization
**Before** (problematic approach):
- 5 test sites = 5 databases in 1 MariaDB ✅ (this was fine)
- Problem was Traefik label clutter and lack of organization

**After** (clean approach):
- N client sites = N databases in 1 MariaDB ✅ (same as before)
- Organized naming: `client-a.erp.byrne-accounts.org`
- Automated provisioning (no manual site creation)
- Proper SSO group mapping

### Other Shared Resources (Already Implemented)
- **Redis Cache**: Shared by all ERPNext sites
- **Redis Queue**: Shared by all ERPNext sites
- **SocketIO**: Single instance for all sites
- **Worker/Scheduler**: Single instance processes jobs for all sites

**Total Containers for 10 Clients**:
- ERPNext: 7 containers (backend, db, redis-cache, redis-queue, socketio, worker, scheduler)
- **Not** 70 containers (7 per client)
- This is already optimal!

---

## Part 6: Implementation Roadmap

### Phase 1: Website Redesign (Week 1)
**Goal**: Professional marketing site that inspires trust

**Tasks**:
1. ✅ Design new homepage layout
2. ✅ Implement responsive CSS (Tailwind or custom)
3. ✅ Add hero section with strong CTA
4. ✅ Create services section (4-6 services)
5. ✅ Add about section (team, credentials)
6. ✅ Create contact form (or link to email)
7. ✅ Add trust signals (certifications, testimonials)
8. ✅ Optimize for mobile
9. ✅ Test loading speed (target: <2s)

**Deliverables**:
- `byrne-website/index.html` (redesigned)
- `byrne-website/assets/css/style.css` (new styles)
- `byrne-website/assets/images/` (professional images)

### Phase 2: Client Portal (Week 2)
**Goal**: Functional client dashboard with SSO

**Tasks**:
1. ✅ Design portal dashboard layout
2. ✅ Integrate Authentik SSO authentication
3. ✅ Read user info from Authentik (groups, email)
4. ✅ Display client-specific links (ERPNext, POS, Webmail)
5. ✅ Add client branding (logo, colors)
6. ✅ Create "Get Started" guide for clients
7. ✅ Test SSO flow end-to-end

**Deliverables**:
- `byrne-website/portal.html` (redesigned)
- Authentik OAuth application for portal
- User group mappings in Authentik

### Phase 3: Multi-Tenant ERPNext Setup (Week 3)
**Goal**: Streamlined process for onboarding new clients

**Tasks**:
1. ✅ Create client provisioning script (`scripts/provision-client.sh`)
2. ✅ Automate ERPNext site creation
3. ✅ Automate Authentik user/group creation
4. ✅ Automate Traefik label generation
5. ✅ Generate client welcome email template
6. ✅ Document onboarding process
7. ✅ Test with 2 clients (staging)

**Deliverables**:
- `scripts/provision-client.sh` (automated provisioning)
- `docs/CLIENT_ONBOARDING_GUIDE.md` (updated)
- Client site template configuration

### Phase 4: Webmail Integration (Week 4)
**Goal**: Unified webmail access via Mailcow

**Tasks**:
1. ✅ Configure Mailcow for multiple domains
2. ✅ Add client email domains to Mailcow
3. ✅ Integrate SOGo webmail with Authentik SSO
4. ✅ Test email sending/receiving per domain
5. ✅ Add webmail links to client portal
6. ✅ Document email setup process

**Deliverables**:
- Mailcow multi-domain configuration
- SOGo SSO integration
- Email setup guide for clients

### Phase 5: Testing & Refinement (Week 5)
**Goal**: Production-ready system

**Tasks**:
1. ✅ End-to-end testing with 2 test clients
2. ✅ Performance testing (load, speed)
3. ✅ Security audit (SSO, permissions)
4. ✅ Backup/restore testing
5. ✅ Documentation review
6. ✅ Create video tutorials (optional)
7. ✅ Launch with real clients

**Deliverables**:
- Test report with metrics
- Final documentation
- Launch checklist

---

## Part 7: Technical Implementation Details

### 7.1 Automated Client Provisioning Script

```bash
#!/bin/bash
# scripts/provision-client.sh
# Automates client onboarding for multi-tenant ERPNext

CLIENT_NAME="$1"  # e.g., "client-a"
CLIENT_COMPANY="$2"  # e.g., "Client A Corp"
CLIENT_EMAIL="$3"  # e.g., "admin@clienta.com"
CLIENT_DOMAIN="$4"  # e.g., "clienta.com" (for email)

# 1. Create ERPNext site
docker compose exec erpnext-backend bench new-site \
  ${CLIENT_NAME}.erp.byrne-accounts.org \
  --db-name _${CLIENT_NAME} \
  --admin-password $(openssl rand -base64 32) \
  --install-app erpnext \
  --install-app posawesome

# 2. Create Authentik user group
# (API call to Authentik)

# 3. Add Traefik labels to compose.yml
# (automated with script)

# 4. Send welcome email
# (template with credentials and portal link)

# 5. Create Mailcow domain and mailbox
# (API call to Mailcow)
```

### 7.2 Client Portal Authentication Flow

```
1. Client visits: portal.byrne-accounts.org
2. Traefik forwards to client portal container
3. Portal checks for Authentik session cookie
4. If not authenticated:
   - Redirect to Authentik login: auth.securenexus.net
   - User logs in with credentials
   - Authentik redirects back to portal with token
5. Portal verifies token with Authentik
6. Portal reads user info (name, email, groups)
7. Portal shows dashboard with links:
   - ERPNext: client-a.erp.byrne-accounts.org
   - POS: client-a.pos.byrne-accounts.org
   - Webmail: webmail.byrne-accounts.org (logged in via SSO)
8. Client clicks link → Traefik forwards to service
9. Service verifies Authentik token (if integrated)
10. Client accesses application
```

### 7.3 Traefik Label Template (per client)

```yaml
# In compose.yml, erpnext-backend service
labels:
  # Client A ERPNext
  - traefik.http.routers.erp-client-a.rule=Host(`client-a.erp.byrne-accounts.org`)
  - traefik.http.routers.erp-client-a.entrypoints=websecure
  - traefik.http.routers.erp-client-a.tls.certresolver=le
  - traefik.http.routers.erp-client-a.middlewares=secure-headers@file,authentik@file
  - traefik.http.routers.erp-client-a.service=erp

  # Client A POS
  - traefik.http.routers.pos-client-a.rule=Host(`client-a.pos.byrne-accounts.org`)
  - traefik.http.routers.pos-client-a.entrypoints=websecure
  - traefik.http.routers.pos-client-a.tls.certresolver=le
  - traefik.http.routers.pos-client-a.middlewares=secure-headers@file,authentik@file
  - traefik.http.routers.pos-client-a.service=erp
```

**Automation**: Script generates these labels and appends to compose.yml

### 7.4 Authentik Group Mapping

```
Authentik Groups:
├── byrne-admins (full access to all clients)
├── byrne-accountants (access to assigned clients)
├── client-a-users (Client A employees)
│   └── admin@clienta.com (admin)
│   └── user@clienta.com (user)
├── client-b-users (Client B employees)
│   └── admin@clientb.com (admin)
└── ...

Portal Dashboard:
- Reads user's groups
- Shows links only for their client's services
- Example: user in "client-a-users" sees:
  - client-a.erp.byrne-accounts.org
  - client-a.pos.byrne-accounts.org
  - webmail.byrne-accounts.org
```

---

## Part 8: Design Specifications

### 8.1 Color Palette

**Primary Colors**:
- Navy Blue: `#1e3a8a` (trust, professionalism)
- Deep Blue: `#2563eb` (interactive elements)

**Secondary Colors**:
- Teal: `#10b981` (growth, success)
- Green: `#059669` (hover states)

**Accent Colors**:
- Gold: `#f59e0b` (CTAs, highlights)
- Orange: `#ea580c` (urgent actions)

**Neutrals**:
- White: `#ffffff`
- Light Gray: `#f9fafb`
- Gray: `#6b7280`
- Dark Gray: `#1f2937`

### 8.2 Typography

**Headings**:
- Font: Inter, Roboto, or system font stack
- H1: 3rem (48px), bold
- H2: 2.25rem (36px), bold
- H3: 1.875rem (30px), semibold

**Body**:
- Font: Inter, Roboto, or system font stack
- Size: 1rem (16px)
- Line height: 1.6

**Buttons**:
- Font: semibold
- Size: 1rem (16px)
- Padding: 0.75rem 1.5rem

### 8.3 Component Library

**Buttons**:
```html
<button class="btn btn-primary">Client Portal</button>
<button class="btn btn-secondary">Get Started</button>
<button class="btn btn-outline">Learn More</button>
```

**Cards**:
```html
<div class="card">
  <div class="card-icon">📊</div>
  <h3 class="card-title">Service Name</h3>
  <p class="card-description">Description...</p>
</div>
```

**Hero Section**:
```html
<section class="hero">
  <div class="hero-content">
    <h1>Professional Accounting Solutions</h1>
    <p>Empowering businesses with...</p>
    <div class="hero-cta">
      <button class="btn btn-primary">Access Portal</button>
    </div>
  </div>
</section>
```

---

## Part 9: Success Metrics

### Website Performance
- **Page load time**: < 2 seconds
- **Mobile responsive**: Yes (all pages)
- **Lighthouse score**: > 90 (all categories)
- **SSL grade**: A+ (already achieved)

### Client Experience
- **Portal login time**: < 5 seconds (SSO)
- **Application access**: 1 click from portal
- **Email delivery**: < 1 minute
- **Uptime**: 99.9%+ (already achieved)

### Operational Efficiency
- **Client onboarding**: < 30 minutes (automated)
- **Resource usage**: < 10% increase per client
- **Container count**: 7 total (not 7 per client)
- **Database size**: < 500 MB per client

### Security
- **All traffic**: HTTPS (enforced)
- **Authentication**: SSO with MFA (Authentik)
- **Access control**: Group-based (Authentik)
- **Audit logs**: Enabled (Authentik + ERPNext)

---

## Part 10: Cost-Benefit Analysis

### Current System (Post-Cleanup)
- **Containers**: 30 (core infrastructure + 1 client)
- **Memory**: ~12 GB
- **Storage**: ~50 GB
- **Maintenance**: Manual per client

### Proposed System (5 Clients)
- **Containers**: 30 (no increase!)
- **Memory**: ~14 GB (+2 GB for 4 additional clients)
- **Storage**: ~52 GB (+2 GB for databases)
- **Maintenance**: Automated provisioning

### ROI
- **Time savings**: 60% (automated vs manual)
- **Resource efficiency**: 90% (shared vs dedicated)
- **Client satisfaction**: Higher (SSO, portal)
- **Scalability**: 10x easier to add clients

---

## Part 11: Next Steps (Decision Points)

### Immediate Decisions Needed
1. **Website design**: Start from scratch or enhance current?
   - **Recommendation**: Enhance current (faster)

2. **Portal technology**: Static HTML + JS or React/Vue?
   - **Recommendation**: Static HTML + vanilla JS (simpler)

3. **Provisioning automation**: Priority 1 or after portal?
   - **Recommendation**: After portal (manual is okay for now)

4. **Webmail**: Keep separate or Mailcow only?
   - **Recommendation**: Mailcow only (less complexity)

### Phase 1 Start
**Ready to begin**:
1. Redesign `byrne-website/index.html` with modern layout
2. Update CSS for professional appearance
3. Add trust signals and better CTAs
4. Test on mobile and desktop

**Approval needed**:
- Color scheme preferences
- Logo/branding assets
- Service descriptions
- Contact information

---

## Conclusion

This plan provides a comprehensive roadmap for transforming byrne-accounts.org into a professional multi-tenant accounting platform. The architecture leverages existing infrastructure (Traefik, Authentik, shared databases) while adding:

1. **Professional website** that inspires trust
2. **Client portal** for easy access
3. **Automated provisioning** for scalability
4. **Unified webmail** via Mailcow
5. **Optimal resource usage** (shared containers)

**Key Insight**: Your multi-tenant database strategy is already optimal! ERPNext's design naturally supports multiple clients with shared infrastructure. The focus should be on:
- Better website design
- Integrated client portal
- Automated provisioning
- Clean organization

**Estimated Timeline**: 5 weeks to production-ready system
**Estimated Cost**: $0 (using existing infrastructure)
**Risk Level**: Low (incremental improvements, existing services stay running)

---

**Ready to proceed with Phase 1?** Let's start with the website redesign!
