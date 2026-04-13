#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/init-diagnostics-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/init-diagnostics-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "init-diagnostics-brief" ] || { echo "Exported manifest must contain init-diagnostics-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "init-lab" ] || { echo "Exported manifest must contain namespace init-lab"; exit 1; }
[ "$(export_key data.targetDeployment)" = "report-api" ] || { echo "Exported manifest missing repaired targetDeployment"; exit 1; }
[ "$(export_key data.safeManifestNote)" = "confirm init container command, shared volume name, and mount paths before changing the Deployment manifest" ] || { echo "Exported manifest missing repaired safeManifestNote"; exit 1; }
! grep -Fq 'targetDeployment: report-worker' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetDeployment"; exit 1; }
! grep -Fq 'restart the deployment and patch the init command until the pod becomes ready' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe remediation note"; exit 1; }
! grep -Fq 'kubectl delete pod' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe pod deletion guidance"; exit 1; }
! grep -Fq 'kubectl patch deployment' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe patch guidance"; exit 1; }
! grep -Fq 'kubectl rollout restart' "$CHECKLIST_FILE" || { echo "Checklist must not restart the Deployment"; exit 1; }
! grep -Fq 'kubectl patch deployment' "$CHECKLIST_FILE" || { echo "Checklist must not patch the live Deployment"; exit 1; }
! grep -Fq 'kubectl delete pod' "$CHECKLIST_FILE" || { echo "Checklist must not delete pods"; exit 1; }

echo "init diagnostics manifest export and safety checks passed"
