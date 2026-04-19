#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/api-fleet -n affinity-lab --timeout=180s >/dev/null || {
  echo "Deployment api-fleet did not become Available"
  exit 1
}

echo "Deployment api-fleet becomes Available after the placement rules are repaired"
