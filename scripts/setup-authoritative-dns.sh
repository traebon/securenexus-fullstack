#!/bin/bash
# Setup Authoritative DNS Records with SOA

DOMAIN=${DOMAIN:-"securenexus.net"}
SERVER_IP=$(curl -s http://checkip.amazonaws.com || echo "217.154.37.3")
DNS_SERVER="ns1.$DOMAIN"

echo "Setting up authoritative DNS for domain: $DOMAIN"
echo "Server IP: $SERVER_IP"
echo "DNS Server: $DNS_SERVER"

# Function to add DNS records (reuse from existing script)
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
        "NS")
            json_value="{\"host\":\"$value\",\"ttl\":$ttl}"
            ;;
        "SOA")
            # SOA format: "primary email serial refresh retry expire minimum"
            json_value="{\"text\":\"$value\",\"ttl\":$ttl}"
            ;;
        *)
            echo "Warning: Unsupported record type $type for $domain"
            return 1
            ;;
    esac

    echo "Adding $type record: $domain -> $value"
    docker compose exec -T etcd etcdctl put "$etcd_key" "$json_value"

    if [ $? -eq 0 ]; then
        echo "✓ Successfully added $type record for $domain"
    else
        echo "✗ Failed to add $type record for $domain"
        return 1
    fi
}

# Add SOA (Start of Authority) record - CRITICAL for authoritative DNS
echo "Adding SOA record..."
SOA_VALUE="$DNS_SERVER. admin.$DOMAIN. $(date +%Y%m%d%H) 3600 1800 604800 300"
add_dns_record "$DOMAIN" "SOA" "$SOA_VALUE" 300

# Add NS (Name Server) records
echo "Adding NS records..."
add_dns_record "$DOMAIN" "NS" "$DNS_SERVER." 300

# Add A record for name server itself
add_dns_record "$DNS_SERVER" "A" "$SERVER_IP" 300

# Add main domain and subdomain A records
echo "Adding service A records..."
add_dns_record "$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "auth.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "traefik.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "grafana.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "prometheus.$DOMAIN" "A" "$SERVER_IP" 300
add_dns_record "portal.$DOMAIN" "A" "$SERVER_IP" 300

# Add wildcard
add_dns_record "*.$DOMAIN" "A" "$SERVER_IP" 300

echo ""
echo "✅ Authoritative DNS setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Restart CoreDNS: docker compose restart coredns"
echo "2. Test locally: dig @localhost $DOMAIN"
echo "3. Test SOA: dig @localhost $DOMAIN SOA"
echo "4. Configure your domain registrar to use: $DNS_SERVER"
echo "   (Point NS records to $DNS_SERVER with IP $SERVER_IP)"