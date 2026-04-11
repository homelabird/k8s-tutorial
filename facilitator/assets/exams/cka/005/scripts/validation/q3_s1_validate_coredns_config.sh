#!/bin/bash
set -e

kubectl rollout status deployment coredns -n kube-system --timeout=120s >/dev/null 2>&1

CORE_FILE=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' 2>/dev/null || true)

if ! printf '%s\n' "$CORE_FILE" | grep -q 'kubernetes cluster.local in-addr.arpa ip6.arpa'; then
  echo "CoreDNS Corefile is not serving cluster.local"
  exit 1
fi

if printf '%s\n' "$CORE_FILE" | grep -q 'broken.local'; then
  echo "CoreDNS Corefile still references broken.local"
  exit 1
fi

echo "CoreDNS in kube-system is restored to cluster.local and available"
exit 0
