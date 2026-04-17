#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="lifecycle-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "$NAMESPACE" delete deployment lifecycle-api --ignore-not-found >/dev/null
kubectl -n "$NAMESPACE" delete configmap lifecycle-diagnostics-brief --ignore-not-found >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "$NAMESPACE" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lifecycle-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lifecycle-api
  template:
    metadata:
      labels:
        app: lifecycle-api
    spec:
      terminationGracePeriodSeconds: 30
      containers:
        - name: api
          image: nginx:1.25.3
          command: ["/bin/sh", "-c", "sleep 3600"]
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 5"]
EOF_DEPLOYMENT

kubectl rollout status deployment/lifecycle-api -n "$NAMESPACE" --timeout=120s >/dev/null

cat <<'EOF_CM' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: lifecycle-diagnostics-brief
  namespace: lifecycle-lab
data:
  targetDeployment: lifecycle-worker
  deploymentInventory: kubectl get pods -n lifecycle-lab
  terminationGraceCheck: kubectl rollout restart deployment lifecycle-api -n lifecycle-lab
  preStopTypeCheck: kubectl edit deployment lifecycle-api -n lifecycle-lab
  preStopCommandCheck: kubectl delete pod -n lifecycle-lab -l app=lifecycle-api
  containerCommandCheck: kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].name}'
  imageCheck: kubectl patch deployment lifecycle-api -n lifecycle-lab --type merge -p '{}'
  eventCheck: kubectl get configmap -n lifecycle-lab
  safeManifestNote: force-delete pods and patch the deployment until lifecycle hooks look right
EOF_CM

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/lifecycle-diagnostics-brief.yaml" "$OUTPUT_DIR/lifecycle-diagnostics-checklist.txt"
