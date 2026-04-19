#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="daemonset-lab"

kubectl delete daemonset log-agent -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF_DAEMONSET' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-agent
  namespace: daemonset-lab
spec:
  selector:
    matchLabels:
      app: log-agent
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: log-agent
    spec:
      nodeSelector:
        kubernetes.io/os: windows
      tolerations:
        - operator: Exists
      containers:
        - name: agent
          image: busybox:1.36
          command:
            - sh
            - -c
            - sleep 3600
EOF_DAEMONSET
