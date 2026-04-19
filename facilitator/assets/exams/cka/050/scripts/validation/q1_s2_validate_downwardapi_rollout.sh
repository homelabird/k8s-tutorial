#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/meta-api -n downwardapi-lab --timeout=180s >/dev/null || {
  echo "Deployment meta-api did not become Available"
  exit 1
}

echo "Deployment meta-api becomes Available after the env wiring is repaired"
