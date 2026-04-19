#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/subpath-api -n subpath-lab --timeout=180s >/dev/null || {
  echo "Deployment subpath-api did not become Available"
  exit 1
}

echo "Deployment subpath-api becomes Available after the mount wiring is repaired"
