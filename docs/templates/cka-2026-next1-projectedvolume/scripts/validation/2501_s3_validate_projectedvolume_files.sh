#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n projectedvolume-lab deploy/bundle-api -- cat /etc/bundle/config/app.conf | grep -Fx 'mode=production' >/dev/null || {
  echo "Projected ConfigMap file is missing mode=production"
  exit 1
}

kubectl exec -n projectedvolume-lab deploy/bundle-api -- cat /etc/bundle/secret/token | grep -Fx 'token=stable' >/dev/null || {
  echo "Projected Secret file is missing token=stable"
  exit 1
}

echo "The running container reads the projected ConfigMap and Secret files from /etc/bundle"
