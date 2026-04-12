#!/bin/bash
set -euo pipefail

NAMESPACE="node-lab"
DEPLOYMENT="queue-consumer"
TARGET_LABEL="maintenance-lab=target"

kubectl create namespace "$NAMESPACE" >/dev/null 2>&1 || true
kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
mkdir -p /tmp/exam/q1
rm -f /tmp/exam/q1/node-status.txt

TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"
[ -n "$TARGET_NODE" ] || {
  echo "No nodes available for node maintenance drill"
  exit 1
}

while IFS= read -r node_name; do
  [ -n "$node_name" ] || continue
  kubectl label node "$node_name" maintenance-lab- >/dev/null 2>&1 || true
done < <(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

kubectl label node "$TARGET_NODE" "$TARGET_LABEL" --overwrite >/dev/null
kubectl uncordon "$TARGET_NODE" >/dev/null 2>&1 || true
kubectl cordon "$TARGET_NODE" >/dev/null 2>&1 || true

cat <<'EOF_DEPLOY' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: queue-consumer
  namespace: node-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: queue-consumer
  template:
    metadata:
      labels:
        app: queue-consumer
    spec:
      nodeSelector:
        maintenance-lab: target
      containers:
      - name: consumer
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
EOF_DEPLOY

exit 0
