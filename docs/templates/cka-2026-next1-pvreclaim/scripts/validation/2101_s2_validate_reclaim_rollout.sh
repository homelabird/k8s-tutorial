#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/reports-db -n pv-reclaim-lab --timeout=180s >/dev/null || {
  echo "Deployment reports-db must become Available"
  exit 1
}

echo "Deployment reports-db becomes Available after the storage wiring repair"
