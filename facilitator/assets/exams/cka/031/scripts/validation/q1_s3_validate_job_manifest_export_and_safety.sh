#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/job-diagnostics-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/job-diagnostics-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "job-diagnostics-brief" ] || { echo "Exported manifest must contain job-diagnostics-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "job-lab" ] || { echo "Exported manifest must contain namespace job-lab"; exit 1; }
[ "$(export_key data.targetJob)" = "report-batch" ] || { echo "Exported manifest missing repaired targetJob"; exit 1; }
[ "$(export_key data.safeManifestNote)" = "confirm completions, parallelism, backoffLimit, and pod template command before changing the Job manifest" ] || { echo "Exported manifest missing repaired safeManifestNote"; exit 1; }
! grep -Fq 'targetJob: nightly-batch' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetJob"; exit 1; }
! grep -Fq 'kubectl delete job report-batch -n job-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe delete guidance"; exit 1; }
! grep -Fq 'kubectl create job report-batch-copy --image=busybox:1.36 -n job-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe replacement guidance"; exit 1; }
! grep -Fq 'kubectl replace --force -f report-batch.yaml' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe replace guidance"; exit 1; }
! grep -Fq 'kubectl delete pod -n job-lab -l job-name=report-batch' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe pod deletion guidance"; exit 1; }
! grep -Fq 'rerun the batch from scratch and ignore the existing Job manifest' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe remediation note"; exit 1; }
! grep -Fq 'kubectl delete job report-batch -n job-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete the Job"; exit 1; }
! grep -Fq 'kubectl create job report-batch-copy --image=busybox:1.36 -n job-lab' "$CHECKLIST_FILE" || { echo "Checklist must not create a replacement Job"; exit 1; }
! grep -Fq 'kubectl delete pod -n job-lab -l job-name=report-batch' "$CHECKLIST_FILE" || { echo "Checklist must not delete Job pods"; exit 1; }

echo "job diagnostics manifest export and safety checks passed"
