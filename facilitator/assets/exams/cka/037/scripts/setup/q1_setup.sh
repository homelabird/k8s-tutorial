#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="priority-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_PRIORITYCLASS' | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: ops-critical
value: 100000
preemptionPolicy: PreemptLowerPriority
globalDefault: false
description: High-priority batch workload diagnostics class
EOF_PRIORITYCLASS

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: batch-api
  template:
    metadata:
      labels:
        app: batch-api
    spec:
      priorityClassName: ops-critical
      containers:
        - name: api
          image: nginx:1.25.3
          ports:
            - containerPort: 80
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: priority-diagnostics-brief
  namespace: priority-lab
data:
  targetDeployment: edge-batch
  targetPriorityClass: default-priority
  priorityClassInventory: kubectl get priorityclass
  deploymentInventory: kubectl get pods -n priority-lab
  priorityClassNameCheck: kubectl patch deployment batch-api -n priority-lab --type merge -p '{"spec":{"template":{"spec":{"priorityClassName":"ops-critical"}}}}'
  priorityValueCheck: kubectl patch priorityclass ops-critical --type merge -p '{"value":100000}'
  preemptionPolicyCheck: kubectl delete pod -n priority-lab -l app=batch-api
  globalDefaultCheck: kubectl rollout restart deployment/batch-api -n priority-lab
  schedulerCheck: kubectl get deployment batch-api -n priority-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  eventCheck: kubectl get pods -n priority-lab
  safeManifestNote: restart the deployment and patch the PriorityClass until the workload looks scheduled
EOF_BRIEF

rm -f "${OUTPUT_DIR}/priority-diagnostics-brief.yaml" "${OUTPUT_DIR}/priority-diagnostics-checklist.txt"
