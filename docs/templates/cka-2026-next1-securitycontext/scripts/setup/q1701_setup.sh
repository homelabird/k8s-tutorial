#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="securitycontext-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment secure-api -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-api
  template:
    metadata:
      labels:
        app: secure-api
    spec:
      securityContext:
        runAsUser: 0
        fsGroup: 0
      volumes:
        - name: data
          emptyDir: {}
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - id -u | grep -Fx 1000 && echo secure > /data/secure.txt && sleep 3600
          securityContext:
            allowPrivilegeEscalation: true
            seccompProfile:
              type: Unconfined
          volumeMounts:
            - name: data
              mountPath: /data
EOF_DEPLOYMENT
