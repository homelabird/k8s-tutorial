#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="envfrom-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment env-bundle -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete configmap app-env -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete secret app-secret -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_CONFIGMAP' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-env
data:
  MODE: production
EOF_CONFIGMAP

cat <<'EOF_SECRET' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
stringData:
  API_KEY: stable-key
EOF_SECRET

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: env-bundle
spec:
  replicas: 1
  selector:
    matchLabels:
      app: env-bundle
  template:
    metadata:
      labels:
        app: env-bundle
    spec:
      containers:
        - name: bundle
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - test "${MODE}" = "production" && test "${SECRET_API_KEY}" = "stable-key" && sleep 3600
          envFrom:
            - configMapRef:
                name: app-env
            - secretRef:
                name: app-secret
              prefix: APP_
EOF_DEPLOYMENT
