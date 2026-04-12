#!/bin/bash
set -euo pipefail

NAMESPACE="netpol-lab"
FRONTEND_IMAGE="curlimages/curl:8.7.1"
SERVER_IMAGE="hashicorp/http-echo:1.0.0"

kubectl create namespace "$NAMESPACE" >/dev/null 2>&1 || true
kubectl delete networkpolicy --all -n "$NAMESPACE" >/dev/null 2>&1 || true
kubectl delete svc api db -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete pod frontend api db frontend-check api-check other-check -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true

cat <<EOF_FRONTEND | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: ${NAMESPACE}
  labels:
    app: frontend
spec:
  containers:
  - name: curl
    image: ${FRONTEND_IMAGE}
    command: ["sleep", "3600"]
EOF_FRONTEND

cat <<EOF_API | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: api
  namespace: ${NAMESPACE}
  labels:
    app: api
spec:
  containers:
  - name: api
    image: ${SERVER_IMAGE}
    args: ["-listen=:8080", "-text=api-ok"]
EOF_API

cat <<EOF_DB | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: db
  namespace: ${NAMESPACE}
  labels:
    app: db
spec:
  containers:
  - name: db
    image: ${SERVER_IMAGE}
    args: ["-listen=:5432", "-text=db-ok"]
EOF_DB

cat <<EOF_API_SVC | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: ${NAMESPACE}
spec:
  selector:
    app: api
  ports:
  - port: 8080
    targetPort: 8080
EOF_API_SVC

cat <<EOF_DB_SVC | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: ${NAMESPACE}
spec:
  selector:
    app: db
  ports:
  - port: 5432
    targetPort: 5432
EOF_DB_SVC

kubectl wait --for=condition=Ready pod/frontend -n "$NAMESPACE" --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod/api -n "$NAMESPACE" --timeout=180s >/dev/null
kubectl wait --for=condition=Ready pod/db -n "$NAMESPACE" --timeout=180s >/dev/null

exit 0
