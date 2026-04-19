#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="taints-lab"
DEPLOYMENT="taint-api"
TARGET_NODE="$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane,!node-role.kubernetes.io/master' -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

if [ -z "${TARGET_NODE}" ]; then
  TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"
fi

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment "${DEPLOYMENT}" -n "${NAMESPACE}" --ignore-not-found >/dev/null

kubectl taint nodes "${TARGET_NODE}" node-role.kubernetes.io/control-plane- >/dev/null 2>&1 || true
kubectl taint nodes "${TARGET_NODE}" node-role.kubernetes.io/master- >/dev/null 2>&1 || true
kubectl taint nodes "${TARGET_NODE}" dedicated=ops:NoExecute --overwrite >/dev/null
kubectl label nodes "${TARGET_NODE}" workload=ops --overwrite >/dev/null

for NODE in $(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  if [ "${NODE}" = "${TARGET_NODE}" ]; then
    continue
  fi
  kubectl taint nodes "${NODE}" dedicated- >/dev/null 2>&1 || true
  kubectl label nodes "${NODE}" workload=general --overwrite >/dev/null 2>&1 || true
done

cat <<EOF_DEPLOYMENT | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOYMENT}
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
      tolerations:
        - key: dedicated
          operator: Equal
          value: ops
          effect: NoExecute
          tolerationSeconds: 60
      containers:
        - name: api
          image: nginx:1.25.3
EOF_DEPLOYMENT
