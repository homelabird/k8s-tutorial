#!/bin/bash
set -euo pipefail

NAMESPACE="daemonset-lab"
OUTPUT_DIR="/tmp/exam/q1001"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/daemonset-rollout-brief.yaml" "$OUTPUT_DIR/daemonset-rollout-checklist.txt"

cat <<'EOF_DAEMONSET' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-agent
  namespace: daemonset-lab
spec:
  selector:
    matchLabels:
      app: log-agent
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: log-agent
    spec:
      tolerations:
      - operator: Exists
      containers:
      - name: agent
        image: busybox:1.36
        command: ['sh', '-c', 'sleep 3600']
EOF_DAEMONSET

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: daemonset-rollout-brief
  namespace: daemonset-lab
data:
  targetDaemonSet: metrics-agent
  daemonSetInventory: kubectl get deployment -n daemonset-lab
  rolloutStatusCheck: kubectl scale daemonset log-agent -n daemonset-lab --replicas=0
  nodeInventory: kubectl get node kind-cluster-worker -o yaml
  nodeCoverageCheck: kubectl get pods -A
  updateStrategyCheck: kubectl delete daemonset log-agent -n daemonset-lab
  safeManifestNote: convert the DaemonSet into a Deployment and cordon the worker before retrying
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/daemonset-rollout-checklist.txt"
DaemonSet Inventory
- kubectl delete daemonset log-agent -n daemonset-lab

Node Coverage
- kubectl cordon kind-cluster-worker

Safe Rollout Review
- kubectl scale daemonset log-agent -n daemonset-lab --replicas=0
EOF_STALE

exit 0
