#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="init-lab"
OUTPUT_DIR="/tmp/exam/q1401"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: report-api
  template:
    metadata:
      labels:
        app: report-api
    spec:
      volumes:
        - name: bootstrap
          emptyDir: {}
      initContainers:
        - name: bootstrap-config
          image: busybox:1.36
          command:
            - sh
            - -c
            - echo ready > /work/status.txt
          volumeMounts:
            - name: bootstrap
              mountPath: /work
      containers:
        - name: api
          image: busybox:1.36
          command:
            - sh
            - -c
            - while true; do cat /work/status.txt >/dev/null 2>&1; sleep 30; done
          volumeMounts:
            - name: bootstrap
              mountPath: /work
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: init-diagnostics-brief
  namespace: init-lab
data:
  targetDeployment: report-worker
  deploymentInventory: kubectl get deployment report-api -n init-lab
  initContainerInventory: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[*].name}'
  initCommandCheck: kubectl describe deployment report-api -n init-lab
  sharedVolumeCheck: kubectl get pvc -n init-lab
  initMountCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].image}'
  appMountCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  eventCheck: kubectl get pods -n init-lab
  safeManifestNote: restart the deployment and patch the init command until the pod becomes ready
EOF_BRIEF

rm -f "${OUTPUT_DIR}/init-diagnostics-brief.yaml" "${OUTPUT_DIR}/init-diagnostics-checklist.txt"
