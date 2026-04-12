#!/bin/bash
set -euo pipefail

NAMESPACE="node-health-lab"
CONFIGMAP="node-recovery-brief"
OUTPUT_DIR="/tmp/exam/q601"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/node-recovery-brief.yaml" "$OUTPUT_DIR/node-notready-checklist.txt"

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: node-recovery-brief
  namespace: node-health-lab
data:
  targetNode: worker-0
  nodeConditionCheck: kubectl get node worker-0
  kubeletServiceCheck: sudo systemctl restart kubelet
  kubeletLogCheck: sudo journalctl -u kubelet -n 5
  configCheck: sudo ls /etc/kubernetes
  runtimeCheck: sudo docker ps
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/node-notready-checklist.txt"
Node Conditions
- sudo reboot

Kubelet Service
- sudo systemctl restart kubelet

Runtime and Config
- kubectl drain kind-cluster-worker --ignore-daemonsets
EOF_STALE

exit 0
