#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="identity-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment metrics-api -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete serviceaccount metrics-sa -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_SERVICEACCOUNT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-sa
EOF_SERVICEACCOUNT

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metrics-api
  template:
    metadata:
      labels:
        app: metrics-api
    spec:
      serviceAccountName: default
      automountServiceAccountToken: true
      volumes:
        - name: identity-token
          projected:
            sources:
              - serviceAccountToken:
                  path: wrong-token
                  audience: legacy-api
                  expirationSeconds: 3600
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - test -s /var/run/metrics/token && sleep 3600
          volumeMounts:
            - name: identity-token
              mountPath: /var/run/identity
              readOnly: true
EOF_DEPLOYMENT
