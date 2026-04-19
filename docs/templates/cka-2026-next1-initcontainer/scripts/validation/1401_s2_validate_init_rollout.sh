#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/report-api -n init-lab --timeout=180s >/dev/null || {
  echo "Deployment report-api did not become Available"
  exit 1
}

echo "Deployment report-api becomes Available after the init-container handoff is repaired"
