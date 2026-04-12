#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/daemonset-rollout-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/daemonset-rollout-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "daemonset-rollout-brief" ] || { echo "Exported manifest must contain daemonset-rollout-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "daemonset-lab" ] || { echo "Exported manifest must contain namespace daemonset-lab"; exit 1; }
[ "$(export_key data.targetDaemonSet)" = "log-agent" ] || { echo "Exported manifest missing repaired targetDaemonSet"; exit 1; }
[ "$(export_key data.safeManifestNote)" = "confirm desiredNumberScheduled matches running pods before changing DaemonSet manifests" ] || { echo "Exported manifest missing repaired safeManifestNote"; exit 1; }
! grep -Fq 'targetDaemonSet: metrics-agent' "$EXPORT_FILE" || { echo "Exported manifest still contains stale DaemonSet target"; exit 1; }
! grep -Fq 'kubectl delete daemonset log-agent -n daemonset-lab' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe DaemonSet deletion guidance"; exit 1; }
! grep -Fq 'kubectl scale daemonset log-agent -n daemonset-lab --replicas=0' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe scale guidance"; exit 1; }
! grep -Fq 'cordon the worker' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe cordon guidance"; exit 1; }
! grep -Fq 'kubectl delete daemonset log-agent -n daemonset-lab' "$CHECKLIST_FILE" || { echo "Checklist must not delete the DaemonSet"; exit 1; }
! grep -Fq 'kubectl scale daemonset log-agent -n daemonset-lab --replicas=0' "$CHECKLIST_FILE" || { echo "Checklist must not scale the DaemonSet to zero"; exit 1; }
! grep -Fq 'kubectl cordon kind-cluster-worker' "$CHECKLIST_FILE" || { echo "Checklist must not cordon nodes"; exit 1; }

echo "daemonset manifest export and safety checks passed"
