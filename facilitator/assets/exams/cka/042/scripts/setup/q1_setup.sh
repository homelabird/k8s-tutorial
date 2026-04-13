#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="debug-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_POD' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: Pod
metadata:
  name: orders-api
  labels:
    app: orders-api
spec:
  containers:
    - name: api
      image: nginx:1.25.3
      command:
        - /bin/sh
        - -c
        - while true; do echo orders-api-ready; sleep 30; done
EOF_POD

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: debug-diagnostics-brief
  namespace: debug-lab
data:
  targetPod: edge-api
  podInventory: kubectl get pods -n debug-lab
  containerInventory: kubectl get deployment orders-api -n debug-lab
  logsCheck: kubectl exec -n debug-lab orders-api -- sh
  nodeCheck: kubectl delete pod orders-api -n debug-lab
  debugCommand: kubectl rollout restart deployment/orders-api -n debug-lab
  ephemeralContainerCheck: kubectl patch pod orders-api -n debug-lab --type merge -p '{"spec":{"ephemeralContainers":[]}}'
  eventCheck: kubectl get pod orders-api -n debug-lab
  safeManifestNote: delete the pod and restart the workload until debugging feels easier
EOF_BRIEF

rm -f "${OUTPUT_DIR}/debug-diagnostics-brief.yaml" "${OUTPUT_DIR}/debug-diagnostics-checklist.txt"
