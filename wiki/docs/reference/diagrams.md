# Architecture Diagrams

Comprehensive system architecture diagrams and visual references.

## System Architecture

For the complete system architecture diagram, see [System Architecture](../getting-started/architecture.md).

## Component Diagrams

### DNS Infrastructure

For DNS architecture including CoreDNS, etcd, and dynamic updates, see [Infrastructure Overview](../infrastructure/overview.md#dns-infrastructure).

### Email Architecture

For email system architecture including Mailcow components, see [Email Overview](../email/overview.md#email-architecture).

### Monitoring Stack

For monitoring architecture including Prometheus, Grafana, and Loki, see [Monitoring Overview](../monitoring/overview.md#monitoring-architecture).

### Multi-Tenant Architecture

For ERPNext multi-tenant architecture, see:
- [ERPNext Overview](../erpnext/overview.md#multi-tenant-architecture)
- [Clients Overview](../clients/overview.md#multi-tenant-architecture)

### Security Layers

For security architecture and access control flows, see [Security Overview](../security/overview.md#security-layers).

### Portal Architecture

For portal and dashboard architecture, see [Portal Overview](../portal/overview.md#portal-architecture).

## Network Diagrams

### Docker Networks

All services communicate via the `proxy` Docker network. See [System Architecture - Network Architecture](../getting-started/architecture.md#network-architecture) for details.

### VPN Access

For Tailscale VPN architecture and admin-only access patterns, see [Infrastructure Overview - VPN Access](../infrastructure/overview.md#vpn-access-tailscale).

## Data Flow Diagrams

### User Authentication Flow

See [System Architecture - User Authentication Flow](../getting-started/architecture.md#user-authentication-flow).

### SSL Certificate Flow

See [System Architecture - SSL Certificate Flow](../getting-started/architecture.md#ssl-certificate-flow).

### Client Routing

For how Traefik routes requests to multi-tenant ERPNext sites, see [Clients Overview - Site Routing](../clients/overview.md#site-routing).

## Deployment Flow

See [Operations Overview - Deployment Strategy](../operations/overview.md#deployment-strategy) for the deployment flow diagram.

## Quick Visual Reference

All major diagrams are embedded throughout the documentation using Mermaid. Use the search function to find specific architectural components.

**Most Common Diagrams**:
1. [Complete System Architecture](../getting-started/index.md#system-architecture)
2. [Multi-Tenant Architecture](../clients/overview.md#multi-tenant-architecture)
3. [Security Layers](../security/overview.md#security-layers)
4. [Monitoring Architecture](../monitoring/overview.md#monitoring-architecture)
5. [Deployment Flow](../operations/overview.md#deployment-strategy)
