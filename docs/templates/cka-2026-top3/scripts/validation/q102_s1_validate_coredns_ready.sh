#!/bin/bash
set -e

kubectl rollout status deployment coredns -n kube-system --timeout=120s >/dev/null 2>&1
echo "CoreDNS deployment is available"
exit 0
