#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/health-api -n probe-lab --timeout=180s >/dev/null || {
  echo "Deployment health-api did not become Available"
  exit 1
}

echo "Deployment health-api becomes Available after the probe wiring is repaired"
