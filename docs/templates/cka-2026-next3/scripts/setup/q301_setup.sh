#!/bin/bash
set -euo pipefail

NAMESPACE="config-lab"
DEPLOYMENT="report-viewer"

kubectl create namespace "$NAMESPACE" >/dev/null 2>&1 || true
kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete configmap report-config -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete secret report-credentials -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true

kubectl create configmap report-config \
  -n "$NAMESPACE" \
  --from-literal=APP_MODE=production >/dev/null

kubectl create secret generic report-credentials \
  -n "$NAMESPACE" \
  --from-literal=username=reporter \
  --from-literal=password=super-secret-password >/dev/null

cat <<'EOF_DEPLOY' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-viewer
  namespace: config-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: report-viewer
  template:
    metadata:
      labels:
        app: report-viewer
    spec:
      containers:
      - name: viewer
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          [ "$APP_MODE" = "production" ] || exit 1
          [ "$REPORT_USER" = "reporter" ] || exit 1
          [ "$REPORT_PASS" = "super-secret-password" ] || exit 1
          sleep 3600
        env:
        - name: APP_MODE
          valueFrom:
            configMapKeyRef:
              name: report-config
              key: mode
        - name: REPORT_USER
          valueFrom:
            secretKeyRef:
              name: report-credentials
              key: user
        - name: REPORT_PASS
          value: hardcoded-password
EOF_DEPLOY

exit 0
