#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="pv-resize-lab"

kubectl delete deployment analytics-api -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pvc analytics-data -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pv analytics-pv --ignore-not-found >/dev/null 2>&1 || true
kubectl delete storageclass expandable-reports --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

rm -rf /tmp/pv-resize-lab-data
mkdir -p /tmp/pv-resize-lab-data

cat <<'EOF_STORAGECLASS' | kubectl apply -f - >/dev/null
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: expandable-reports
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF_STORAGECLASS

cat <<'EOF_PV' | kubectl apply -f - >/dev/null
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

cat <<'EOF_PVC' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
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

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
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
          image: busybox:1.36
          command:
            - sh
            - -c
            - echo resize-ready > /var/lib/analytics/resize-ready.txt && sleep 3600
          volumeMounts:
            - name: data
              mountPath: /var/lib/legacy
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: analytics-legacy
EOF_DEPLOYMENT
