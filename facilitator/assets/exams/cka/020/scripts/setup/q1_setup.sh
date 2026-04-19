#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="connectivity-lab"

kubectl delete pod net-debug -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete statefulset echo-api -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete service echo-api -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete service echo-api-headless -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF_HEADLESS' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Service
metadata:
  name: echo-api-headless
  namespace: connectivity-lab
spec:
  clusterIP: None
  selector:
    app: legacy-api
  ports:
    - port: 8080
      targetPort: 8080
EOF_HEADLESS

cat <<'EOF_SERVICE' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Service
metadata:
  name: echo-api
  namespace: connectivity-lab
spec:
  selector:
    app: echo-api
  ports:
    - port: 8080
      targetPort: 9090
EOF_SERVICE

cat <<'EOF_STS' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: echo-api
  namespace: connectivity-lab
spec:
  serviceName: echo-api-headless
  replicas: 1
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
EOF_STS

cat <<'EOF_DEBUG' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: net-debug
  namespace: connectivity-lab
spec:
  containers:
    - name: net-debug
      image: busybox:1.36
      command:
        - sh
        - -c
        - sleep 3600
EOF_DEBUG
