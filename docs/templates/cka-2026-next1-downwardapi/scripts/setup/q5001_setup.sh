#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="downwardapi-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment meta-api -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
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
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - test -n "$POD_NAME" && test -n "$POD_NAMESPACE" && sleep 3600
          env:
            - name: APP_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: APP_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
EOF_DEPLOYMENT
