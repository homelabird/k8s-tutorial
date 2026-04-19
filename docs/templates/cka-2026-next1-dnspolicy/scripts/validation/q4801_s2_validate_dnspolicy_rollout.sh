#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status deployment/dns-client -n dnspolicy-lab --timeout=180s >/dev/null || {
  echo "Deployment dns-client did not become Available"
  exit 1
}

echo "Deployment dns-client becomes Available after the DNS settings are repaired"
