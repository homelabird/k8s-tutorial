#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/probe-diagnostics-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/probe-diagnostics-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "probe-diagnostics-brief" ] || { echo "Exported manifest must contain probe-diagnostics-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "probe-lab" ] || { echo "Exported manifest must contain namespace probe-lab"; exit 1; }
[ "$(export_key data.targetDeployment)" = "health-api" ] || { echo "Exported manifest missing repaired targetDeployment"; exit 1; }
[ "$(export_key data.safeManifestNote)" = "confirm startup, liveness, readiness probe paths and thresholds before changing the Deployment manifest" ] || { echo "Exported manifest missing repaired safeManifestNote"; exit 1; }
! grep -Fq 'targetDeployment: api-v2' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetDeployment"; exit 1; }
! grep -Fq 'kubectl rollout restart deployment/health-api -n probe-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe rollout restart guidance"; exit 1; }
! grep -Fq 'kubectl patch deployment health-api -n probe-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe patch guidance"; exit 1; }
! grep -Fq 'kubectl delete pod -n probe-lab -l app=health-api' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe pod deletion guidance"; exit 1; }
! grep -Fq 'restart the Deployment until the probes look healthy enough' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe remediation note"; exit 1; }
! grep -Fq 'kubectl rollout restart deployment/health-api -n probe-lab' "$CHECKLIST_FILE" || { echo "Checklist must not restart the Deployment"; exit 1; }
! grep -Fq 'kubectl patch deployment health-api -n probe-lab' "$CHECKLIST_FILE" || { echo "Checklist must not patch the live Deployment"; exit 1; }
! grep -Fq 'kubectl delete pod -n probe-lab -l app=health-api' "$CHECKLIST_FILE" || { echo "Checklist must not delete pods"; exit 1; }

echo "probe diagnostics manifest export and safety checks passed"
