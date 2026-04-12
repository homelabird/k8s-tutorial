#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q801/disruption-planning-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q801/disruption-planning-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "disruption-planning-brief" ] || { echo "Exported manifest must contain disruption-planning-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "disruption-lab" ] || { echo "Exported manifest must contain namespace disruption-lab"; exit 1; }
[ "$(export_key data.targetNode)" = "kind-cluster-worker" ] || { echo "Exported manifest missing repaired targetNode"; exit 1; }
[ "$(export_key data.drainPreview)" = "kubectl drain kind-cluster-worker --ignore-daemonsets --delete-emptydir-data --dry-run=client" ] || { echo "Exported manifest missing repaired drainPreview"; exit 1; }
[ "$(export_key data.safeRemediationNote)" = "review PodDisruptionBudget impact before any non-dry-run drain" ] || { echo "Exported manifest missing repaired safeRemediationNote"; exit 1; }
! grep -Fq 'targetNode: kind-cluster-control-plane' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetNode"; exit 1; }
! grep -Fq 'kubectl delete pdb -A' "$EXPORT_FILE" || { echo "Exported manifest still contains stale PDB deletion guidance"; exit 1; }
! grep -Fq 'kubectl drain kind-cluster-worker --force --ignore-daemonsets --delete-emptydir-data' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe live drain guidance"; exit 1; }
! grep -Fq 'delete the PodDisruptionBudget if eviction is blocked' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe remediation note"; exit 1; }
! grep -Fq 'kubectl delete pdb api-pdb -n disruption-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete PodDisruptionBudgets"; exit 1; }
! grep -Fq 'kubectl delete pod -n disruption-lab -l app=api' "$CHECKLIST_FILE" || { echo "Checklist must not delete workload pods"; exit 1; }
! grep -Fq 'kubectl drain kind-cluster-worker --force --ignore-daemonsets --delete-emptydir-data' "$CHECKLIST_FILE" || { echo "Checklist must not use a live forced drain"; exit 1; }

echo "disruption planning manifest export and safety checks passed"
