#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q1/runtime-diagnostics-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q1/runtime-diagnostics-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "runtime-diagnostics-brief" ] || { echo "Exported manifest must contain runtime-diagnostics-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "runtime-lab" ] || { echo "Exported manifest must contain namespace runtime-lab"; exit 1; }
[ "$(export_key data.targetNode)" = "kind-cluster-control-plane" ] || { echo "Exported manifest missing repaired targetNode"; exit 1; }
[ "$(export_key data.runtimeServiceCheck)" = "sudo systemctl status containerd" ] || { echo "Exported manifest missing repaired runtimeServiceCheck"; exit 1; }
! grep -Fq 'targetNode: kind-cluster-worker' "$EXPORT_FILE" || { echo "Exported manifest still contains stale targetNode"; exit 1; }
! grep -Fq 'sudo crictl info' "$EXPORT_FILE" || { echo "Exported manifest still contains stale crictl info guidance"; exit 1; }
! grep -Fq 'sudo systemctl restart containerd' "$EXPORT_FILE" || { echo "Exported manifest still contains unsafe runtime restart guidance"; exit 1; }
! grep -Fq 'sudo systemctl stop containerd' "$CHECKLIST_FILE" || { echo "Checklist must not stop containerd"; exit 1; }
! grep -Fq 'sudo systemctl restart containerd' "$CHECKLIST_FILE" || { echo "Checklist must not restart containerd"; exit 1; }
! grep -Fq 'sudo systemctl restart kubelet' "$CHECKLIST_FILE" || { echo "Checklist must not restart kubelet"; exit 1; }
! grep -Fq 'sed -i' "$CHECKLIST_FILE" || { echo "Checklist must not rewrite kubelet config"; exit 1; }
! grep -Fq '> /var/lib/kubelet/config.yaml' "$CHECKLIST_FILE" || { echo "Checklist must not overwrite kubelet config"; exit 1; }

echo "runtime diagnostics manifest export and safety checks passed"
