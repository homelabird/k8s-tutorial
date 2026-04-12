#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/cronjob-diagnostics-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'CronJob Inventory' "$EXPORT_FILE" || { echo "Checklist missing CronJob Inventory section"; exit 1; }
grep -Fxq 'Scheduling Checks' "$EXPORT_FILE" || { echo "Checklist missing Scheduling Checks section"; exit 1; }
grep -Fxq 'Safe Manifest Review' "$EXPORT_FILE" || { echo "Checklist missing Safe Manifest Review section"; exit 1; }
grep -Fq 'kubectl get cronjob log-pruner -n cronjob-lab -o wide' "$EXPORT_FILE" || { echo "Checklist missing CronJob inventory step"; exit 1; }
grep -Fq "kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.schedule}'" "$EXPORT_FILE" || { echo "Checklist missing schedule check step"; exit 1; }
grep -Fq "kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.suspend}'" "$EXPORT_FILE" || { echo "Checklist missing suspend check step"; exit 1; }
grep -Fq "kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.concurrencyPolicy}'" "$EXPORT_FILE" || { echo "Checklist missing concurrency policy step"; exit 1; }
grep -Fq 'kubectl get cronjob log-pruner -n cronjob-lab -o custom-columns=SUCCESS:.spec.successfulJobsHistoryLimit,FAILED:.spec.failedJobsHistoryLimit' "$EXPORT_FILE" || { echo "Checklist missing history limits step"; exit 1; }
grep -Fq "kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}'" "$EXPORT_FILE" || { echo "Checklist missing job template check step"; exit 1; }
grep -Fq 'confirm schedule, suspend=false, and history limits before changing the CronJob manifest' "$EXPORT_FILE" || { echo "Checklist missing safe manifest note"; exit 1; }

echo "cronjob diagnostics checklist export is valid"
