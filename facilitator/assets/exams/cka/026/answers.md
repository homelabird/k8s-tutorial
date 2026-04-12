# CKA 2026 Single Domain Drill - StorageClass and dynamic provisioning diagnostics

## Question 1: StorageClass and dynamic provisioning diagnostics

Repair the dynamic provisioning brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: dynamic-provisioning-brief
  namespace: storageclass-lab
data:
  targetNamespace: storageclass-lab
  targetPVC: reports-pvc
  targetStorageClass: exam-standard
  storageClassInventory: kubectl get storageclass
  defaultClassCheck: kubectl get storageclass -o custom-columns=NAME:.metadata.name,DEFAULT:.metadata.annotations.storageclass\\.kubernetes\\.io/is-default-class
  pvcDescribe: kubectl describe pvc reports-pvc -n storageclass-lab
  workloadDescribe: kubectl describe pod reports-api -n storageclass-lab
  eventCheck: kubectl get events -n storageclass-lab --sort-by=.lastTimestamp
  recommendedManifestLine: 'storageClassName: exam-standard'
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/dynamic-provisioning-checklist.txt
StorageClass Inventory
- kubectl get storageclass
- kubectl get storageclass -o custom-columns=NAME:.metadata.name,DEFAULT:.metadata.annotations.storageclass\\.kubernetes\\.io/is-default-class

PVC Analysis
- kubectl describe pvc reports-pvc -n storageclass-lab
- kubectl describe pod reports-api -n storageclass-lab
- kubectl get events -n storageclass-lab --sort-by=.lastTimestamp

Safe Manifest Fix
- kubectl get pvc reports-pvc -n storageclass-lab -o yaml
- ensure the manifest contains storageClassName: exam-standard
EOF_CHECKLIST

kubectl get configmap dynamic-provisioning-brief -n storageclass-lab -o yaml > /tmp/exam/q1/dynamic-provisioning-brief.yaml
```

Expected checks:

- `dynamic-provisioning-brief` contains the intended namespace target, PVC target, StorageClass target, StorageClass inventory commands, PVC inspection commands, and safe manifest guidance
- `/tmp/exam/q1/dynamic-provisioning-checklist.txt` contains the required sections and exact storage troubleshooting commands
- `/tmp/exam/q1/dynamic-provisioning-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting StorageClass objects, patching provisioner fields, or deleting the PVC are removed
