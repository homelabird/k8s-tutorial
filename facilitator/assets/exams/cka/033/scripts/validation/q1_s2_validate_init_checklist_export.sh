#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/init-diagnostics-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Deployment Inventory' "$EXPORT_FILE" || { echo "Checklist missing Deployment Inventory section"; exit 1; }
grep -Fxq 'Init Container Checks' "$EXPORT_FILE" || { echo "Checklist missing Init Container Checks section"; exit 1; }
grep -Fxq 'Safe Manifest Review' "$EXPORT_FILE" || { echo "Checklist missing Safe Manifest Review section"; exit 1; }
grep -Fq 'kubectl get deployment report-api -n init-lab -o wide' "$EXPORT_FILE" || { echo "Checklist missing deployment inventory step"; exit 1; }
grep -Fq "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[*].name}'" "$EXPORT_FILE" || { echo "Checklist missing init container inventory step"; exit 1; }
grep -Fq "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].command}'" "$EXPORT_FILE" || { echo "Checklist missing init command step"; exit 1; }
grep -Fq "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.volumes[0].name}'" "$EXPORT_FILE" || { echo "Checklist missing shared volume step"; exit 1; }
grep -Fq "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}'" "$EXPORT_FILE" || { echo "Checklist missing init mount step"; exit 1; }
grep -Fq "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "$EXPORT_FILE" || { echo "Checklist missing app mount step"; exit 1; }
grep -Fq 'kubectl get events -n init-lab --sort-by=.lastTimestamp' "$EXPORT_FILE" || { echo "Checklist missing event check step"; exit 1; }
grep -Fq 'confirm init container command, shared volume name, and mount paths before changing the Deployment manifest' "$EXPORT_FILE" || { echo "Checklist missing safe manifest note"; exit 1; }

echo "init diagnostics checklist export is valid"
