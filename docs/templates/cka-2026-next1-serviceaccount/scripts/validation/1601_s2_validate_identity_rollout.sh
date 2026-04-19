#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/metrics-api -n identity-lab --timeout=180s >/dev/null || {
  echo "Deployment metrics-api did not become Available"
  exit 1
}

echo "Deployment metrics-api becomes Available after the identity wiring is repaired"
