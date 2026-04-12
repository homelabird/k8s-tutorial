#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/dynamic-provisioning-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'StorageClass Inventory' "$EXPORT_FILE" || { echo "Checklist missing StorageClass Inventory section"; exit 1; }
grep -Fxq 'PVC Analysis' "$EXPORT_FILE" || { echo "Checklist missing PVC Analysis section"; exit 1; }
grep -Fxq 'Safe Manifest Fix' "$EXPORT_FILE" || { echo "Checklist missing Safe Manifest Fix section"; exit 1; }
grep -Fq 'kubectl get storageclass' "$EXPORT_FILE" || { echo "Checklist missing storageclass list step"; exit 1; }
grep -Fq 'kubectl get storageclass -o custom-columns=NAME:.metadata.name,DEFAULT:.metadata.annotations.storageclass\.kubernetes\.io/is-default-class' "$EXPORT_FILE" || { echo "Checklist missing default StorageClass inspection step"; exit 1; }
grep -Fq 'kubectl describe pvc reports-pvc -n storageclass-lab' "$EXPORT_FILE" || { echo "Checklist missing pvc describe step"; exit 1; }
grep -Fq 'kubectl describe pod reports-api -n storageclass-lab' "$EXPORT_FILE" || { echo "Checklist missing workload describe step"; exit 1; }
grep -Fq 'kubectl get events -n storageclass-lab --sort-by=.lastTimestamp' "$EXPORT_FILE" || { echo "Checklist missing event inspection step"; exit 1; }
grep -Fq 'kubectl get pvc reports-pvc -n storageclass-lab -o yaml' "$EXPORT_FILE" || { echo "Checklist missing pvc manifest export step"; exit 1; }
grep -Fq 'ensure the manifest contains storageClassName: exam-standard' "$EXPORT_FILE" || { echo "Checklist missing safe manifest guidance"; exit 1; }

echo "dynamic provisioning checklist export is valid"
