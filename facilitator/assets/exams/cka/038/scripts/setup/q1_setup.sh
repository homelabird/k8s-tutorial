#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="qos-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporting-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reporting-api
  template:
    metadata:
      labels:
        app: reporting-api
    spec:
      containers:
        - name: api
          image: nginx:1.25.3
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 100m
              memory: 128Mi
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: qos-diagnostics-brief
  namespace: qos-lab
data:
  targetDeployment: edge-api
  deploymentInventory: kubectl get pods -n qos-lab
  requestsCpuCheck: kubectl set resources deployment reporting-api -n qos-lab --requests=cpu=100m,memory=128Mi
  requestsMemoryCheck: kubectl rollout restart deployment/reporting-api -n qos-lab
  limitsCpuCheck: kubectl patch deployment reporting-api -n qos-lab --type merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","resources":{"limits":{"cpu":"100m"}}}]}}}}'
  limitsMemoryCheck: kubectl delete pod -n qos-lab -l app=reporting-api
  qosClassCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  eventCheck: kubectl get pods -n qos-lab
  safeManifestNote: restart the deployment and patch resources until the pod qos class looks right
EOF_BRIEF

rm -f "${OUTPUT_DIR}/qos-diagnostics-brief.yaml" "${OUTPUT_DIR}/qos-diagnostics-checklist.txt"
