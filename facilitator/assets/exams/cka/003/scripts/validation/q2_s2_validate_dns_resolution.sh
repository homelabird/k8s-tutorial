#!/bin/bash
set -e

DNS_POLICY=$(kubectl get pod dns-check -n dns-lab -o jsonpath='{.spec.dnsPolicy}' 2>/dev/null || true)
NAMESERVER=$(kubectl get pod dns-check -n dns-lab -o jsonpath='{.spec.dnsConfig.nameservers[0]}' 2>/dev/null || true)
CORE_DNS_IP=$(kubectl get service coredns -n dns-lab -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)

if [ "$DNS_POLICY" != "None" ]; then
  echo "dns-check is expected to use dnsPolicy=None for the dedicated CoreDNS drill"
  exit 1
fi

if [ -z "$CORE_DNS_IP" ] || [ "$NAMESERVER" != "$CORE_DNS_IP" ]; then
  echo "dns-check is not using the dedicated CoreDNS service IP"
  exit 1
fi

OUTPUT="$(kubectl exec -n dns-lab dns-check -- nslookup web.dns-lab.svc.cluster.local 2>&1)" || {
  echo "dns-check failed to resolve the service FQDN"
  exit 1
}

printf '%s\n' "$OUTPUT" >/tmp/q2-nslookup.out
echo "dns-check can resolve web.dns-lab.svc.cluster.local"
exit 0
