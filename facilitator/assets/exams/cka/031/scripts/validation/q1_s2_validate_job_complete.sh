#!/usr/bin/env bash
set -euo pipefail

kubectl wait --for=condition=complete job/report-batch -n job-lab --timeout=180s >/dev/null || {
  echo "Job report-batch must complete successfully"
  exit 1
}

echo "Job report-batch completes successfully after the repair"
