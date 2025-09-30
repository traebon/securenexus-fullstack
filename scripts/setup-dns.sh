#!/bin/bash
# DNS Records Setup Script for CoreDNS with etcd backend

DOMAIN=${DOMAIN:-"securenexus.net"}
ETCD_ENDPOINT="http://localhost:2379"

echo "Setting up DNS records for domain: $DOMAIN"

# Function to add DNS records to etcd for CoreDNS
# Parameters: add_dns_record <domain> <type> <value> <ttl>
# Format: CoreDNS etcd plugin expects keys like /coredns/{domain}/{type}
# Value format: {"host":"1.2.3.4","ttl":300} for A records
#               {"host":"server.example.com","ttl":300} for CNAME
#               {"text":"v=spf1 include:_spf.google.com ~all","ttl":300} for TXT
add_dns_record() {
    local domain=$1
    local type=$2
    local value=$3
    local ttl=${4:-300}

    # Reverse the domain for etcd key (CoreDNS etcd format)
    local reversed_domain=$(echo "$domain" | sed 's/\./\//g' | awk -F/ '{for(i=NF;i>=1;i--) printf "%s%s", $i, (i>1?"/":"");}')
    local etcd_key="/coredns/$reversed_domain/$type"

    # Create JSON value based on record type
    local json_value
    case "$type" in
        "A"|"AAAA")
            json_value="{\"host\":\"$value\",\"ttl\":$ttl}"
            ;;
        "CNAME")
            json_value="{\"host\":\"$value\",\"ttl\":$ttl}"
            ;;
        "TXT")
            json_value="{\"text\":\"$value\",\"ttl\":$ttl}"
            ;;
        "MX")
            # Assuming value format: "priority target"
            local priority=$(echo "$value" | cut -d' ' -f1)
            local target=$(echo "$value" | cut -d' ' -f2-)
            json_value="{\"host\":\"$target\",\"priority\":$priority,\"ttl\":$ttl}"
            ;;
        *)
            echo "Warning: Unsupported record type $type for $domain"
            return 1
            ;;
    esac

    # Add record to etcd
    echo "Adding $type record: $domain -> $value"
    docker compose exec -T etcd etcdctl put "$etcd_key" "$json_value"

    if [ $? -eq 0 ]; then
        echo "✓ Successfully added $type record for $domain"
    else
        echo "✗ Failed to add $type record for $domain"
        return 1
    fi
}

# Function to get current server IP (fallback)
get_server_ip() {
    curl -s http://checkip.amazonaws.com || echo "127.0.0.1"
}

SERVER_IP=$(get_server_ip)
echo "Detected server IP: $SERVER_IP"

# Add basic DNS records
echo "Adding DNS records..."

# Main domain A record
add_dns_record "$DOMAIN" "A" "$SERVER_IP" 300

# Subdomains for services
add_dns_record "authentik.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "traefik.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "grafana.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "prometheus.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "pdns.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "portal.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "brand.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "mail.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "dns.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "vpn.$DOMAIN" "A" "$SERVER_IP" 300

# Add wildcard for flexibility
add_dns_record "*.$DOMAIN" "A" "$SERVER_IP" 300

# Example TXT records
add_dns_record "$DOMAIN" "TXT" "v=spf1 -all" 300
add_dns_record "_dmarc.$DOMAIN" "TXT" "v=DMARC1; p=reject; rua=mailto:dmarc@$DOMAIN" 300

echo "DNS setup complete!"
echo ""
echo "You can test with:"
echo "  dig @localhost -p 5353 $DOMAIN"
echo "  dig @localhost -p 5353 auth.$DOMAIN"
