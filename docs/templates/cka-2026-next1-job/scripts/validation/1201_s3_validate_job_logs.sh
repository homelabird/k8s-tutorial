#!/usr/bin/env bash
set -euo pipefail

POD_NAME="$(kubectl get pods -n job-lab -l job-name=report-batch -o jsonpath='{.items[0].metadata.name}')"
[ -n "${POD_NAME}" ] || { echo "Completed Job pod must exist"; exit 1; }

kubectl logs -n job-lab "${POD_NAME}" | grep -Fx "batch-ready" >/dev/null || {
  echo "Completed Job pod must log batch-ready"
  exit 1
}

echo "The completed Job pod logs batch-ready"
