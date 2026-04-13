## Question 2101: PersistentVolume reclaim policy and claimRef diagnostics

Repair the storage diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: reclaim-diagnostics-brief
  namespace: pv-reclaim-lab
data:
  targetPvc: reports-data
  pvcInventory: kubectl get pvc reports-data -n pv-reclaim-lab -o wide
  volumeNameCheck: kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.volumeName}'
  storageClassCheck: kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.storageClassName}'
  reclaimPolicyCheck: kubectl get pv reports-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
  claimRefCheck: kubectl get pv reports-pv -o jsonpath='{.spec.claimRef.namespace}/{.spec.claimRef.name}'
  mountPathCheck: kubectl get deployment reports-db -n pv-reclaim-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n pv-reclaim-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm PVC binding, PV reclaim policy, claimRef, and workload mount path before changing storage manifests
EOF_BRIEF

mkdir -p /tmp/exam/q2101
cat <<'EOF_CHECKLIST' > /tmp/exam/q2101/reclaim-diagnostics-checklist.txt
PVC Inventory
- kubectl get pvc reports-data -n pv-reclaim-lab -o wide
- kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.volumeName}'
- kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.storageClassName}'

PV Checks
- kubectl get pv reports-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
- kubectl get pv reports-pv -o jsonpath='{.spec.claimRef.namespace}/{.spec.claimRef.name}'
- kubectl get deployment reports-db -n pv-reclaim-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n pv-reclaim-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment reports-db -n pv-reclaim-lab -o yaml
- kubectl get pv reports-pv -o yaml
- confirm PVC binding, PV reclaim policy, claimRef, and workload mount path before changing storage manifests
EOF_CHECKLIST

kubectl get configmap reclaim-diagnostics-brief -n pv-reclaim-lab -o yaml > /tmp/exam/q2101/reclaim-diagnostics-brief.yaml
```

Expected checks:

- `reclaim-diagnostics-brief` contains the intended PVC target, exact PVC and PV inspection commands, claimRef evidence, event visibility, and safe manifest guidance
- `/tmp/exam/q2101/reclaim-diagnostics-checklist.txt` contains the required sections and exact PVC inventory and PV troubleshooting commands
- `/tmp/exam/q2101/reclaim-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting the PVC or PV, scaling the Deployment, or patching live PV fields are removed
