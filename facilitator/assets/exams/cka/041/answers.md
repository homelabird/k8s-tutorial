## Question 1: PersistentVolumeClaim expansion and resize diagnostics

Repair the resize diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: resize-diagnostics-brief
  namespace: pv-resize-lab
data:
  targetPvc: analytics-data
  pvcInventory: kubectl get pvc analytics-data -n pv-resize-lab -o wide
  requestedSizeCheck: kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.resources.requests.storage}'
  currentCapacityCheck: kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.capacity.storage}'
  storageClassCheck: kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.storageClassName}'
  allowExpansionCheck: kubectl get storageclass expandable-reports -o jsonpath='{.allowVolumeExpansion}'
  conditionCheck: kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.conditions[*].type}'
  mountPathCheck: kubectl get deployment analytics-api -n pv-resize-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n pv-resize-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm requested size, current capacity, resize support, PVC conditions, and mount path before changing storage manifests
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/resize-diagnostics-checklist.txt
PVC Inventory
- kubectl get pvc analytics-data -n pv-resize-lab -o wide
- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.resources.requests.storage}'
- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.capacity.storage}'
- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.storageClassName}'

Resize Checks
- kubectl get storageclass expandable-reports -o jsonpath='{.allowVolumeExpansion}'
- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.conditions[*].type}'
- kubectl get deployment analytics-api -n pv-resize-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n pv-resize-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment analytics-api -n pv-resize-lab -o yaml
- kubectl get pvc analytics-data -n pv-resize-lab -o yaml
- confirm requested size, current capacity, resize support, PVC conditions, and mount path before changing storage manifests
EOF_CHECKLIST

kubectl get configmap resize-diagnostics-brief -n pv-resize-lab -o yaml > /tmp/exam/q1/resize-diagnostics-brief.yaml
```

Expected checks:

- `resize-diagnostics-brief` contains the intended PVC target, exact resize inspection commands, StorageClass expansion evidence, PVC condition checks, event visibility, and safe manifest guidance
- `/tmp/exam/q1/resize-diagnostics-checklist.txt` contains the required sections and exact resize troubleshooting commands
- `/tmp/exam/q1/resize-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as editing or deleting the PVC, restarting the workload, or patching the StorageClass are removed
