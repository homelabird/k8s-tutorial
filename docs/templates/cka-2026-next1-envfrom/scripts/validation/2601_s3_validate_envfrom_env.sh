#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n envfrom-lab deploy/env-bundle -- env | grep -Fx 'MODE=production' >/dev/null || {
  echo "The running container must expose MODE=production"
  exit 1
}

kubectl exec -n envfrom-lab deploy/env-bundle -- env | grep -Fx 'SECRET_API_KEY=stable-key' >/dev/null || {
  echo "The running container must expose SECRET_API_KEY=stable-key"
  exit 1
}

echo "The running container reads the expected ConfigMap and Secret-backed environment variables"
