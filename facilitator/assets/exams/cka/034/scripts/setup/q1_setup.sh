#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="affinity-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment api-fleet -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-fleet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-fleet
  template:
    metadata:
      labels:
        app: api-fleet
    spec:
      nodeSelector:
        kubernetes.io/os: windows
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: wrong-app
              topologyKey: broken.topology/key
      topologySpreadConstraints:
        - maxSkew: 2
          topologyKey: broken.topology/key
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: wrong-app
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - sleep 3600
EOF_DEPLOYMENT
