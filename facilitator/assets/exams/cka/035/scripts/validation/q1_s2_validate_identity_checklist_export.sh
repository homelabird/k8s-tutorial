#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/identity-diagnostics-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Deployment Inventory' "$EXPORT_FILE" || { echo "Checklist missing Deployment Inventory section"; exit 1; }
grep -Fxq 'Identity Checks' "$EXPORT_FILE" || { echo "Checklist missing Identity Checks section"; exit 1; }
grep -Fxq 'Safe Manifest Review' "$EXPORT_FILE" || { echo "Checklist missing Safe Manifest Review section"; exit 1; }
grep -Fq "kubectl get deployment metrics-api -n identity-lab -o wide" "$EXPORT_FILE" || { echo "Checklist missing deployment inventory step"; exit 1; }
grep -Fq "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'" "$EXPORT_FILE" || { echo "Checklist missing serviceAccount step"; exit 1; }
grep -Fq "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'" "$EXPORT_FILE" || { echo "Checklist missing automount step"; exit 1; }
grep -Fq "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}'" "$EXPORT_FILE" || { echo "Checklist missing projected token path step"; exit 1; }
grep -Fq "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}'" "$EXPORT_FILE" || { echo "Checklist missing projected audience step"; exit 1; }
grep -Fq "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "$EXPORT_FILE" || { echo "Checklist missing mount path step"; exit 1; }
grep -Fq "kubectl get events -n identity-lab --sort-by=.lastTimestamp" "$EXPORT_FILE" || { echo "Checklist missing event check step"; exit 1; }
grep -Fq "confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest" "$EXPORT_FILE" || { echo "Checklist missing safe manifest note"; exit 1; }

echo "identity diagnostics checklist export is valid"
