#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="downwardapi-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "$NAMESPACE" delete deployment meta-api --ignore-not-found >/dev/null
kubectl -n "$NAMESPACE" delete configmap meta-diagnostics-brief --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "$NAMESPACE" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meta-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: meta-api
  template:
    metadata:
      labels:
        app: meta-api
    spec:
      containers:
        - name: api
          image: nginx:1.25.3
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
EOF_DEPLOYMENT

kubectl rollout status deployment/meta-api -n "$NAMESPACE" --timeout=120s >/dev/null

cat <<'EOF_CM' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: meta-diagnostics-brief
  namespace: downwardapi-lab
data:
  targetDeployment: meta-worker
  deploymentInventory: kubectl get pods -n downwardapi-lab
  envNameCheck: kubectl rollout restart deployment meta-api -n downwardapi-lab
  fieldPathCheck: kubectl edit deployment meta-api -n downwardapi-lab
  namespaceFieldCheck: kubectl delete pod -n downwardapi-lab -l app=meta-api
  containerNameCheck: kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.replicas}'
  imageCheck: kubectl patch deployment meta-api -n downwardapi-lab --type merge -p '{}'
  eventCheck: kubectl get configmap -n downwardapi-lab
  safeManifestNote: restart the deployment and patch env wiring until metadata looks correct
EOF_CM

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/meta-diagnostics-brief.yaml" "$OUTPUT_DIR/meta-diagnostics-checklist.txt"
