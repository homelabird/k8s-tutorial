#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="taints-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "$NAMESPACE" delete deployment taint-api --ignore-not-found >/dev/null
kubectl -n "$NAMESPACE" delete configmap taint-diagnostics-brief --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "$NAMESPACE" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: taint-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: taint-api
  template:
    metadata:
      labels:
        app: taint-api
    spec:
      nodeSelector:
        workload: ops
      tolerations:
        - key: workload
          operator: Equal
          value: ops
          effect: NoExecute
          tolerationSeconds: 60
      containers:
        - name: api
          image: nginx:1.25.3
EOF_DEPLOYMENT

kubectl rollout status deployment/taint-api -n "$NAMESPACE" --timeout=120s >/dev/null

cat <<'EOF_CM' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: taint-diagnostics-brief
  namespace: taints-lab
data:
  targetDeployment: taint-worker
  deploymentInventory: kubectl get pods -n taints-lab
  tolerationKeyCheck: kubectl drain worker-1 --ignore-daemonsets
  tolerationEffectCheck: kubectl delete pod -n taints-lab -l app=taint-api
  tolerationOperatorCheck: kubectl rollout restart deployment taint-api -n taints-lab
  tolerationSecondsCheck: kubectl patch node worker-1 --type merge -p '{}'
  nodeSelectorCheck: kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.replicas}'
  eventCheck: kubectl get configmap -n taints-lab
  safeManifestNote: drain the node and patch taints until the workload stabilizes
EOF_CM

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/taint-diagnostics-brief.yaml" "$OUTPUT_DIR/taint-diagnostics-checklist.txt"
