#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="identity-lab"
OUTPUT_DIR="/tmp/exam/q1601"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_SERVICEACCOUNT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-reader
EOF_SERVICEACCOUNT

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metrics-api
  template:
    metadata:
      labels:
        app: metrics-api
    spec:
      serviceAccountName: metrics-reader
      automountServiceAccountToken: false
      volumes:
        - name: identity-token
          projected:
            sources:
              - serviceAccountToken:
                  path: identity-token
                  audience: metrics-api
      containers:
        - name: api
          image: nginx:1.25.3
          volumeMounts:
            - name: identity-token
              mountPath: /var/run/identity
              readOnly: true
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: identity-diagnostics-brief
  namespace: identity-lab
data:
  targetDeployment: metrics-worker
  deploymentInventory: kubectl get pods -n identity-lab
  serviceAccountCheck: kubectl get serviceaccount -n identity-lab
  automountCheck: kubectl patch deployment metrics-api -n identity-lab --type merge -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":true}}}}'
  projectedTokenPathCheck: kubectl rollout restart deployment/metrics-api -n identity-lab
  projectedAudienceCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  mountPathCheck: kubectl delete pod -n identity-lab -l app=metrics-api
  eventCheck: kubectl get pods -n identity-lab
  safeManifestNote: restart the deployment and patch service account settings until the token mount looks correct
EOF_BRIEF

rm -f "${OUTPUT_DIR}/identity-diagnostics-brief.yaml" "${OUTPUT_DIR}/identity-diagnostics-checklist.txt"
