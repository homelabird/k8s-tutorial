#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="pv-resize-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"
mkdir -p /tmp/pv-resize-lab-data

cat <<'EOF_STORAGECLASS' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable-reports
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF_STORAGECLASS

cat <<'EOF_PV' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: analytics-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: expandable-reports
  hostPath:
    path: /tmp/pv-resize-lab-data
EOF_PV

cat <<'EOF_PVC' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: analytics-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: expandable-reports
  volumeName: analytics-pv
EOF_PVC

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: analytics-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: analytics-api
  template:
    metadata:
      labels:
        app: analytics-api
    spec:
      containers:
        - name: api
          image: nginx:1.25.3
          volumeMounts:
            - name: data
              mountPath: /var/lib/analytics
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: analytics-data
EOF_DEPLOYMENT

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: resize-diagnostics-brief
  namespace: pv-resize-lab
data:
  targetPvc: edge-data
  pvcInventory: kubectl get pods -n pv-resize-lab
  requestedSizeCheck: kubectl edit pvc analytics-data -n pv-resize-lab
  currentCapacityCheck: kubectl delete pvc analytics-data -n pv-resize-lab
  storageClassCheck: kubectl get storageclass
  allowExpansionCheck: kubectl patch storageclass expandable-reports --type merge -p '{"allowVolumeExpansion":true}'
  conditionCheck: kubectl rollout restart deployment/analytics-api -n pv-resize-lab
  mountPathCheck: kubectl get deployment analytics-api -n pv-resize-lab
  eventCheck: kubectl get pvc analytics-data -n pv-resize-lab
  safeManifestNote: edit the pvc and restart the workload until the resize clears
EOF_BRIEF

rm -f "${OUTPUT_DIR}/resize-diagnostics-brief.yaml" "${OUTPUT_DIR}/resize-diagnostics-checklist.txt"
