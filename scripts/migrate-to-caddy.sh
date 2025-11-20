#!/bin/bash

# Traefik to Caddy Migration Script
# SecureNexus Infrastructure

set -e  # Exit on error

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups/migration_${TIMESTAMP}"

echo "🚀 Starting Traefik to Caddy Migration"
echo "Timestamp: $TIMESTAMP"
echo "=========================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt user
prompt_user() {
    read -p "$1 (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Function to backup configurations
backup_configs() {
    echo "📦 Creating backup..."
    mkdir -p "$BACKUP_DIR"

    cp compose.yml "$BACKUP_DIR/compose.yml.backup"
    cp -r config/ "$BACKUP_DIR/config-backup/"
    cp -r acme/ "$BACKUP_DIR/acme-backup/" 2>/dev/null || true

    echo "✅ Backup created at: $BACKUP_DIR"
}

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."

    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker is not running"
        exit 1
    fi

    # Check if compose file exists
    if [[ ! -f "compose.yml" ]]; then
        echo "❌ compose.yml not found"
        exit 1
    fi

    # Check if we're in the right directory
    if [[ ! -d "config" ]]; then
        echo "❌ Config directory not found"
        exit 1
    fi

    echo "✅ Prerequisites check passed"
}

# Function to test current setup
test_current_setup() {
    echo "🧪 Testing current Traefik setup..."

    # Test if services are running
    if ! docker compose ps --filter "status=running" | grep -q traefik; then
        echo "⚠️  Traefik is not running"
    fi

    # Test basic connectivity
    if command_exists curl; then
        if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "404\|503"; then
            echo "⚠️  Current setup shows issues (404/503)"
        fi
    fi

    echo "✅ Current setup check completed"
}

# Function to add Caddy volumes
add_caddy_volumes() {
    echo "📝 Adding Caddy volumes to compose.yml..."

    # Check if volumes section exists
    if ! grep -q "^volumes:" compose.yml; then
        echo "❌ No volumes section found in compose.yml"
        exit 1
    fi

    # Add Caddy volumes if not present
    if ! grep -q "caddy-data:" compose.yml; then
        sed -i '/^volumes:/a\  caddy-data:\n  caddy-config:' compose.yml
        echo "✅ Added Caddy volumes"
    else
        echo "✅ Caddy volumes already present"
    fi
}

# Function to stop Traefik
stop_traefik() {
    echo "🛑 Stopping Traefik..."
    docker compose stop traefik || true
    echo "✅ Traefik stopped"
}

