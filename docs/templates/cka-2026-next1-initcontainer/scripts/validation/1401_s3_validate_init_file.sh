#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n init-lab deploy/report-api -- cat /work/report.txt | grep -Fx 'ready=1' >/dev/null || {
  echo "The running container must read ready=1 from /work/report.txt"
  exit 1
}

echo "The running container reads the seeded report file from the shared volume"
