## Question 1401: InitContainer and shared volume diagnostics

Repair the init container diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: init-diagnostics-brief
  namespace: init-lab
data:
  targetDeployment: report-api
  deploymentInventory: kubectl get deployment report-api -n init-lab -o wide
  initContainerInventory: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[*].name}'
  initCommandCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].command}'
  sharedVolumeCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.volumes[0].name}'
  initMountCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}'
  appMountCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n init-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm init container command, shared volume name, and mount paths before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q1401
cat <<'EOF_CHECKLIST' > /tmp/exam/q1401/init-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment report-api -n init-lab -o wide
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[*].name}'

Init Container Checks
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].command}'
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.volumes[0].name}'
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}'
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n init-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment report-api -n init-lab -o yaml
- confirm init container command, shared volume name, and mount paths before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap init-diagnostics-brief -n init-lab -o yaml > /tmp/exam/q1401/init-diagnostics-brief.yaml
```

Expected checks:

- `init-diagnostics-brief` contains the intended Deployment target, exact init container inspection commands, events check, and safe manifest guidance
- `/tmp/exam/q1401/init-diagnostics-checklist.txt` contains the required sections and exact deployment inventory and init container troubleshooting commands
- `/tmp/exam/q1401/init-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live init container command are removed
