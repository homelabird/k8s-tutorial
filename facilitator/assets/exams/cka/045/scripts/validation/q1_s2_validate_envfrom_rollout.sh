#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/env-bundle -n envfrom-lab --timeout=180s >/dev/null || {
  echo "Deployment env-bundle did not become Available"
  exit 1
}

echo "Deployment env-bundle becomes Available after the envFrom wiring is repaired"
