#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/stateful-identity-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/stateful-identity-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "stateful-identity-brief" ] || { echo "Exported manifest must contain stateful-identity-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "stateful-lab" ] || { echo "Exported manifest must contain namespace stateful-lab"; exit 1; }
[ "$(export_key data.targetStatefulSet)" = "web" ] || { echo "Exported manifest missing repaired targetStatefulSet"; exit 1; }
[ "$(export_key data.headlessService)" = "web-svc" ] || { echo "Exported manifest missing repaired headlessService"; exit 1; }
[ "$(export_key data.safeManifestNote)" = "confirm serviceName: web-svc and stable pod ordinals before changing manifests" ] || { echo "Exported manifest missing repaired safeManifestNote"; exit 1; }
! grep -Fq 'targetStatefulSet: cache' "$EXPORT_FILE" || { echo "Exported manifest still contains stale StatefulSet target"; exit 1; }
! grep -Fq 'kubectl patch svc web-svc -n stateful-lab -p' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe service patch guidance"; exit 1; }
! grep -Fq 'kubectl delete pvc -n stateful-lab --all' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe pvc deletion guidance"; exit 1; }
! grep -Fq 'delete the StatefulSet and recreate it' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe StatefulSet recreation guidance"; exit 1; }
! grep -Fq 'kubectl delete statefulset web -n stateful-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete the StatefulSet"; exit 1; }
! grep -Fq 'kubectl patch svc web-svc -n stateful-lab -p' "$CHECKLIST_FILE" || { echo "Checklist must not convert the headless service"; exit 1; }
! grep -Fq 'kubectl delete pvc -n stateful-lab --all' "$CHECKLIST_FILE" || { echo "Checklist must not delete PVCs"; exit 1; }

echo "stateful identity manifest export and safety checks passed"
