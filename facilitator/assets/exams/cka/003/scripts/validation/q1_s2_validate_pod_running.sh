#!/bin/bash
set -e

PHASE=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.status.phase}' 2>/dev/null || true)

if [ "$PHASE" = "Running" ]; then
  echo "Pod 'restricted-shell' is running"
  exit 0
fi

echo "Pod 'restricted-shell' is not running"
exit 1
