#!/bin/bash
set -e

kubectl delete pod restricted-shell -n secure-workloads --ignore-not-found=true
kubectl delete namespace secure-workloads --ignore-not-found=true
kubectl wait --for=delete namespace/secure-workloads --timeout=60s >/dev/null 2>&1 || true

echo "Setup complete for Question 1"
exit 0
