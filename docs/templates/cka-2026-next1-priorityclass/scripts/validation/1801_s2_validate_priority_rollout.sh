#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/batch-api -n priority-lab --timeout=180s >/dev/null || {
  echo "Deployment batch-api did not become Available"
  exit 1
}

echo "Deployment batch-api becomes Available after the PriorityClass wiring is repaired"
