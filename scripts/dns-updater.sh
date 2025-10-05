#!/bin/bash
# DNS Updater - Automatically creates DNS records in etcd based on Docker container labels
# Label format: coredns.name=myservice creates myservice.${DOMAIN}

set -eo pipefail

# Configuration from environment
ETCD_HOST="${ETCD_HOST:-etcd}"
ETCD_PORT="${ETCD_PORT:-2379}"
DOMAIN="${DOMAIN:-example.com}"
DNS_TTL="${DNS_TTL:-300}"
DOCKER_HOST="${DOCKER_HOST:-docker-proxy:2375}"

# etcd v3 API endpoint
ETCD_API="http://${ETCD_HOST}:${ETCD_PORT}/v3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to set a DNS record in etcd
set_dns_record() {
    local name="$1"
    local ip="$2"
    local type="${3:-A}"

    # Construct the full domain name
    local fqdn="${name}.${DOMAIN}"

    # Create etcd key path for CoreDNS (NOT reverse DNS format)
    # Format: /coredns/{domain}/{subdomain}/{type}
    # Example: /coredns/securenexus.net/dns/A
    local key="/coredns/${DOMAIN}/${name}/${type}"

    # Create JSON value for the record
    local value='{"host":"'${ip}'","ttl":'${DNS_TTL}'}'

    # Encode key and value to base64 for etcd v3 API
    local key_b64=$(echo -n "${key}" | base64 -w0)
    local value_b64=$(echo -n "${value}" | base64 -w0)

    # Set the record in etcd using v3 API
    local response=$(curl -sS -X POST "${ETCD_API}/kv/put" \
        -H "Content-Type: application/json" \
        -d "{\"key\":\"${key_b64}\",\"value\":\"${value_b64}\"}")

    if [ $? -eq 0 ]; then
        log_info "Created DNS record: ${fqdn} -> ${ip}"
    else
        log_error "Failed to create DNS record: ${fqdn}"
        return 1
    fi
}

# Function to delete a DNS record from etcd
delete_dns_record() {
    local name="$1"
    local type="${2:-A}"

    # Construct the full domain name
    local fqdn="${name}.${DOMAIN}"

    # Create etcd key path
    local key="/coredns/${DOMAIN}/${name}/${type}"

    # Encode key to base64 for etcd v3 API
    local key_b64=$(echo -n "${key}" | base64 -w0)

    # Delete the record from etcd using v3 API
    local response=$(curl -sS -X POST "${ETCD_API}/kv/deleterange" \
        -H "Content-Type: application/json" \
        -d "{\"key\":\"${key_b64}\"}")

    if [ $? -eq 0 ]; then
        log_info "Deleted DNS record: ${fqdn}"
    else
        log_warn "Failed to delete DNS record: ${fqdn}"
    fi
}

# Function to get container IP address
get_container_ip() {
    local container_id="$1"

    # Get the IP address from the proxy network
    local ip=$(docker -H tcp://${DOCKER_HOST} inspect "$container_id" \
        --format '{{range .NetworkSettings.Networks}}{{if eq .NetworkMode "proxy"}}{{.IPAddress}}{{end}}{{end}}' \
        2>/dev/null | head -1)

    # If not found in proxy network, try the first available network
    if [ -z "$ip" ]; then
        ip=$(docker -H tcp://${DOCKER_HOST} inspect "$container_id" \
            --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
            2>/dev/null | head -1)
    fi

    echo "$ip"
}

# Function to sync all containers
sync_all_containers() {
    log_info "Starting DNS sync for all containers..."

    # Get all running containers with coredns.name label
    local containers=$(docker -H tcp://${DOCKER_HOST} ps --filter "label=coredns.name" --format "{{.ID}}" 2>/dev/null)

    if [ -z "$containers" ]; then
        log_warn "No containers found with 'coredns.name' label"
        return 0
    fi

    # Process each container
    while IFS= read -r container_id; do
        if [ -z "$container_id" ]; then
            continue
        fi

        # Get the DNS name from the label
        local dns_name=$(docker -H tcp://${DOCKER_HOST} inspect "$container_id" \
            --format '{{index .Config.Labels "coredns.name"}}' 2>/dev/null)

        if [ -n "$dns_name" ]; then
            # Get the container's IP address
            local ip=$(get_container_ip "$container_id")

            if [ -n "$ip" ]; then
                set_dns_record "$dns_name" "$ip"
            else
                log_warn "No IP address found for container $container_id"
            fi
        fi
    done <<< "$containers"

    log_info "DNS sync completed"
}

# Function to watch for container events
watch_container_events() {
    log_info "Watching for container events..."

    docker -H tcp://${DOCKER_HOST} events \
        --filter "event=start" \
        --filter "event=stop" \
        --filter "event=die" \
        --format "{{.Status}} {{.ID}}" | while read event container_id; do

        # Check if container has coredns.name label
        local dns_name=$(docker -H tcp://${DOCKER_HOST} inspect "$container_id" \
            --format '{{index .Config.Labels "coredns.name"}}' 2>/dev/null)

        if [ -n "$dns_name" ]; then
            case "$event" in
                start)
                    # Container started - add DNS record
                    local ip=$(get_container_ip "$container_id")
                    if [ -n "$ip" ]; then
                        set_dns_record "$dns_name" "$ip"
                    fi
                    ;;
                stop|die)
                    # Container stopped - remove DNS record
                    delete_dns_record "$dns_name"
                    ;;
            esac
        fi
    done
}

# Main execution
main() {
    log_info "DNS Updater starting..."
    log_info "Configuration: DOMAIN=${DOMAIN}, ETCD=${ETCD_HOST}:${ETCD_PORT}, TTL=${DNS_TTL}"

    # Wait for etcd to be ready
    while ! curl -sS -X POST "${ETCD_API}/maintenance/status" -H "Content-Type: application/json" > /dev/null 2>&1; do
        log_warn "Waiting for etcd to be ready..."
        sleep 5
    done

    log_info "etcd is ready"

    # Initial sync of all containers
    sync_all_containers

    # Watch for container events
    watch_container_events
}

# Run main function
main