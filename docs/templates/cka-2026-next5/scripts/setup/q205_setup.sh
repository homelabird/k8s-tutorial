#!/bin/bash
set -euo pipefail

NAMESPACE="scheduling-lab"
DEPLOYMENT="metrics-agent"
IMAGE="nginx:1.25.5"
TARGET_NODE="$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane,!node-role.kubernetes.io/master' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

if [ -z "$TARGET_NODE" ]; then
  TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"
fi

kubectl create namespace "$NAMESPACE" >/dev/null 2>&1 || true

kubectl taint nodes "$TARGET_NODE" node-role.kubernetes.io/control-plane- >/dev/null 2>&1 || true
kubectl taint nodes "$TARGET_NODE" node-role.kubernetes.io/master- >/dev/null 2>&1 || true
kubectl taint nodes "$TARGET_NODE" dedicated=ops:NoSchedule --overwrite >/dev/null
kubectl label nodes "$TARGET_NODE" workload=ops --overwrite >/dev/null

for NODE in $(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  if [ "$NODE" = "$TARGET_NODE" ]; then
    continue
  fi
  kubectl taint nodes "$NODE" dedicated- >/dev/null 2>&1 || true
  kubectl label nodes "$NODE" workload=general --overwrite >/dev/null 2>&1 || true
done

cat <<EOF_DEPLOY | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOYMENT}
  namespace: ${NAMESPACE}
  labels:
    app: ${DEPLOYMENT}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${DEPLOYMENT}
  template:
    metadata:
      labels:
        app: ${DEPLOYMENT}
    spec:
      nodeSelector:
        workload: general
      containers:
      - name: agent
        image: ${IMAGE}
        ports:
        - containerPort: 80
EOF_DEPLOY

exit 0
