#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="rwop-lab"
OUTPUT_DIR="/tmp/exam/q2801"

kubectl delete namespace "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" >/dev/null
mkdir -p "${OUTPUT_DIR}"

cat <<'EOF_SC' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rwop-hostpath
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF_SC

cat <<'EOF_PV' | kubectl apply -f -
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
EOF_PV

cat <<'EOF_PVC' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-claim
spec:
  storageClassName: rwop-hostpath
  accessModes:
    - ReadWriteOncePod
  resources:
    requests:
      storage: 1Gi
EOF_PVC

cat <<'EOF_POD' | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: v1
kind: Pod
metadata:
  name: rwop-reader
spec:
  restartPolicy: Never
  containers:
    - name: reader
      image: nginx:1.25.3
      command: ["/bin/sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data/app
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: data-claim
EOF_POD

cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: rwop-diagnostics-brief
  namespace: rwop-lab
data:
  targetClaim: wrong-claim
  claimInventory: kubectl get pods -n rwop-lab
  accessModeCheck: kubectl patch pvc data-claim -n rwop-lab --type merge -p '{"spec":{"accessModes":["ReadWriteOnce"]}}'
  storageClassCheck: kubectl delete pvc data-claim -n rwop-lab
  volumeNameCheck: kubectl get pod rwop-reader -n rwop-lab -o jsonpath='{.spec.containers[0].image}'
  readerPodCheck: kubectl edit pod rwop-reader -n rwop-lab
  mountPathCheck: kubectl delete pod -n rwop-lab -l app=rwop-reader
  storageClassExpansionCheck: kubectl get pvc data-claim -n rwop-lab -o yaml
  eventCheck: kubectl get configmap -n rwop-lab
  safeManifestNote: delete the claim and patch the pod until the PVC mounts correctly
EOF_BRIEF

rm -f "${OUTPUT_DIR}/rwop-diagnostics-brief.yaml" "${OUTPUT_DIR}/rwop-diagnostics-checklist.txt"
