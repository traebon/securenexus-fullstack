# Changelog

All notable changes to the SecureNexus Full Stack platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Resource limits for memory-intensive services (PostgreSQL, Redis, Nextcloud, Caddy, Loki)
- Comprehensive example secret files for better onboarding (`secrets/*.example`)
- Detailed secrets management documentation (`docs/SECRETS.md`)
- Forgejo Actions workflow for validation and testing
- Semantic versioning strategy

### Changed
- **BREAKING**: Removed hardcoded secrets from Notesnook services (rotated all exposed credentials)
- **SECURITY**: Pinned all `:latest` image tags to specific versions for stability
- **SECURITY**: Fixed DNS updater to use docker-proxy instead of direct socket access
- Updated README.md to reflect complete Caddy migration (removed stale Traefik references)
- Enhanced service configuration examples to use Caddyfile syntax

### Fixed
- Port binding conflicts between Traefik and Caddy (Caddy is now the sole reverse proxy)
- Documentation inconsistencies regarding proxy configuration
- Security vulnerabilities from hardcoded secrets in git history
- Docker socket security issues with DNS updater service

### Security
- Generated new secrets to replace compromised credentials
- Implemented proper secret file management with `_FILE` variants
- Enhanced container resource isolation with memory and CPU limits
- Improved Docker socket security via proxy service

## [2.0.0] - 2025-11-28 (Production Ready)

### Added
- Complete Caddy reverse proxy with HTTP/3 QUIC support
- CrowdSec threat protection with forward authentication
- Dashy dashboard platform with comprehensive service catalog
- Notesnook self-hosted note-taking platform (6-service architecture)
- Nextcloud personal cloud storage with full SSO integration
- Multi-tenant ERPNext deployment (Byrne + Dickson)
- Automated backup system with 3-tier retention (daily/weekly/monthly)
- Comprehensive monitoring with 30+ alert rules across 11 categories
- TLS 1.3 and modern security headers across all services

### Changed
- **BREAKING**: Migrated from Traefik to Caddy reverse proxy
- **BREAKING**: Removed Redis from Authentik (PostgreSQL-only caching)
- Updated Authentik to v2025.10.1 with enhanced security
- Enhanced firewall configuration with deny-by-default policy
- Optimized Prometheus memory allocation (2GB) for production workloads

### Deprecated
- Traefik configuration (moved to legacy status)
- Stalwart mail server (replaced with Mailcow)
- Headscale VPN (replaced with Tailscale)

### Removed
- Direct Docker socket dependencies (replaced with docker-proxy)
- Legacy Traefik configuration files
- Insecure HTTP endpoints (HTTPS-only deployment)

### Fixed
- SSL certificate management via Caddy ACME integration
- Service discovery and DNS management
- Container health monitoring and alerting
- Performance bottlenecks in monitoring stack

### Security
- Enterprise-grade security with A+ rating
- Zero-trust architecture with VPN-only admin access
- Comprehensive intrusion detection via CrowdSec
- Automated security updates via Watchtower
- Encrypted backup storage with automated rotation

## [1.0.0] - 2025-10-15 (Initial Production)

### Added
- Core infrastructure with Authentik SSO
- Basic monitoring stack (Prometheus, Grafana)
- DNS management with CoreDNS + etcd
- Mailcow email server integration
- Tailscale VPN for secure access
- Basic backup system
- Initial documentation

### Security
- UFW firewall configuration
- Basic SSL certificate management
- Container security hardening
- Initial secrets management

---

## Version Strategy

This project follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes that require manual intervention
- **MINOR**: New features and significant improvements
- **PATCH**: Bug fixes and minor improvements

### Release Schedule

- **Major releases**: Quarterly (January, April, July, October)
- **Minor releases**: Monthly for significant features
- **Patch releases**: As needed for critical fixes

### Branch Strategy

- `main`: Production-ready code
- `develop`: Integration branch for new features
- `feature/*`: Individual feature development
- `hotfix/*`: Critical production fixes

### Tagging Convention

- Format: `vMAJOR.MINOR.PATCH` (e.g., `v2.1.0`)
- Pre-releases: `vMAJOR.MINOR.PATCH-rc.N` (e.g., `v2.1.0-rc.1`)
- Development builds: `vMAJOR.MINOR.PATCH-dev` (e.g., `v2.1.0-dev`)