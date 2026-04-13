#!/bin/bash
set -euo pipefail

NAMESPACE="affinity-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/placement-diagnostics-brief.yaml" "$OUTPUT_DIR/placement-diagnostics-checklist.txt"

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "$NAMESPACE" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-fleet
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-fleet
  template:
    metadata:
      labels:
        app: api-fleet
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: api-fleet
            topologyKey: kubernetes.io/hostname
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: api-fleet
      containers:
      - name: api
        image: nginx:1.25.3
        ports:
        - containerPort: 80
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: placement-diagnostics-brief
  namespace: affinity-lab
data:
  targetDeployment: edge-fleet
  deploymentInventory: kubectl get pods -n affinity-lab
  replicaCheck: kubectl scale deployment api-fleet -n affinity-lab --replicas=1
  antiAffinityTopologyCheck: kubectl rollout restart deployment/api-fleet -n affinity-lab
  antiAffinitySelectorCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.nodeSelector}'
  topologySpreadKeyCheck: kubectl get nodes -o wide
  maxSkewCheck: kubectl patch deployment api-fleet -n affinity-lab --type merge -p '{"spec":{"replicas":1}}'
  whenUnsatisfiableCheck: kubectl delete pod -n affinity-lab -l app=api-fleet
  eventCheck: kubectl get pods -n affinity-lab
  safeManifestNote: restart the deployment, scale replicas down, and patch placement rules until the pods settle
EOF_BRIEF
