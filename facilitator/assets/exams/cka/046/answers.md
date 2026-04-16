# CKA 2026 Single Domain Drill 046 Answers

## Question 1

Repair `subpath-diagnostics-brief` in namespace `subpath-lab` so it documents the exact ConfigMap-backed `subPath` wiring used by deployment `subpath-api`, then export the repaired ConfigMap manifest and a plain-text checklist.

### Expected brief data

- `targetDeployment: subpath-api`
- `deploymentInventory: kubectl get deployment subpath-api -n subpath-lab -o wide`
- `configMapNameCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}'`
- `itemPathCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.volumes[0].configMap.items[0].path}'`
- `mountPathCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'`
- `subPathCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].subPath}'`
- `readOnlyCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'`
- `containerNameCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].name}'`
- `imageCheck: kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].image}'`
- `eventCheck: kubectl get events -n subpath-lab --sort-by=.lastTimestamp`
- `safeManifestNote: confirm ConfigMap item path, subPath, and target mount path before changing the Deployment manifest`

### Expected checklist sections

1. `Deployment Inventory`
2. `subPath Checks`
3. `Safe Manifest Review`

### Expected checklist commands

- `kubectl get deployment subpath-api -n subpath-lab -o wide`
- `kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].name}'`
- `kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}'`
- `kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.volumes[0].configMap.items[0].path}'`
- `kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'`
- `kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].subPath}'`
- `kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'`
- `kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].image}'`
- `kubectl get events -n subpath-lab --sort-by=.lastTimestamp`
- `kubectl get deployment subpath-api -n subpath-lab -o yaml`
- `confirm ConfigMap item path, subPath, and target mount path before changing the Deployment manifest`
