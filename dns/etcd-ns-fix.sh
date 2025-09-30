#!/bin/bash
# CoreDNS etcd NS record fix script
# Research and implement correct NS record structure for zone apex

# TODO(human) - Research CoreDNS etcd plugin NS record format
# Current issue: CoreDNS not returning NS records for securenexus.net apex domain
#
# Tasks to investigate:
# 1. Check CoreDNS etcd plugin documentation for apex NS record key format
# 2. Test different key patterns:
#    - /coredns/net/securenexus/@/NS (common apex notation)
#    - /coredns/net/securenexus/*/NS (wildcard format)
#    - /coredns/net/securenexus/NS (current format - not working)
# 3. Verify if multiple NS records need array format or separate keys
# 4. Test the solution with: dig @localhost NS securenexus.net

echo "This script needs human implementation to fix CoreDNS etcd NS records"
echo "Current status: NS records exist in etcd but CoreDNS returns NXDOMAIN"
echo "Expected: CoreDNS should return both ns1.securenexus.net and ns2.securenexus.net"