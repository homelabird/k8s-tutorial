#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n pv-reclaim-lab deploy/reports-db -- cat /var/lib/reporting/ready.txt | grep -Fx "reports-ready" >/dev/null || {
  echo "reports-db must write reports-ready to /var/lib/reporting/ready.txt"
  exit 1
}

echo "The running container writes reports-ready to the mounted storage path"
