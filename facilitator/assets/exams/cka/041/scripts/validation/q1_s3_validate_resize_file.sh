#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n pv-resize-lab deploy/analytics-api -- cat /var/lib/analytics/resize-ready.txt | grep -Fx "resize-ready" >/dev/null || {
  echo "analytics-api must write resize-ready to /var/lib/analytics/resize-ready.txt"
  exit 1
}

echo "The running container writes resize-ready to the mounted analytics path"
