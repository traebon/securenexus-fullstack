# GitHub Repository Cleanup Plan

## 🎯 Objective

Transform personal SecureNexus infrastructure repositories into generic, reusable templates for the self-hosting community.

## 📈 Current Progress

### ✅ Completed Documentation Cleanup (January 6, 2026)
- **README.md**: Updated GitHub clone URL to use generic domain
- **FORGEJO_SETUP_INSTRUCTIONS.md**: Removed personal SSH key and "traebon" username references
- **GITHUB_MIRRORING_STRATEGY.md**: Updated all GitHub URLs and personal usernames to generic placeholders
- **FORGEJO_MIGRATION_COMPLETE_GUIDE.md**: Updated domain references and personal information
- **GITHUB_CLEANUP_PLAN.md**: Updated status to reflect current progress

### 🔄 In Progress
- **CHANGELOG.md**: Update GitHub Actions references to Forgejo Actions
- **CLAUDE.md**: Review and update any git-related references
- **Configuration Files**: Need automated cleanup for compose.yml, Caddyfile, etc.

## 🔍 Personal Information Audit

### 1. Domain References
**Current**: `securenexus.net`, `byrne-accounts.org`, `dickinson-law.com`
**Target**: `example.com`, `your-domain.com`, `client-domain.com`

**Files to Update**:
- `compose.yml` - All environment variables with domains
- `config/caddy/Caddyfile` - Virtual host configurations
- `dns/zones/*.zone` - DNS zone files
- `.env.example` - Domain template variables
- All documentation in `docs/`
- All scripts in `scripts/`

### 2. Email Addresses
**Current**: `tristian@securenexus.net`, `admin@securenexus.net`
**Target**: `admin@example.com`, `alerts@your-domain.com`

**Files to Update**:
- `monitoring/alertmanager.yml` - Alert email recipients
- `compose.yml` - ACME email configurations
- All documentation files
- Script configurations

### 3. Personal Names
**Current**: "SecureNexus", "Tristian", "traebon", "lattitiude"
**Target**: "SelfHost Stack", "Administrator", "your-username", "your-hostname"

**Files to Update**:
- README.md and all documentation
- Git commit messages (if needed)
- Container labels and descriptions
- Branding files

### 4. Infrastructure-Specific Data
**Current**: Tailscale keys, API tokens, IP addresses
**Target**: Template placeholders and generation scripts

**Files to Update**:
- All `secrets/` directory contents
- IP address references in configs
- API keys and tokens
- SSH keys and certificates

## 📋 Cleanup Checklist

### Phase 1: Secrets and Credentials ✅
- [ ] **Remove all `secrets/` directory contents**
  ```bash
  find secrets/ -type f -exec rm {} \;
  # Keep directory structure with .gitkeep files
  find secrets/ -type d -exec touch {}/.gitkeep \;
  ```

- [ ] **Check for hardcoded secrets**
  ```bash
  grep -r -i "password\|secret\|key\|token\|api_key" . \
    --exclude-dir=.git --exclude-dir=secrets
  ```

- [ ] **Scan for sensitive patterns**
  ```bash
  grep -r "SecureNexus2024\|lattitiude\|tristian" . \
    --exclude-dir=.git
  ```

### Phase 2: Domain and Email References ✅
- [ ] **Replace domain references**
  ```bash
  # Primary domain replacement
  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/securenexus\.net/example.com/g' {} \;

  # Client domains
  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/byrne-accounts\.org/client-domain.com/g' {} \;

  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/dickinson-law\.com/client-domain.com/g' {} \;
  ```

- [ ] **Replace email addresses**
  ```bash
  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/tristian@securenexus\.net/admin@example.com/g' {} \;

  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/admin@securenexus\.net/alerts@example.com/g' {} \;

  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/alerts@securenexus\.net/monitoring@example.com/g' {} \;
  ```

### Phase 3: Personal Names and Branding ✅
- [ ] **Replace project names**
  ```bash
  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/SecureNexus/SelfHost Stack/g' {} \;

  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/securenexus/selfhost-stack/g' {} \;
  ```

