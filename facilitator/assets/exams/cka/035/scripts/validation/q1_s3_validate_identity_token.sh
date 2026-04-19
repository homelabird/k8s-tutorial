#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n identity-lab deploy/metrics-api -- test -s /var/run/metrics/token || {
  echo "The running container must read the projected token at /var/run/metrics/token"
  exit 1
}

echo "The running container reads the projected service account token at /var/run/metrics/token"
