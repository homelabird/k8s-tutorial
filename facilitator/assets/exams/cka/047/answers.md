# CKA 2026 Single Domain Drill 047 Answers

## Question 1

Repair `rwop-diagnostics-brief` in namespace `rwop-lab` so it documents the exact `ReadWriteOncePod` PVC wiring used by claim `data-claim` and pod `rwop-reader`, then export the repaired ConfigMap manifest and a plain-text checklist.

### Expected brief data

- `targetClaim: data-claim`
- `claimInventory: kubectl get pvc data-claim -n rwop-lab -o wide`
- `accessModeCheck: kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.accessModes[0]}'`
- `storageClassCheck: kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.storageClassName}'`
- `volumeNameCheck: kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.volumeName}'`
- `readerPodCheck: kubectl get pod rwop-reader -n rwop-lab -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}'`
- `mountPathCheck: kubectl get pod rwop-reader -n rwop-lab -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}'`
- `storageClassExpansionCheck: kubectl get storageclass rwop-hostpath -o jsonpath='{.allowVolumeExpansion}'`
- `eventCheck: kubectl get events -n rwop-lab --sort-by=.lastTimestamp`
- `safeManifestNote: confirm PVC access mode, claim consumer, and mount path before changing workload or storage manifests`
