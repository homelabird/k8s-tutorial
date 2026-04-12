#!/bin/bash
set -euo pipefail

NAMESPACE="kubeadm-lab"
CONFIGMAP="upgrade-brief"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/upgrade-plan.txt" "$OUTPUT_DIR/upgrade-brief.yaml"

cat <<'EOF_CONFIGMAP' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: upgrade-brief
  namespace: kubeadm-lab
data:
  currentVersion: v1.31.5
  targetVersion: v1.31.7
  controlPlaneEndpoint: old-api.internal:6443
  maintenanceNode: cp-maint-0
  planCommand: kubeadm upgrade node
  applyCommand: kubeadm upgrade node experimental-control-plane
  drainCommand: kubectl drain cp-maint-0
  uncordonCommand: kubectl cordon cp-maint-0
  backupPaths: /etc/kubernetes/admin.conf
EOF_CONFIGMAP

exit 0
