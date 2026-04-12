#!/bin/bash
set -euo pipefail

NAMESPACE="job-lab"
CONFIGMAP="job-diagnostics-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetJob)" = "report-batch" ] || { echo "targetJob must be report-batch"; exit 1; }
[ "$(get_key jobInventory)" = "kubectl get job report-batch -n job-lab -o wide" ] || { echo "jobInventory is incorrect"; exit 1; }
[ "$(get_key completionsCheck)" = "kubectl get job report-batch -n job-lab -o jsonpath='{.spec.completions}'" ] || { echo "completionsCheck is incorrect"; exit 1; }
[ "$(get_key parallelismCheck)" = "kubectl get job report-batch -n job-lab -o jsonpath='{.spec.parallelism}'" ] || { echo "parallelismCheck is incorrect"; exit 1; }
[ "$(get_key backoffLimitCheck)" = "kubectl get job report-batch -n job-lab -o jsonpath='{.spec.backoffLimit}'" ] || { echo "backoffLimitCheck is incorrect"; exit 1; }
[ "$(get_key podEvidenceCheck)" = "kubectl get pods -n job-lab -l job-name=report-batch -o wide" ] || { echo "podEvidenceCheck is incorrect"; exit 1; }
[ "$(get_key jobDescribeCheck)" = "kubectl describe job report-batch -n job-lab" ] || { echo "jobDescribeCheck is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm completions, parallelism, backoffLimit, and pod template command before changing the Job manifest" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "job diagnostics brief contract is repaired"