- [ ] **Replace personal references**
  ```bash
  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/traebon/your-username/g' {} \;

  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/Tristian/Administrator/g' {} \;

  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/lattitiude/your-hostname/g' {} \;
  ```

### Phase 4: Infrastructure-Specific Data ✅
- [ ] **Replace IP addresses**
  ```bash
  # Replace specific IPs with examples
  find . -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
    -exec sed -i 's/192\.168\.1\.100/192.168.1.10/g' {} \;

  # Check for other specific IPs
  grep -r "192\.168\." . --exclude-dir=.git | grep -v "192\.168\.1\.10"
  ```

- [ ] **Remove API keys and tokens**
  ```bash
  # Search for potential API keys
  grep -r -E "[A-Za-z0-9]{32,}" . --exclude-dir=.git --exclude-dir=secrets
  ```

### Phase 5: Configuration Templates ✅
- [ ] **Create template files**
  ```bash
  # Create generic compose template
  cp compose.yml compose.template.yml

  # Create environment template
  cp .env.example .env.template

  # Create Caddy template
  cp config/caddy/Caddyfile config/caddy/Caddyfile.template
  ```

- [ ] **Add template variables**
  ```bash
  # Replace fixed values with template variables in compose.template.yml
  sed -i 's/example\.com/${DOMAIN}/g' compose.template.yml
  sed -i 's/admin@example\.com/${ADMIN_EMAIL}/g' compose.template.yml
  ```

## 🏗️ Repository Restructuring

### New Repository Name
**From**: `securenexus-fullstack`
**To**: `selfhost-stack` or `docker-selfhost-platform`

### New Directory Structure
```
selfhost-stack/                    (renamed from securenexus-fullstack)
├── README.md                      (rewritten for generic use)
├── QUICK_START.md                 (new - immediate deployment guide)
├── DEPLOYMENT_GUIDE.md            (comprehensive setup)
├── ARCHITECTURE.md                (system overview)
├── CUSTOMIZATION.md               (domain/service configuration)
├── compose.yml                    (production configuration)
├── compose.template.yml           (template with variables)
├── .env.template                  (clean environment template)
├── config/                        (generic configurations)
│   ├── caddy/Caddyfile.template  (template Caddy config)
│   └── */                        (service configs)
├── docs/                          (cleaned documentation)
│   ├── setup/                    (setup guides)
│   ├── services/                 (service-specific guides)
│   ├── security/                 (hardening procedures)
│   └── examples/                 (configuration examples)
├── scripts/                       (generic utility scripts)
│   ├── setup.sh                  (initial deployment)
│   ├── customize.sh              (domain customization)
│   └── utils/                    (maintenance scripts)
├── examples/                      (sample configurations)
│   ├── production/               (production examples)
│   ├── development/              (dev examples)
│   └── minimal/                  (basic setup)
└── templates/                     (configuration templates)
    ├── domains/                  (domain-specific examples)
    └── services/                 (service configuration examples)
```

## 📝 New Documentation Strategy

### 1. Generic README.md
```markdown
# Self-Hosted Infrastructure Stack

Complete Docker Compose infrastructure for self-hosting with 85+ integrated services.

## Features
- Identity Management (Authentik SSO)
- Monitoring & Alerting (Prometheus, Grafana)
- Reverse Proxy (Caddy with automatic HTTPS)
- DNS Management (CoreDNS + etcd)
- Mail Server Integration (Mailcow)
- Cloud Services (Nextcloud, Notes)
- Unified Design System

## Quick Start
1. Clone repository
2. Run setup script: `./scripts/setup.sh`
3. Customize domain: `./scripts/customize.sh your-domain.com`
4. Deploy: `make up-all`

## Documentation
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Architecture Overview](ARCHITECTURE.md)
- [Customization Guide](CUSTOMIZATION.md)
- [Service Guides](docs/services/)
```

