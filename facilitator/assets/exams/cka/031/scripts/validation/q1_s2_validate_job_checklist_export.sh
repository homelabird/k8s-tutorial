#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/job-diagnostics-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'Job Inventory' "$EXPORT_FILE" || { echo "Checklist missing Job Inventory section"; exit 1; }
grep -Fxq 'Pod Evidence' "$EXPORT_FILE" || { echo "Checklist missing Pod Evidence section"; exit 1; }
grep -Fxq 'Safe Manifest Review' "$EXPORT_FILE" || { echo "Checklist missing Safe Manifest Review section"; exit 1; }
grep -Fq 'kubectl get job report-batch -n job-lab -o wide' "$EXPORT_FILE" || { echo "Checklist missing Job inventory step"; exit 1; }
grep -Fq "kubectl get job report-batch -n job-lab -o jsonpath='{.spec.completions}'" "$EXPORT_FILE" || { echo "Checklist missing completions check step"; exit 1; }
grep -Fq "kubectl get job report-batch -n job-lab -o jsonpath='{.spec.parallelism}'" "$EXPORT_FILE" || { echo "Checklist missing parallelism check step"; exit 1; }
grep -Fq "kubectl get job report-batch -n job-lab -o jsonpath='{.spec.backoffLimit}'" "$EXPORT_FILE" || { echo "Checklist missing backoffLimit check step"; exit 1; }
grep -Fq 'kubectl get pods -n job-lab -l job-name=report-batch -o wide' "$EXPORT_FILE" || { echo "Checklist missing pod evidence step"; exit 1; }
grep -Fq 'kubectl describe job report-batch -n job-lab' "$EXPORT_FILE" || { echo "Checklist missing job describe step"; exit 1; }
grep -Fq 'confirm completions, parallelism, backoffLimit, and pod template command before changing the Job manifest' "$EXPORT_FILE" || { echo "Checklist missing safe manifest note"; exit 1; }

echo "job diagnostics checklist export is valid"
