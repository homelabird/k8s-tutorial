#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="qos-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment reporting-api -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporting-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reporting-api
  template:
    metadata:
      labels:
        app: reporting-api
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - sleep 3600
          resources:
            requests:
              cpu: "64"
              memory: 128Gi
            limits:
              cpu: "64"
              memory: 128Gi
EOF_DEPLOYMENT
