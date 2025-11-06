# API Reference

REST API documentation for all SecureNexus components.

## API Overview

SecureNexus provides several REST APIs for automation and integration:

- **Traefik API**: Proxy configuration and status
- **Prometheus API**: Metrics querying and management
- **Mailcow API**: Email management (domains, mailboxes, aliases)
- **Authentik API**: Identity and SSO management
- **ERPNext API**: ERP data and operations
- **Grafana API**: Dashboard and datasource management

## Traefik API

**Base URL**: `http://localhost:8080/api`
**Authentication**: None (localhost only)

### Endpoints

#### Get All HTTP Routers

```bash
GET /http/routers
```

**Example**:
```bash
curl -s http://localhost:8080/api/http/routers | jq
```

**Response**:
```json
[
  {
    "entryPoints": ["websecure"],
    "service": "erp",
    "rule": "Host(`erp.byrne-accounts.org`)",
    "middlewares": ["secure-headers@file"],
    "tls": {
      "certResolver": "le"
    },
    "status": "enabled",
    "name": "erp-main@docker"
  }
]
```

#### Get All HTTP Services

```bash
GET /http/services
```

**Example**:
```bash
curl -s http://localhost:8080/api/http/services | jq
```

#### Get All Middlewares

```bash
GET /http/middlewares
```

**Example**:
```bash
curl -s http://localhost:8080/api/http/middlewares | jq
```

#### Get Raw Configuration

```bash
GET /rawdata
```

**Example**:
```bash
curl -s http://localhost:8080/api/rawdata | jq
```

### Dashboard

Web UI: `https://traefik.securenexus.net` (VPN required)

## Prometheus API

**Base URL**: `http://localhost:9090/api/v1`
**Authentication**: None (VPN required for external access)

### Query API

#### Instant Query

```bash
GET /query?query=<promql>
```

**Example**:
```bash
# Check if services are up
curl -s "http://localhost:9090/api/v1/query?query=up" | jq

# CPU usage
curl -s "http://localhost:9090/api/v1/query?query=100-(avg(irate(node_cpu_seconds_total{mode='idle'}[5m]))*100)" | jq
```

**Response**:
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "job": "traefik",
          "instance": "traefik:8080"
        },
        "value": [1697520000, "1"]
      }
    ]
  }
}
```

#### Range Query

```bash
GET /query_range?query=<promql>&start=<timestamp>&end=<timestamp>&step=<duration>
```

**Example**:
```bash
# CPU usage for last hour
curl -s "http://localhost:9090/api/v1/query_range?query=up&start=$(date -d '1 hour ago' +%s)&end=$(date +%s)&step=60" | jq
```

### Targets API

#### Get All Targets

```bash
GET /targets
```

**Example**:
```bash
curl -s http://localhost:9090/api/v1/targets | jq
```

**Response**:
```json
{
  "status": "success",
  "data": {
    "activeTargets": [
      {
        "discoveredLabels": {},
        "labels": {
          "job": "traefik",
          "instance": "traefik:8080"
        },
        "scrapePool": "traefik",
        "scrapeUrl": "http://traefik:8080/metrics",
        "health": "up",
        "lastScrape": "2025-10-07T12:00:00.000Z"
      }
    ]
  }
}
```

### Alerts API

#### Get All Alerts

```bash
GET /alerts
```

**Example**:
```bash
curl -s http://localhost:9090/api/v1/alerts | jq
```

### Status API

#### Get TSDB Status

```bash
GET /status/tsdb
```

**Example**:
```bash
curl -s http://localhost:9090/api/v1/status/tsdb | jq
```

#### Get Configuration

```bash
GET /status/config
```

**Example**:
```bash
curl -s http://localhost:9090/api/v1/status/config | jq
```

### Web UI

Dashboard: `https://prometheus.securenexus.net` (VPN required)

## Mailcow API

**Base URL**: `https://mail.securenexus.net/api/v1`
**Authentication**: API Key (Header: `X-API-Key`)

### Getting API Key

```bash
./scripts/mailcow-get-api-key.sh
```

Or manually:
1. Login to Mailcow admin
2. Go to System > API
3. Generate API key

