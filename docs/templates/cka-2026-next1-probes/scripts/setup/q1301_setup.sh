#!/bin/bash
set -euo pipefail

NAMESPACE="probe-lab"
OUTPUT_DIR="/tmp/exam/q1301"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/probe-diagnostics-brief.yaml" "$OUTPUT_DIR/probe-diagnostics-checklist.txt"

cat <<'EOF_DEPLOY' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-api
  namespace: probe-lab
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
        image: nginx:1.25.3
        ports:
        - containerPort: 80
        startupProbe:
          httpGet:
            path: /
            port: 80
          failureThreshold: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          periodSeconds: 5
EOF_DEPLOY

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-diagnostics-brief
  namespace: probe-lab
data:
  targetDeployment: api-v2
  deploymentInventory: kubectl get pods -n probe-lab
  startupProbeCheck: kubectl rollout restart deployment/health-api -n probe-lab
  livenessProbeCheck: kubectl patch deployment health-api -n probe-lab --type merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","livenessProbe":{"httpGet":{"path":"/healthz","port":8080}}}]}}}}'
  readinessProbeCheck: kubectl delete pod -n probe-lab -l app=health-api
  portCheck: kubectl get service health-api -n probe-lab -o wide
  eventCheck: kubectl get events -A
  safeManifestNote: restart the Deployment until the probes look healthy enough
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/probe-diagnostics-checklist.txt"
Deployment Inventory
- kubectl rollout restart deployment/health-api -n probe-lab

Probe Checks
- kubectl patch deployment health-api -n probe-lab --type merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","livenessProbe":{"httpGet":{"path":"/healthz","port":8080}}}]}}}}'
- kubectl delete pod -n probe-lab -l app=health-api

Safe Manifest Review
- restart the Deployment until the probes look healthy enough
EOF_STALE

exit 0
