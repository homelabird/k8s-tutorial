#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/bundle-api -n projectedvolume-lab --timeout=180s >/dev/null || {
  echo "Deployment bundle-api did not become Available"
  exit 1
}

echo "Deployment bundle-api becomes Available after the projected volume repair"