### Domains

#### List Domains

```bash
GET /get/domain/all
```

**Example**:
```bash
curl -s "https://mail.securenexus.net/api/v1/get/domain/all" \
  -H "X-API-Key: <your-api-key>" | jq
```

#### Add Domain

```bash
POST /add/domain
```

**Example**:
```bash
curl -X POST "https://mail.securenexus.net/api/v1/add/domain" \
  -H "X-API-Key: <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "description": "Example Domain",
    "max_num_mboxes_for_domain": 10,
    "max_quota_for_domain": 10240
  }'
```

#### Delete Domain

```bash
POST /delete/domain
```

**Example**:
```bash
curl -X POST "https://mail.securenexus.net/api/v1/delete/domain" \
  -H "X-API-Key: <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '["example.com"]'
```

### Mailboxes

#### List Mailboxes

```bash
GET /get/mailbox/all
```

**Example**:
```bash
curl -s "https://mail.securenexus.net/api/v1/get/mailbox/all" \
  -H "X-API-Key: <your-api-key>" | jq
```

#### Get Mailbox Details

```bash
GET /get/mailbox/<email>
```

**Example**:
```bash
curl -s "https://mail.securenexus.net/api/v1/get/mailbox/user@example.com" \
  -H "X-API-Key: <your-api-key>" | jq
```

#### Add Mailbox

```bash
POST /add/mailbox
```

**Example**:
```bash
curl -X POST "https://mail.securenexus.net/api/v1/add/mailbox" \
  -H "X-API-Key: <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "local_part": "user",
    "domain": "example.com",
    "name": "User Name",
    "quota": "10240",
    "password": "SecurePassword123!",
    "password2": "SecurePassword123!",
    "active": "1"
  }'
```

#### Delete Mailbox

```bash
POST /delete/mailbox
```

**Example**:
```bash
curl -X POST "https://mail.securenexus.net/api/v1/delete/mailbox" \
  -H "X-API-Key: <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '["user@example.com"]'
```

### Aliases

#### List Aliases

```bash
GET /get/alias/all
```

**Example**:
```bash
curl -s "https://mail.securenexus.net/api/v1/get/alias/all" \
  -H "X-API-Key: <your-api-key>" | jq
```

#### Add Alias

```bash
POST /add/alias
```

**Example**:
```bash
curl -X POST "https://mail.securenexus.net/api/v1/add/alias" \
  -H "X-API-Key: <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "address": "sales@example.com",
    "goto": "user@example.com",
    "active": "1"
  }'
```

**Documentation**: [Mailcow API Setup](../MAILCOW_API_SETUP.md)

## Authentik API

**Base URL**: `https://sso.securenexus.net/api/v3`
**Authentication**: Bearer Token (Header: `Authorization: Bearer <token>`)

### Getting API Token

1. Login to Authentik admin
2. Go to Directory > Tokens & App passwords
3. Click "Create Token"
4. Select API token type
5. Copy token

### Users

#### List Users

```bash
GET /core/users/
```

**Example**:
```bash
curl -s "https://sso.securenexus.net/api/v3/core/users/" \
  -H "Authorization: Bearer <your-token>" | jq
```

#### Get User

```bash
GET /core/users/<user_id>/
```

**Example**:
```bash
curl -s "https://sso.securenexus.net/api/v3/core/users/1/" \
  -H "Authorization: Bearer <your-token>" | jq
```

#### Create User

```bash
POST /core/users/
```

**Example**:
```bash
curl -X POST "https://sso.securenexus.net/api/v3/core/users/" \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "name": "New User",
    "email": "newuser@example.com",
    "is_active": true
  }'
```

### Applications

#### List Applications

```bash
GET /core/applications/
```

**Example**:
```bash
curl -s "https://sso.securenexus.net/api/v3/core/applications/" \
  -H "Authorization: Bearer <your-token>" | jq
```

### Groups

#### List Groups

```bash
GET /core/groups/
```

**Example**:
```bash
curl -s "https://sso.securenexus.net/api/v3/core/groups/" \
  -H "Authorization: Bearer <your-token>" | jq
```

## ERPNext API

