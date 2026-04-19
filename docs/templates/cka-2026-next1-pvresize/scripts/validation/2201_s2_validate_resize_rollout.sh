#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/analytics-api -n pv-resize-lab --timeout=180s >/dev/null || {
  echo "Deployment analytics-api must become Available"
  exit 1
}

echo "Deployment analytics-api becomes Available after the resize storage repair"
