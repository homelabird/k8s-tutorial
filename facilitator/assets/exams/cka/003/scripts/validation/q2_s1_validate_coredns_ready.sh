#!/bin/bash
set -e

kubectl rollout status deployment coredns -n dns-lab --timeout=120s >/dev/null 2>&1

CORE_FILE=$(kubectl get configmap coredns -n dns-lab -o jsonpath='{.data.Corefile}' 2>/dev/null || true)
ENDPOINT_IP=$(kubectl get endpoints coredns -n dns-lab -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null || true)

if ! printf '%s\n' "$CORE_FILE" | grep -q 'kubernetes cluster.local in-addr.arpa ip6.arpa'; then
  echo "Dedicated CoreDNS is not serving cluster.local"
  exit 1
fi

if printf '%s\n' "$CORE_FILE" | grep -q 'broken.local'; then
  echo "Dedicated CoreDNS still references broken.local"
  exit 1
fi

if [ -z "$ENDPOINT_IP" ]; then
  echo "Dedicated CoreDNS service has no ready endpoints"
  exit 1
fi

echo "Dedicated CoreDNS serves cluster.local and is available"
exit 0
