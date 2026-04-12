#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q701/dynamic-provisioning-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q701/dynamic-provisioning-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "dynamic-provisioning-brief" ] || { echo "Exported manifest must contain dynamic-provisioning-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "storageclass-lab" ] || { echo "Exported manifest must contain namespace storageclass-lab"; exit 1; }
[ "$(export_key data.targetNamespace)" = "storageclass-lab" ] || { echo "Exported manifest missing repaired targetNamespace"; exit 1; }
[ "$(export_key data.targetStorageClass)" = "exam-standard" ] || { echo "Exported manifest missing repaired targetStorageClass"; exit 1; }
[ "$(export_key data.recommendedManifestLine)" = "storageClassName: exam-standard" ] || { echo "Exported manifest missing repaired recommendedManifestLine"; exit 1; }
! grep -Fq 'targetNamespace: default' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetNamespace"; exit 1; }
! grep -Fq 'kubectl delete pvc reports-pvc -n storageclass-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains stale PVC deletion guidance"; exit 1; }
! grep -Fq 'kubectl delete storageclass exam-archive' "$EXPORT_FILE" || { echo "Exported manifest still contains stale StorageClass deletion guidance"; exit 1; }
! grep -Fq 'storageClassName: ""' "$EXPORT_FILE" || { echo "Exported manifest still contains stale manifest guidance"; exit 1; }
! grep -Fq 'kubectl delete storageclass exam-archive' "$CHECKLIST_FILE" || { echo "Checklist must not delete StorageClass objects"; exit 1; }
! grep -Fq 'kubectl delete pvc reports-pvc -n storageclass-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete the PVC"; exit 1; }
! grep -Fq "kubectl patch storageclass exam-standard -p '{\"provisioner\":\"broken.example.io\"}'" "$CHECKLIST_FILE" || { echo "Checklist must not patch cluster-scoped provisioners"; exit 1; }

echo "dynamic provisioning manifest export and safety checks passed"
