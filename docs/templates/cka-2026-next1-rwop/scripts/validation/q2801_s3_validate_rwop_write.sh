#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n rwop-lab deploy/rwop-reader -- cat /data/app/reader.txt | grep -Fx 'reader-ready' >/dev/null || {
  echo "rwop-reader did not write reader-ready through the mounted RWOP volume"
  exit 1
}

echo "The running workload can write the expected marker file through the mounted RWOP volume"
