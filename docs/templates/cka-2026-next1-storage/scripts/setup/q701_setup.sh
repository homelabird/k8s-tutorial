#!/bin/bash
set -euo pipefail

NAMESPACE="storageclass-lab"
CONFIGMAP="dynamic-provisioning-brief"
OUTPUT_DIR="/tmp/exam/q701"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/dynamic-provisioning-brief.yaml" "$OUTPUT_DIR/dynamic-provisioning-checklist.txt"

cat <<'EOF_STANDARD' | kubectl apply -f - >/dev/null
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: exam-standard
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF_STANDARD

cat <<'EOF_ARCHIVE' | kubectl apply -f - >/dev/null
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: exam-archive
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF_ARCHIVE

cat <<'EOF_PVC' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: reports-pvc
  namespace: storageclass-lab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: exam-archive
EOF_PVC

cat <<'EOF_POD' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: reports-api
  namespace: storageclass-lab
  labels:
    app: reports-api
spec:
  containers:
    - name: api
      image: nginx:1.25.3
      volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: reports-pvc
EOF_POD

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: dynamic-provisioning-brief
  namespace: storageclass-lab
data:
  targetNamespace: default
  targetPVC: cache-pvc
  targetStorageClass: exam-archive
  storageClassInventory: kubectl get pv
  defaultClassCheck: kubectl get storageclass exam-standard
  pvcDescribe: kubectl delete pvc reports-pvc -n storageclass-lab
  workloadDescribe: kubectl get pod -A
  eventCheck: kubectl delete storageclass exam-archive
  recommendedManifestLine: 'storageClassName: ""'
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/dynamic-provisioning-checklist.txt"
StorageClass Inventory
- kubectl delete storageclass exam-archive

PVC Analysis
- kubectl delete pvc reports-pvc -n storageclass-lab

Safe Manifest Fix
- kubectl patch storageclass exam-standard -p '{"provisioner":"broken.example.io"}'
EOF_STALE

exit 0
