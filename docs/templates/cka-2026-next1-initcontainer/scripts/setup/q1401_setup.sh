#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="init-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment report-api -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: report-api
  template:
    metadata:
      labels:
        app: report-api
    spec:
      volumes:
        - name: shared-data
          emptyDir: {}
        - name: seed-data
          emptyDir: {}
      initContainers:
        - name: bootstrap
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - mkdir -p /seed && echo broken=1 > /seed/report.txt
          volumeMounts:
            - name: seed-data
              mountPath: /seed
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - grep -Fx 'ready=1' /work/report.txt && sleep 3600
          volumeMounts:
            - name: shared-data
              mountPath: /work
EOF_DEPLOYMENT
