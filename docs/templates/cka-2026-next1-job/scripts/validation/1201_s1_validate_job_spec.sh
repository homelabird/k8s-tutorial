#!/usr/bin/env bash
set -euo pipefail

COMPLETIONS="$(kubectl get job report-batch -n job-lab -o jsonpath='{.spec.completions}')"
PARALLELISM="$(kubectl get job report-batch -n job-lab -o jsonpath='{.spec.parallelism}')"
BACKOFF="$(kubectl get job report-batch -n job-lab -o jsonpath='{.spec.backoffLimit}')"
SUSPEND="$(kubectl get job report-batch -n job-lab -o jsonpath='{.spec.suspend}')"

[ "${COMPLETIONS}" = "1" ] || { echo "report-batch must keep completions 1"; exit 1; }
[ "${PARALLELISM}" = "1" ] || { echo "report-batch must use parallelism 1"; exit 1; }
[ "${BACKOFF}" = "1" ] || { echo "report-batch must keep backoffLimit 1"; exit 1; }
[ "${SUSPEND}" = "false" ] || { echo "report-batch must not stay suspended"; exit 1; }

echo "Job report-batch uses the intended completions, parallelism, backoffLimit, and suspend settings"
