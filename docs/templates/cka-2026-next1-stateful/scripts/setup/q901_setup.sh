#!/bin/bash
set -euo pipefail

NAMESPACE="stateful-lab"
OUTPUT_DIR="/tmp/exam/q901"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/stateful-identity-brief.yaml" "$OUTPUT_DIR/stateful-identity-checklist.txt"

cat <<'EOF_SVC' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: stateful-lab
spec:
  clusterIP: None
  selector:
    app: web
  ports:
    - name: http
      port: 80
      targetPort: 80
EOF_SVC

cat <<'EOF_STS' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: stateful-lab
spec:
  serviceName: web-svc
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.25.3
          ports:
            - containerPort: 80
  volumeClaimTemplates:
    - metadata:
        name: www-data
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF_STS

cat <<'EOF_DNS' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: dns-debug
  namespace: stateful-lab
spec:
  containers:
    - name: dns-debug
      image: busybox:1.36
      command: ['sh', '-c', 'sleep 3600']
EOF_DNS

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: stateful-identity-brief
  namespace: stateful-lab
data:
  targetStatefulSet: cache
  headlessService: legacy-svc
  statefulSetInventory: kubectl get deployment -n stateful-lab
  serviceInspection: kubectl patch svc web-svc -n stateful-lab -p '{"spec":{"type":"NodePort"}}'
  podInventory: kubectl get pods -A
  ordinalDnsCheck: kubectl exec -n stateful-lab dns-debug -- nslookup api.default.svc.cluster.local
  pvcInventory: kubectl delete pvc -n stateful-lab --all
  safeManifestNote: delete the StatefulSet and recreate it with a normal ClusterIP Service
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/stateful-identity-checklist.txt"
StatefulSet Inventory
- kubectl delete statefulset web -n stateful-lab

Stable Network Identity
- kubectl patch svc web-svc -n stateful-lab -p '{"spec":{"type":"NodePort"}}'

Safe Manifest Review
- kubectl delete pvc -n stateful-lab --all
EOF_STALE

exit 0
