#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="pv-reclaim-lab"

kubectl delete deployment reports-db -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pvc reports-data -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pv reports-pv --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

rm -rf /tmp/pv-reclaim-lab-data
mkdir -p /tmp/pv-reclaim-lab-data

cat <<'EOF_PV' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolume
metadata:
  name: reports-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual-reports
  hostPath:
    path: /tmp/pv-reclaim-lab-data
EOF_PV

cat <<'EOF_PVC' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: reports-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual-reports
  volumeName: reports-pv
EOF_PVC

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reports-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reports-db
  template:
    metadata:
      labels:
        app: reports-db
    spec:
      containers:
        - name: db
          image: busybox:1.36
          command:
            - sh
            - -c
            - echo reports-ready > /var/lib/reporting/ready.txt && sleep 3600
          volumeMounts:
            - name: data
              mountPath: /var/lib/legacy
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: reports-legacy
EOF_DEPLOYMENT
