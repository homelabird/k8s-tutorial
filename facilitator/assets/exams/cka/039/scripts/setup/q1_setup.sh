#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="registry-auth-lab"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl delete deployment private-api -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete serviceaccount puller -n "${NAMESPACE}" --ignore-not-found >/dev/null
kubectl delete secret regcred -n "${NAMESPACE}" --ignore-not-found >/dev/null

cat <<'EOF_SECRET' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: Secret
metadata:
  name: regcred
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30=
EOF_SECRET

cat <<'EOF_SERVICEACCOUNT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: puller
imagePullSecrets:
  - name: regcred
EOF_SERVICEACCOUNT

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: private-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: private-api
  template:
    metadata:
      labels:
        app: private-api
    spec:
      serviceAccountName: missing-puller
      imagePullSecrets:
        - name: wrongcred
      containers:
        - name: api
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - sleep 3600
EOF_DEPLOYMENT
