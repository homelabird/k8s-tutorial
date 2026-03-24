#!/bin/bash
set -e

kubectl rollout status deployment coredns -n dns-lab --timeout=120s >/dev/null 2>&1

CORE_FILE=$(kubectl get configmap coredns -n dns-lab -o jsonpath='{.data.Corefile}' 2>/dev/null || true)

if ! printf '%s\n' "$CORE_FILE" | grep -q 'kubernetes cluster.local in-addr.arpa ip6.arpa'; then
  echo "Dedicated CoreDNS is not serving cluster.local"
  exit 1
fi

echo "Dedicated CoreDNS serves cluster.local and is available"
exit 0
