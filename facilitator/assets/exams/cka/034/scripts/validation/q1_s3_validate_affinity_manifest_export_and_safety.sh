#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/placement-diagnostics-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/placement-diagnostics-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "placement-diagnostics-brief" ] || { echo "Exported manifest must contain placement-diagnostics-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "affinity-lab" ] || { echo "Exported manifest must contain namespace affinity-lab"; exit 1; }
[ "$(export_key data.targetDeployment)" = "api-fleet" ] || { echo "Exported manifest missing repaired targetDeployment"; exit 1; }
[ "$(export_key data.safeManifestNote)" = "confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest" ] || { echo "Exported manifest missing repaired safeManifestNote"; exit 1; }
! grep -Fq 'targetDeployment: edge-fleet' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetDeployment"; exit 1; }
! grep -Fq 'restart the deployment, scale replicas down, and patch placement rules until the pods settle' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe remediation note"; exit 1; }
! grep -Fq 'kubectl delete pod' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe pod deletion guidance"; exit 1; }
! grep -Fq 'kubectl patch deployment' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe patch guidance"; exit 1; }
! grep -Fq 'kubectl rollout restart' "$CHECKLIST_FILE" || { echo "Checklist must not restart the Deployment"; exit 1; }
! grep -Fq 'kubectl patch deployment' "$CHECKLIST_FILE" || { echo "Checklist must not patch the live Deployment"; exit 1; }
! grep -Fq 'kubectl delete pod' "$CHECKLIST_FILE" || { echo "Checklist must not delete pods"; exit 1; }
! grep -Fq 'kubectl scale deployment' "$CHECKLIST_FILE" || { echo "Checklist must not scale the Deployment"; exit 1; }

echo "affinity diagnostics manifest export and safety checks passed"
