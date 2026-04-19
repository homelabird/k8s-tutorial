#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="projectedvolume-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment bundle-api -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete configmap bundle-config -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete secret bundle-secret -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_CONFIGMAP' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: bundle-config
data:
  app.conf: |
    mode=production
EOF_CONFIGMAP

cat <<'EOF_SECRET' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: Secret
metadata:
  name: bundle-secret
stringData:
  token: token=stable
EOF_SECRET

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bundle-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bundle-api
  template:
    metadata:
      labels:
        app: bundle-api
    spec:
      volumes:
        - name: bundle-data
          projected:
            sources:
              - configMap:
                  name: bundle-config
                  items:
                    - key: app.conf
                      path: broken/app.conf
              - secret:
                  name: bundle-secret
                  items:
                    - key: token
                      path: auth/token
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - grep -Fx 'mode=production' /etc/bundle/config/app.conf && grep -Fx 'token=stable' /etc/bundle/secret/token && sleep 3600
          volumeMounts:
            - name: bundle-data
              mountPath: /bundle
              readOnly: false
EOF_DEPLOYMENT
