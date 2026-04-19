#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="probe-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment health-api -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health-api
  template:
    metadata:
      labels:
        app: health-api
    spec:
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - mkdir -p /www && echo ok > /www/healthz && echo probe > /www/index.html && httpd -f -p 8080 -h /www
          ports:
            - containerPort: 8080
          startupProbe:
            httpGet:
              path: /startupz
              port: 8080
            periodSeconds: 2
            failureThreshold: 15
          livenessProbe:
            httpGet:
              path: /livez
              port: 8080
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8080
            periodSeconds: 5
EOF_DEPLOYMENT
