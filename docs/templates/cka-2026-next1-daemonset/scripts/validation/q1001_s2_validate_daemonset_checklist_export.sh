#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1001/daemonset-rollout-checklist.txt"
[ -f "$EXPORT_FILE" ] || { echo "Expected checklist export at $EXPORT_FILE"; exit 1; }

grep -Fxq 'DaemonSet Inventory' "$EXPORT_FILE" || { echo "Checklist missing DaemonSet Inventory section"; exit 1; }
grep -Fxq 'Node Coverage' "$EXPORT_FILE" || { echo "Checklist missing Node Coverage section"; exit 1; }
grep -Fxq 'Safe Rollout Review' "$EXPORT_FILE" || { echo "Checklist missing Safe Rollout Review section"; exit 1; }
grep -Fq 'kubectl get daemonset log-agent -n daemonset-lab -o wide' "$EXPORT_FILE" || { echo "Checklist missing DaemonSet inventory step"; exit 1; }
grep -Fq 'kubectl rollout status daemonset/log-agent -n daemonset-lab --timeout=180s' "$EXPORT_FILE" || { echo "Checklist missing rollout status step"; exit 1; }
grep -Fq 'kubectl get nodes -o wide' "$EXPORT_FILE" || { echo "Checklist missing node inventory step"; exit 1; }
grep -Fq 'kubectl get pods -n daemonset-lab -l app=log-agent -o wide' "$EXPORT_FILE" || { echo "Checklist missing node coverage step"; exit 1; }
grep -Fq "kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.spec.updateStrategy.type}'" "$EXPORT_FILE" || { echo "Checklist missing update strategy step"; exit 1; }
grep -Fq 'confirm desiredNumberScheduled matches running pods before changing DaemonSet manifests' "$EXPORT_FILE" || { echo "Checklist missing safe manifest note"; exit 1; }

echo "daemonset checklist export is valid"