**Base URL**: `https://<site-domain>/api`
**Authentication**: API Key & Secret (Headers: `Authorization: token <api-key>:<api-secret>`)

### Getting API Credentials

1. Login to ERPNext
2. Go to User settings
3. Click "API Access"
4. Generate API Key & Secret
5. Save credentials securely

### Resources

#### Get Document

```bash
GET /resource/<DocType>/<name>
```

**Example**:
```bash
curl -s "https://erp.byrne-accounts.org/api/resource/Customer/CUST-001" \
  -H "Authorization: token <api-key>:<api-secret>" | jq
```

#### List Documents

```bash
GET /resource/<DocType>
```

**Example**:
```bash
curl -s "https://erp.byrne-accounts.org/api/resource/Customer?fields=[\"name\",\"customer_name\"]&limit_page_length=10" \
  -H "Authorization: token <api-key>:<api-secret>" | jq
```

#### Create Document

```bash
POST /resource/<DocType>
```

**Example**:
```bash
curl -X POST "https://erp.byrne-accounts.org/api/resource/Customer" \
  -H "Authorization: token <api-key>:<api-secret>" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_name": "New Customer",
    "customer_type": "Individual",
    "customer_group": "Individual"
  }'
```

#### Update Document

```bash
PUT /resource/<DocType>/<name>
```

**Example**:
```bash
curl -X PUT "https://erp.byrne-accounts.org/api/resource/Customer/CUST-001" \
  -H "Authorization: token <api-key>:<api-secret>" \
  -H "Content-Type: application/json" \
  -d '{
    "mobile_no": "+1234567890"
  }'
```

#### Delete Document

```bash
DELETE /resource/<DocType>/<name>
```

**Example**:
```bash
curl -X DELETE "https://erp.byrne-accounts.org/api/resource/Customer/CUST-001" \
  -H "Authorization: token <api-key>:<api-secret>"
```

### Methods

#### Call Server Method

```bash
POST /method/<method_path>
```

**Example**:
```bash
curl -X POST "https://erp.byrne-accounts.org/api/method/frappe.auth.get_logged_user" \
  -H "Authorization: token <api-key>:<api-secret>"
```

## Grafana API

**Base URL**: `https://grafana.securenexus.net/api` (VPN required)
**Authentication**: Basic Auth or API Key

### Using Basic Auth

```bash
curl -u admin:<password> https://grafana.securenexus.net/api/...
```

### Using API Key

1. Login to Grafana
2. Go to Configuration > API Keys
3. Create API key
4. Use in header: `Authorization: Bearer <api-key>`

### Dashboards

#### List Dashboards

```bash
GET /search
```

**Example**:
```bash
curl -s "https://grafana.securenexus.net/api/search" \
  -H "Authorization: Bearer <api-key>" | jq
```

#### Get Dashboard

```bash
GET /dashboards/uid/<dashboard-uid>
```

**Example**:
```bash
curl -s "https://grafana.securenexus.net/api/dashboards/uid/<uid>" \
  -H "Authorization: Bearer <api-key>" | jq
```

#### Create/Update Dashboard

```bash
POST /dashboards/db
```

**Example**:
```bash
curl -X POST "https://grafana.securenexus.net/api/dashboards/db" \
  -H "Authorization: Bearer <api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {
      "title": "New Dashboard",
      "panels": []
    },
    "overwrite": false
  }'
```

### Datasources

#### List Datasources

```bash
GET /datasources
```

**Example**:
```bash
curl -s "https://grafana.securenexus.net/api/datasources" \
  -H "Authorization: Bearer <api-key>" | jq
```

## Rate Limiting

Most APIs have rate limiting. Check response headers:

- `X-RateLimit-Limit`: Requests allowed per period
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Time when limit resets

## Error Handling

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 429 | Too Many Requests |
| 500 | Internal Server Error |

### Error Response Format

```json
{
  "status": "error",
  "message": "Description of error",
  "code": "ERROR_CODE"
}
```

## Next Steps

- **[Commands Reference](commands.md)**: CLI commands
- **[System Administrator Reference](overview.md)**: Sysadmin quick reference
- **[Security Overview](../security/overview.md)**: API authentication and security
