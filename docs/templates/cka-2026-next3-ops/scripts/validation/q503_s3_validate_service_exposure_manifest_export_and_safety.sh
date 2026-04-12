#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q503/service-exposure-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q503/service-exposure-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "service-exposure-brief" ] || { echo "Exported manifest must contain service-exposure-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "service-debug-lab" ] || { echo "Exported manifest must contain namespace service-debug-lab"; exit 1; }
[ "$(export_key data.serviceName)" = "echo-api" ] || { echo "Exported manifest missing repaired serviceName"; exit 1; }
[ "$(export_key data.selectorValue)" = "echo-api" ] || { echo "Exported manifest missing repaired selectorValue"; exit 1; }
! grep -Fq 'web-svc' "$EXPORT_FILE" || { echo "Exported manifest still contains stale serviceName"; exit 1; }
! grep -Fq 'component' "$EXPORT_FILE" || { echo "Exported manifest still contains stale selectorKey"; exit 1; }
! grep -Fq 'kubectl delete svc echo-api -n service-debug-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete Services"; exit 1; }
! grep -Fq 'kubectl patch deployment echo-api -n service-debug-lab' "$CHECKLIST_FILE" || { echo "Checklist must not patch Deployments"; exit 1; }
! grep -Fq 'kubectl apply -f ingress.yaml' "$CHECKLIST_FILE" || { echo "Checklist must not introduce ingress resources"; exit 1; }

echo "service exposure manifest export and safety checks passed"
