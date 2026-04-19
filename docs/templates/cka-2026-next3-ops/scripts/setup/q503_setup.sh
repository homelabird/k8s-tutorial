#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="service-debug-lab"

kubectl delete pod net-debug -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete deployment echo-api -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete service echo-api -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-api
  namespace: service-debug-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: echo-api
  template:
    metadata:
      labels:
        app: echo-api
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command:
            - sh
            - -c
            - mkdir -p /www && echo ok > /www/healthz && httpd -f -p 8080 -h /www
          ports:
            - containerPort: 8080
EOF_DEPLOYMENT

cat <<'EOF_SERVICE' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Service
metadata:
  name: echo-api
  namespace: service-debug-lab
spec:
  type: NodePort
  selector:
    app: legacy-api
  ports:
    - port: 8080
      targetPort: 9090
EOF_SERVICE

cat <<'EOF_DEBUG' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: net-debug
  namespace: service-debug-lab
spec:
  containers:
    - name: net-debug
      image: busybox:1.36
      command:
        - sh
        - -c
        - sleep 3600
EOF_DEBUG