# Function to start Caddy
start_caddy() {
    echo "🚀 Starting Caddy..."

    # Add Caddy service to compose.yml
    if ! grep -q "^  caddy:" compose.yml; then
        cat >> compose.yml << 'EOF'

  # Caddy reverse proxy (replaces Traefik)
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    networks: [proxy]
    ports:
      - "80:80"    # HTTP (auto-redirects to HTTPS)
      - "443:443"  # HTTPS
    environment:
      - DOMAIN=${DOMAIN}
      - EMAIL=${EMAIL}
    volumes:
      - ./config/caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - ./config/caddy/snippets:/etc/caddy/snippets:ro
      - caddy-data:/data
      - caddy-config:/config
    healthcheck:
      test: ["CMD", "caddy", "validate", "--config", "/etc/caddy/Caddyfile"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    profiles: ["core"]
EOF
    fi

    # Start Caddy
    docker compose up -d caddy

    # Wait for startup
    echo "⏳ Waiting for Caddy to start..."
    sleep 10

    # Check Caddy status
    if docker compose ps caddy | grep -q "Up"; then
        echo "✅ Caddy started successfully"
    else
        echo "❌ Caddy failed to start"
        docker compose logs caddy --tail 20
        exit 1
    fi
}

# Function to test Caddy setup
test_caddy_setup() {
    echo "🧪 Testing Caddy setup..."

    # Wait a bit more for certificate generation
    echo "⏳ Waiting for SSL certificates..."
    sleep 30

    # Test basic connectivity
    if command_exists curl; then
        echo "Testing main domain..."
        if curl -s -I "https://${DOMAIN:-securenexus.net}" | head -1 | grep -q "200\|301\|302"; then
            echo "✅ Main domain accessible"
        else
            echo "⚠️  Main domain not accessible via HTTPS"
        fi

        echo "Testing SSO domain..."
        if curl -s -I "https://sso.${DOMAIN:-securenexus.net}" | head -1 | grep -q "200\|301\|302"; then
            echo "✅ SSO domain accessible"
        else
            echo "⚠️  SSO domain not accessible"
        fi
    fi

    echo "✅ Basic connectivity test completed"
}

# Function to secure Homarr
secure_homarr() {
    echo "🔒 Securing Homarr (removing port exposure)..."

    # Remove port exposure for Homarr
    if grep -q "7575.*7575" compose.yml; then
        sed -i '/7575.*7575/d' compose.yml
        docker compose up -d homarr
        echo "✅ Homarr port exposure removed"
    else
        echo "✅ Homarr already secured (no port exposure found)"
    fi
}

# Function to show next steps
show_next_steps() {
    echo ""
    echo "🎉 Migration Complete!"
    echo "===================="
    echo ""
    echo "Next steps:"
    echo "1. Test all your services:"
    echo "   - Main site: https://${DOMAIN:-securenexus.net}"
    echo "   - SSO: https://sso.${DOMAIN:-securenexus.net}"
    echo "   - Portal: https://portal.${DOMAIN:-securenexus.net}"
    echo "   - Client sites: https://byrne-accounts.org"
    echo ""
    echo "2. From Tailscale VPN, test admin services:"
    echo "   - Grafana: https://grafana.${DOMAIN:-securenexus.net}"
    echo "   - Prometheus: https://prometheus.${DOMAIN:-securenexus.net}"
    echo ""
    echo "3. Monitor Caddy logs:"
    echo "   docker compose logs -f caddy"
    echo ""
    echo "4. If everything works, clean up:"
    echo "   - Remove Traefik labels from compose.yml"
    echo "   - Remove Traefik service definition"
    echo "   - Update monitoring to use Caddy"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo ""
    echo "For rollback (if needed):"
    echo "  ./scripts/rollback-caddy-migration.sh $TIMESTAMP"
}

# Function to create rollback script
create_rollback_script() {
    cat > "./scripts/rollback-caddy-migration.sh" << EOF
#!/bin/bash
# Rollback script for Caddy migration

BACKUP_TIMESTAMP=\${1:-$TIMESTAMP}
BACKUP_DIR="./backups/migration_\$BACKUP_TIMESTAMP"

echo "🔄 Rolling back Caddy migration..."

if [[ ! -d "\$BACKUP_DIR" ]]; then
    echo "❌ Backup directory not found: \$BACKUP_DIR"
    exit 1
fi

# Stop Caddy
docker compose stop caddy

# Restore compose.yml
cp "\$BACKUP_DIR/compose.yml.backup" compose.yml

# Start Traefik
docker compose up -d traefik

echo "✅ Rollback completed"
echo "Please test your services to ensure they're working"
EOF

    chmod +x "./scripts/rollback-caddy-migration.sh"
}

# Main execution
main() {
    echo "This script will migrate your infrastructure from Traefik to Caddy"
    echo "This will fix the Docker 29.0.0 compatibility issue"
    echo ""

    if ! prompt_user "Do you want to proceed with the migration?"; then
        echo "Migration cancelled"
        exit 0
    fi

    check_prerequisites
    backup_configs
    test_current_setup

    echo ""
    if ! prompt_user "Current setup tested. Proceed with Caddy deployment?"; then
        echo "Migration cancelled"
        exit 0
    fi

    add_caddy_volumes
    stop_traefik
    start_caddy
    test_caddy_setup
    secure_homarr
    create_rollback_script

    show_next_steps
}

# Run main function
main "$@"