#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q502/connectivity-brief.yaml"
MATRIX_FILE="/tmp/exam/q502/connectivity-matrix.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$MATRIX_FILE" ] || { echo "Expected matrix export at $MATRIX_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "connectivity-brief" ] || { echo "Exported manifest must contain connectivity-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "connectivity-lab" ] || { echo "Exported manifest must contain namespace connectivity-lab"; exit 1; }
[ "$(export_key data.serviceName)" = "echo-api" ] || { echo "Exported manifest missing repaired serviceName"; exit 1; }
[ "$(export_key data.headlessServiceName)" = "echo-api-headless" ] || { echo "Exported manifest missing repaired headlessServiceName"; exit 1; }
! grep -Fq 'echo-svc' "$EXPORT_FILE" || { echo "Exported manifest still contains stale serviceName"; exit 1; }
! grep -Fq 'echo-hl' "$EXPORT_FILE" || { echo "Exported manifest still contains stale headlessServiceName"; exit 1; }
! grep -Fq 'kubectl delete svc echo-api -n connectivity-lab' "$MATRIX_FILE" || { echo "Matrix must not delete Services"; exit 1; }
! grep -Fq 'kubectl rollout restart deployment echo-api -n connectivity-lab' "$MATRIX_FILE" || { echo "Matrix must not restart workloads"; exit 1; }

echo "connectivity manifest export and safety checks passed"
