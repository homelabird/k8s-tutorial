#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="priority-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment batch-api -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete priorityclass ops-critical --ignore-not-found >/dev/null

cat <<'EOF_PRIORITYCLASS' | kubectl apply -f - >/dev/null
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: ops-critical
value: 100000
preemptionPolicy: Never
globalDefault: false
description: Non-preempting priority class for critical batch workloads
EOF_PRIORITYCLASS

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: batch-api
  template:
    metadata:
      labels:
        app: batch-api
    spec:
      priorityClassName: ops-standard
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - sleep 3600
EOF_DEPLOYMENT
