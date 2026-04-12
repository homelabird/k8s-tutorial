#!/bin/bash
set -euo pipefail

NAMESPACE="storage-lab"
PV_NAME="app-data-pv"
PVC_NAME="app-data"
DEPLOYMENT="reporting-app"
HOST_PATH="/tmp/cka-2026-next5-app-data"

kubectl create namespace "$NAMESPACE" >/dev/null 2>&1 || true
kubectl delete deployment "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete pvc "$PVC_NAME" -n "$NAMESPACE" --ignore-not-found=true >/dev/null 2>&1 || true
kubectl delete pv "$PV_NAME" --ignore-not-found=true >/dev/null 2>&1 || true

cat <<EOF_PV | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${PV_NAME}
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: ${HOST_PATH}
    type: DirectoryOrCreate
EOF_PV

cat <<EOF_PVC | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
  namespace: ${NAMESPACE}
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: broken
EOF_PVC

cat <<EOF_DEPLOY | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOYMENT}
  namespace: ${NAMESPACE}
  labels:
    app: ${DEPLOYMENT}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${DEPLOYMENT}
  template:
    metadata:
      labels:
        app: ${DEPLOYMENT}
    spec:
      containers:
      - name: app
        image: busybox:1.36.1
        command: ["sh", "-c", "mkdir -p /data && echo storage-ok > /data/ready.txt && sleep 3600"]
        volumeMounts:
        - name: app-data
          mountPath: /data
      volumes:
      - name: app-data
        persistentVolumeClaim:
          claimName: ${PVC_NAME}
EOF_DEPLOY

exit 0
