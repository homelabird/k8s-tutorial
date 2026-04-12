#!/bin/bash
set -euo pipefail

EXPORT_FILE="/tmp/exam/q501/component-repair-brief.yaml"
CHECKLIST_FILE="/tmp/exam/q501/control-plane-checklist.txt"

[ -f "$EXPORT_FILE" ] || { echo "Expected manifest export at $EXPORT_FILE"; exit 1; }
[ -f "$CHECKLIST_FILE" ] || { echo "Expected checklist export at $CHECKLIST_FILE"; exit 1; }

export_key() {
  kubectl create --dry-run=client -f "$EXPORT_FILE" -o "jsonpath={.$1}" 2>/dev/null
}

[ "$(export_key metadata.name)" = "component-repair-brief" ] || { echo "Exported manifest must contain component-repair-brief"; exit 1; }
[ "$(export_key metadata.namespace)" = "controlplane-lab" ] || { echo "Exported manifest must contain namespace controlplane-lab"; exit 1; }
[ "$(export_key data.schedulerManifest)" = "/etc/kubernetes/manifests/kube-scheduler.yaml" ] || { echo "Exported manifest missing repaired schedulerManifest"; exit 1; }
[ "$(export_key data.controllerManagerManifest)" = "/etc/kubernetes/manifests/kube-controller-manager.yaml" ] || { echo "Exported manifest missing repaired controllerManagerManifest"; exit 1; }
! grep -Fq '/etc/kubernetes/manifests/kube-apiserver.yaml' "$EXPORT_FILE" || { echo "Exported manifest still contains stale scheduler manifest path"; exit 1; }
! grep -Fq '/etc/kubernetes/manifests/old-controller-manager.yaml' "$EXPORT_FILE" || { echo "Exported manifest still contains stale controller-manager manifest path"; exit 1; }
! grep -Fq 'systemctl restart kubelet' "$CHECKLIST_FILE" || { echo "Checklist must not restart kubelet"; exit 1; }
! grep -Fq 'rm -f /etc/kubernetes/manifests/kube-controller-manager.yaml' "$CHECKLIST_FILE" || { echo "Checklist must not delete static pod manifests"; exit 1; }

echo "control plane manifest export and safety checks passed"
