#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/cronjob-diagnostics-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/cronjob-diagnostics-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "cronjob-diagnostics-brief" ] || { echo "Exported manifest must contain cronjob-diagnostics-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "cronjob-lab" ] || { echo "Exported manifest must contain namespace cronjob-lab"; exit 1; }
[ "$(export_key data.targetCronJob)" = "log-pruner" ] || { echo "Exported manifest missing repaired targetCronJob"; exit 1; }
[ "$(export_key data.safeManifestNote)" = "confirm schedule, suspend=false, and history limits before changing the CronJob manifest" ] || { echo "Exported manifest missing repaired safeManifestNote"; exit 1; }
! grep -Fq 'targetCronJob: metrics-pruner' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetCronJob"; exit 1; }
! grep -Fq 'kubectl delete cronjob log-pruner -n cronjob-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe delete guidance"; exit 1; }
! grep -Fq 'kubectl create job --from=cronjob/log-pruner manual-pruner -n cronjob-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe manual job guidance"; exit 1; }
! grep -Fq 'kubectl patch cronjob log-pruner -n cronjob-lab -p' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe schedule patch guidance"; exit 1; }
! grep -Fq 'convert the CronJob into a one-off Job and disable history pruning' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe remediation note"; exit 1; }
! grep -Fq 'kubectl delete cronjob log-pruner -n cronjob-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete the CronJob"; exit 1; }
! grep -Fq 'kubectl create job --from=cronjob/log-pruner manual-pruner -n cronjob-lab' "$CHECKLIST_FILE" || { echo "Checklist must not create a manual Job"; exit 1; }
! grep -Fq 'kubectl patch cronjob log-pruner -n cronjob-lab -p' "$CHECKLIST_FILE" || { echo "Checklist must not patch the schedule"; exit 1; }

echo "cronjob diagnostics manifest export and safety checks passed"
