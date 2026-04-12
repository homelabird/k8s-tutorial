#!/bin/bash
set -euo pipefail

NAMESPACE="disruption-lab"
CONFIGMAP="disruption-planning-brief"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/disruption-planning-brief.yaml" "$OUTPUT_DIR/disruption-planning-checklist.txt"

cat <<'EOF_DEPLOY' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: disruption-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: nginx:1.25.3
          ports:
            - containerPort: 80
EOF_DEPLOY

cat <<'EOF_PDB' | kubectl apply -f - >/dev/null
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
  namespace: disruption-lab
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: api
EOF_PDB

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: disruption-planning-brief
  namespace: disruption-lab
data:
  targetNode: kind-cluster-control-plane
  pdbInventory: kubectl delete pdb -A
  pdbDescribe: kubectl get pdb
  nodeWorkloadCheck: kubectl get nodes
  cordonCommand: kubectl delete node kind-cluster-worker
  drainPreview: kubectl drain kind-cluster-worker --force --ignore-daemonsets --delete-emptydir-data
  uncordonCommand: kubectl rollout restart deployment api -n disruption-lab
  safeRemediationNote: delete the PodDisruptionBudget if eviction is blocked
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/disruption-planning-checklist.txt"
PDB Inventory
- kubectl delete pdb api-pdb -n disruption-lab

Node Workload Audit
- kubectl get nodes

Safe Drain Sequence
- kubectl drain kind-cluster-worker --force --ignore-daemonsets --delete-emptydir-data
- kubectl delete pod -n disruption-lab -l app=api
EOF_STALE

exit 0
