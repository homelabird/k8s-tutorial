## Question 1: Projected ConfigMap and Secret volume diagnostics

Repair the projected volume diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: projected-volume-brief
  namespace: projectedvolume-lab
data:
  targetDeployment: bundle-api
  deploymentInventory: kubectl get deployment bundle-api -n projectedvolume-lab -o wide
  configMapNameCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.name}'
  configMapItemPathCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.items[0].path}'
  secretNameCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.name}'
  secretItemPathCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.items[0].path}'
  mountPathCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  readOnlyCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'
  eventCheck: kubectl get events -n projectedvolume-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm projected sources, item paths, and readOnly mount before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/projected-volume-checklist.txt
Deployment Inventory
- kubectl get deployment bundle-api -n projectedvolume-lab -o wide
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.name}'

Projected Volume Checks
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.items[0].path}'
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.name}'
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.items[0].path}'
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'
- kubectl get events -n projectedvolume-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment bundle-api -n projectedvolume-lab -o yaml
- confirm projected sources, item paths, and readOnly mount before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap projected-volume-brief -n projectedvolume-lab -o yaml > /tmp/exam/q1/projected-volume-brief.yaml
```

Expected checks:

- `projected-volume-brief` contains the intended Deployment target, exact projected ConfigMap and Secret source inspection commands, event evidence, and safe manifest guidance
- `/tmp/exam/q1/projected-volume-checklist.txt` contains the required sections and exact projected-volume troubleshooting commands
- `/tmp/exam/q1/projected-volume-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live ConfigMap, Secret, or Deployment are removed
