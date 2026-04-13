## Question 1: Ephemeral containers and kubectl debug diagnostics

Repair the pod debug diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: debug-diagnostics-brief
  namespace: debug-lab
data:
  targetPod: orders-api
  podInventory: kubectl get pod orders-api -n debug-lab -o wide
  containerInventory: kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.containers[*].name}'
  logsCheck: kubectl logs orders-api -n debug-lab -c api --tail=50
  nodeCheck: kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.nodeName}'
  debugCommand: kubectl debug pod/orders-api -n debug-lab -it --image=busybox:1.36 --target=api
  ephemeralContainerCheck: kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[*].name}'
  eventCheck: kubectl get events -n debug-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm target pod, target container, debug image, and ephemeral container evidence before changing workload manifests
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/debug-diagnostics-checklist.txt
Pod Inventory
- kubectl get pod orders-api -n debug-lab -o wide
- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.containers[*].name}'
- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.nodeName}'

Debug Path
- kubectl logs orders-api -n debug-lab -c api --tail=50
- kubectl debug pod/orders-api -n debug-lab -it --image=busybox:1.36 --target=api
- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[*].name}'
- kubectl get events -n debug-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get pod orders-api -n debug-lab -o yaml
- confirm target pod, target container, debug image, and ephemeral container evidence before changing workload manifests
EOF_CHECKLIST

kubectl get configmap debug-diagnostics-brief -n debug-lab -o yaml > /tmp/exam/q1/debug-diagnostics-brief.yaml
```

Expected checks:

- `debug-diagnostics-brief` contains the intended pod target, exact inventory, logs, debug, and ephemeral-container inspection commands, event visibility, and safe manifest guidance
- `/tmp/exam/q1/debug-diagnostics-checklist.txt` contains the required sections and exact pod-debug troubleshooting commands
- `/tmp/exam/q1/debug-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting the Pod, restarting the workload, patching the live Pod spec, or replacing `kubectl debug` with ad hoc `kubectl exec` are removed
