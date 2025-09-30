#!/bin/bash
# Fix NS records for securenexus.net

DOMAIN="securenexus.net"
ETCD_HOST="etcd"
ETCD_PORT="2379"
DNS_TTL="300"

# etcd v3 API (current etcdctl format)
echo "Adding NS records to etcd..."

# Delete any existing conflicting NS records
docker compose exec etcd etcdctl del /coredns/net/securenexus/NS --prefix

# Add NS records - using the same format that works for A records
docker compose exec etcd etcdctl put /coredns/net/securenexus/NS/1 '{"host":"ns1.securenexus.net.","ttl":300}'
docker compose exec etcd etcdctl put /coredns/net/securenexus/NS/2 '{"host":"ns2.securenexus.net.","ttl":300}'

# Also try the direct NS record format
docker compose exec etcd etcdctl put /coredns/net/securenexus/NS '{"host":"ns1.securenexus.net.","ttl":300}'

echo "Restarting CoreDNS to refresh cache..."
docker compose restart coredns

echo "Waiting for CoreDNS to start..."
sleep 5

echo "Testing NS record resolution..."
dig @127.0.0.1 securenexus.net NS

echo "NS record fix attempt completed."