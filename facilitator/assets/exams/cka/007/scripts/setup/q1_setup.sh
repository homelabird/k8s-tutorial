#!/bin/bash
set -euo pipefail

NAMESPACE="rollout-lab"
DEPLOYMENT="web-app"
ORIGINAL_IMAGE="nginx:1.25.3"

kubectl create namespace "$NAMESPACE" >/dev/null 2>&1 || true
mkdir -p /tmp/exam/q1
rm -f /tmp/exam/q1/rollout-history.txt

kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true

cat <<EOF_DEPLOY | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOYMENT}
  namespace: ${NAMESPACE}
  labels:
    app: ${DEPLOYMENT}
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${DEPLOYMENT}
  template:
    metadata:
      labels:
        app: ${DEPLOYMENT}
    spec:
      containers:
      - name: nginx
        image: ${ORIGINAL_IMAGE}
        ports:
        - containerPort: 80
EOF_DEPLOY

kubectl rollout status deployment "$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s >/dev/null

exit 0
