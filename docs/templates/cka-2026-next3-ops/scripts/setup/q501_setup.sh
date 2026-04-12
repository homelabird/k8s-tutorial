#!/bin/bash
set -euo pipefail

NAMESPACE="controlplane-lab"
CONFIGMAP="component-repair-brief"
OUTPUT_DIR="/tmp/exam/q501"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/component-repair-brief.yaml" "$OUTPUT_DIR/control-plane-checklist.txt"

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: component-repair-brief
  namespace: controlplane-lab
data:
  schedulerManifest: /etc/kubernetes/manifests/kube-apiserver.yaml
  controllerManagerManifest: /etc/kubernetes/manifests/old-controller-manager.yaml
  schedulerHealthz: https://127.0.0.1:10251/healthz
  controllerManagerHealthz: https://127.0.0.1:10252/healthz
  schedulerKubeconfig: /etc/kubernetes/admin.conf
  controllerManagerKubeconfig: /etc/kubernetes/controller.conf
  schedulerLogHint: systemctl restart kubelet
  controllerManagerLogHint: rm -f /etc/kubernetes/manifests/kube-controller-manager.yaml
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/control-plane-checklist.txt"
Scheduler
- systemctl restart kubelet
- inspect /etc/kubernetes/manifests/kube-apiserver.yaml

Verification
- kubectl get componentstatuses
EOF_STALE

exit 0
