#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="rwop-lab"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl wait --for=delete "namespace/${NAMESPACE}" --timeout=120s >/dev/null 2>&1 || true
kubectl delete pv rwop-pv --ignore-not-found >/dev/null 2>&1 || true
kubectl delete storageclass rwop-hostpath --ignore-not-found >/dev/null 2>&1 || true

kubectl create namespace "${NAMESPACE}" >/dev/null

cat <<'EOF_SC' | kubectl apply -f - >/dev/null
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rwop-hostpath
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF_SC

cat <<'EOF_PV' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolume
metadata:
  name: rwop-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOncePod
  persistentVolumeReclaimPolicy: Retain
  storageClassName: rwop-hostpath
  hostPath:
    path: /tmp/rwop-data
    type: DirectoryOrCreate
EOF_PV

cat <<'EOF_PVC' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-claim
spec:
  storageClassName: rwop-hostpath
  volumeName: rwop-pv
  accessModes:
    - ReadWriteOncePod
  resources:
    requests:
      storage: 1Gi
EOF_PVC

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/data-claim -n "${NAMESPACE}" --timeout=120s >/dev/null

cat <<'EOF_DEPLOYMENT' | kubectl apply -n "${NAMESPACE}" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rwop-reader
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rwop-reader
  template:
    metadata:
      labels:
        app: rwop-reader
    spec:
      containers:
        - name: reader
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - echo reader-ready > /data/app/reader.txt && sleep 3600
          volumeMounts:
            - name: data
              mountPath: /var/data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: wrong-claim
EOF_DEPLOYMENT
