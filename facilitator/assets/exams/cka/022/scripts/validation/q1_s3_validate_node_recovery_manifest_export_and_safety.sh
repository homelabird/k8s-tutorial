#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/node-recovery-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/node-notready-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "node-recovery-brief" ] || { echo "Exported manifest must contain node-recovery-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "node-health-lab" ] || { echo "Exported manifest must contain namespace node-health-lab"; exit 1; }
[ "$(export_key data.targetNode)" = "kind-cluster-worker" ] || { echo "Exported manifest missing repaired targetNode"; exit 1; }
[ "$(export_key data.runtimeCheck)" = "sudo crictl info" ] || { echo "Exported manifest missing repaired runtimeCheck"; exit 1; }
! grep -Fq 'worker-0' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetNode"; exit 1; }
! grep -Fq 'sudo docker ps' "$EXPORT_FILE" || { echo "Exported manifest still contains stale runtimeCheck"; exit 1; }
! grep -Fq 'sudo systemctl restart kubelet' "$CHECKLIST_FILE" || { echo "Checklist must not restart kubelet"; exit 1; }
! grep -Fq 'sudo reboot' "$CHECKLIST_FILE" || { echo "Checklist must not reboot the node"; exit 1; }
! grep -Fq 'kubectl drain kind-cluster-worker --ignore-daemonsets' "$CHECKLIST_FILE" || { echo "Checklist must not drain the node"; exit 1; }

echo "node recovery manifest export and safety checks passed"
