#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q603/resource-guardrails-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q603/resource-quota-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "resource-guardrails-brief" ] || { echo "Exported manifest must contain resource-guardrails-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "quota-lab" ] || { echo "Exported manifest must contain namespace quota-lab"; exit 1; }
[ "$(export_key data.targetNamespace)" = "quota-lab" ] || { echo "Exported manifest missing repaired targetNamespace"; exit 1; }
[ "$(export_key data.recommendedPatch)" = "kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi" ] || { echo "Exported manifest missing repaired recommendedPatch"; exit 1; }
! grep -Fq 'targetNamespace: default' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetNamespace"; exit 1; }
! grep -Fq 'kubectl delete resourcequota compute-quota -n quota-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains stale quota guidance"; exit 1; }
! grep -Fq 'kubectl get limitrange -A' "$EXPORT_FILE" || { echo "Exported manifest still contains stale limitrange guidance"; exit 1; }
! grep -Fq 'kubectl delete resourcequota compute-quota -n quota-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete the resource quota"; exit 1; }
! grep -Fq 'kubectl delete limitrange default-limits -n quota-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete the limitrange"; exit 1; }
! grep -Fq 'kubectl scale deployment api -n quota-lab --replicas=0' "$CHECKLIST_FILE" || { echo "Checklist must not scale workloads to zero"; exit 1; }
! grep -Fq '--requests=cpu=0,memory=0 --limits=cpu=0,memory=0' "$CHECKLIST_FILE" || { echo "Checklist must not strip resource requests or limits"; exit 1; }

echo "resource guardrails manifest export and safety checks passed"
