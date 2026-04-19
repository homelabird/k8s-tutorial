#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="debug-lab"

kubectl delete pod orders-api -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF_POD' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: orders-api
  labels:
    app: orders-api
spec:
  containers:
    - name: api
      image: busybox:1.36
      command:
        - sh
        - -c
        - echo orders-api-ready && sleep 3600
EOF_POD
