#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n subpath-lab deploy/subpath-api -- cat /etc/app/app.conf | grep -Fx 'mode=production' >/dev/null || {
  echo "Mounted config file is missing mode=production"
  exit 1
}

kubectl exec -n subpath-lab deploy/subpath-api -- cat /etc/app/app.conf | grep -Fx 'feature=stable' >/dev/null || {
  echo "Mounted config file is missing feature=stable"
  exit 1
}

echo "The running container reads the expected ConfigMap-backed file at /etc/app/app.conf"
