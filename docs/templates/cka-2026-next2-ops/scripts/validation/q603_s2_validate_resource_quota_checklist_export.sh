#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q603/resource-quota-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Quota Inspection' "$EXPORT_FILE" || { echo "Checklist missing Quota Inspection section"; exit 1; }
grep -Fxq 'LimitRange Inspection' "$EXPORT_FILE" || { echo "Checklist missing LimitRange Inspection section"; exit 1; }
grep -Fxq 'Workload Sizing Guidance' "$EXPORT_FILE" || { echo "Checklist missing Workload Sizing Guidance section"; exit 1; }
grep -Fq 'kubectl get resourcequota -n quota-lab' "$EXPORT_FILE" || { echo "Checklist missing resourcequota list step"; exit 1; }
grep -Fq 'kubectl describe resourcequota compute-quota -n quota-lab' "$EXPORT_FILE" || { echo "Checklist missing resourcequota describe step"; exit 1; }
grep -Fq 'kubectl describe limitrange default-limits -n quota-lab' "$EXPORT_FILE" || { echo "Checklist missing limitrange describe step"; exit 1; }
grep -Fq 'kubectl get limitrange default-limits -n quota-lab -o yaml' "$EXPORT_FILE" || { echo "Checklist missing limitrange export step"; exit 1; }
grep -Fq 'kubectl describe deployment api -n quota-lab' "$EXPORT_FILE" || { echo "Checklist missing workload inspection step"; exit 1; }
grep -Fq 'kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi' "$EXPORT_FILE" || { echo "Checklist missing safe resource patch guidance"; exit 1; }

echo "resource quota checklist export is valid"
