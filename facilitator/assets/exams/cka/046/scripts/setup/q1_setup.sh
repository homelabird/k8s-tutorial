#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="subpath-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment subpath-api -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete configmap app-config -n "${NAMESPACE}" --ignore-not-found >/dev/null

mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_CONFIGMAP' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.conf: |
    mode=production
    feature=stable
EOF_CONFIGMAP

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: subpath-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: subpath-api
  template:
    metadata:
      labels:
        app: subpath-api
    spec:
      volumes:
        - name: app-config
          configMap:
            name: app-config
            items:
              - key: app.conf
                path: broken/app.conf
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - grep -q '^mode=production$' /etc/app/app.conf && grep -q '^feature=stable$' /etc/app/app.conf && sleep 3600
          volumeMounts:
            - name: app-config
              mountPath: /etc/app/settings.conf
              subPath: broken/app.conf
              readOnly: false
EOF_DEPLOYMENT