### 2. DEPLOYMENT_GUIDE.md
- Step-by-step setup for new users
- Prerequisites and requirements
- Domain configuration
- SSL certificate setup
- Service customization

### 3. CUSTOMIZATION.md
- How to replace template variables
- Domain and email configuration
- Service selection and removal
- Branding customization

## 🔧 Automation Scripts

### 1. setup.sh (New)
```bash
#!/bin/bash
# Initial setup script for new deployments
# Generates secrets, configures environment, validates setup
```

### 2. customize.sh (New)
```bash
#!/bin/bash
# Domain and email customization script
# Usage: ./scripts/customize.sh your-domain.com admin@your-domain.com
```

### 3. validate.sh (Enhanced)
```bash
#!/bin/bash
# Enhanced validation with generic checks
# Removes infrastructure-specific validations
```

## 🎨 Generic Branding

### Color Scheme
**Replace**: SecureNexus blue/green theme
**With**: Neutral professional theme
- Primary: #2563eb (blue)
- Secondary: #64748b (slate)
- Success: #059669 (emerald)
- Warning: #d97706 (amber)

### Logo and Assets
- Remove SecureNexus logo references
- Create generic placeholder logos
- Update favicon references
- Clean up branded screenshots

## 🚀 Template Features to Add

### 1. Multi-Environment Support
```yaml
# compose.dev.yml - Development overrides
# compose.prod.yml - Production optimizations
# compose.minimal.yml - Minimal service set
```

### 2. Service Selection
```bash
# Allow users to choose service profiles
./scripts/setup.sh --profile minimal
./scripts/setup.sh --profile standard
./scripts/setup.sh --profile enterprise
```

### 3. Domain Wizard
```bash
# Interactive domain configuration
./scripts/configure-domains.sh
# Prompts for primary domain, client domains, email addresses
```

## 📊 Cleanup Verification

### Automated Checks
```bash
# Check for remaining personal references
grep -r "securenexus\|tristian\|traebon" . --exclude-dir=.git

# Verify no secrets remain
find . -name "*.txt" -path "./secrets/*" -exec ls -la {} \;

# Check for hardcoded IPs
grep -r "192\.168\.1\." . --exclude-dir=.git | grep -v example

# Verify email replacements
grep -r "@securenexus\.net" . --exclude-dir=.git
```

### Manual Review Checklist
- [ ] All documentation reads generically
- [ ] No personal names in commit messages (if sanitizing)
- [ ] All configuration files use template variables
- [ ] Screenshots and images are generic
- [ ] README clearly explains template nature

## 🎯 Success Criteria

### ✅ Repository Ready for Public Use
- No personal information exposed
- Clear setup instructions for new users
- Template-based configuration system
- Generic branding throughout

### ✅ Template Functionality
- One-command setup for new domains
- Service profiles for different use cases
- Clear customization instructions
- Production-ready defaults

### ✅ Documentation Quality
- Comprehensive deployment guide
- Service-specific documentation
- Troubleshooting procedures
- Architecture explanations

## 🔄 Implementation Timeline

### Phase 1: Automated Cleanup (1-2 hours)
- Run domain/email replacement scripts
- Remove secrets and personal data
- Update configuration templates

### Phase 2: Documentation Rewrite (2-3 hours)
- Create generic README
- Write deployment and customization guides
- Update all documentation for generic use

### Phase 3: Template Enhancement (2-3 hours)
- Create setup and customization scripts
- Add multi-environment support
- Implement service selection

### Phase 4: Validation (1 hour)
- Run cleanup verification scripts
- Manual review of all content
- Test template deployment

**Total Estimated Time**: 6-9 hours

---

**Status**: 🔄 **CLEANUP IN PROGRESS**
**Completed**: Documentation genericization (README.md, Forgejo setup guides, mirroring strategy)
**In Progress**: Personal reference removal across all documentation files
**Next**: Execute automated cleanup scripts for configuration files
**Validation**: Generic template deployment test

**Last Updated**: January 6, 2026