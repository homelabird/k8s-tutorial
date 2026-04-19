#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/secure-api -n securitycontext-lab --timeout=180s >/dev/null || {
  echo "Deployment secure-api did not become Available"
  exit 1
}

echo "Deployment secure-api becomes Available after the securityContext repair"
