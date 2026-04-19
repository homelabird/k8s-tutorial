#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/private-api -n registry-auth-lab --timeout=180s >/dev/null || {
  echo "Deployment private-api did not become Available"
  exit 1
}

echo "Deployment private-api becomes Available after the pull-secret wiring is repaired"
