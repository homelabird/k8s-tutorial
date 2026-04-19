#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="lifecycle-lab"
OUTPUT_DIR="/tmp/exam/q4901"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment lifecycle-api -n "${NAMESPACE}" --ignore-not-found >/dev/null

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}/lifecycle-rollout-status.txt"

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lifecycle-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lifecycle-api
  template:
    metadata:
      labels:
        app: lifecycle-api
    spec:
      terminationGracePeriodSeconds: 5
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - while true; do sleep 30; done
          lifecycle:
            preStop:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - echo stale-hook
EOF_DEPLOYMENT

kubectl rollout status deployment/lifecycle-api -n "${NAMESPACE}" --timeout=120s >/dev/null
