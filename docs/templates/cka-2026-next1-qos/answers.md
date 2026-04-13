## Question 1901: Pod resource requests, limits, and QoS diagnostics

Repair the resource diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: qos-diagnostics-brief
  namespace: qos-lab
data:
  targetDeployment: reporting-api
  deploymentInventory: kubectl get deployment reporting-api -n qos-lab -o wide
  requestsCpuCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}'
  requestsMemoryCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}'
  limitsCpuCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}'
  limitsMemoryCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}'
  qosClassCheck: kubectl get pods -n qos-lab -l app=reporting-api -o jsonpath='{.items[0].status.qosClass}'
  eventCheck: kubectl get events -n qos-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm requests, limits, QoS class, and namespace events before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q1901
cat <<'EOF_CHECKLIST' > /tmp/exam/q1901/qos-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment reporting-api -n qos-lab -o wide

Resource Checks
- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}'
- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}'
- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}'
- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}'
- kubectl get pods -n qos-lab -l app=reporting-api -o jsonpath='{.items[0].status.qosClass}'
- kubectl get events -n qos-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment reporting-api -n qos-lab -o yaml
- confirm requests, limits, QoS class, and namespace events before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap qos-diagnostics-brief -n qos-lab -o yaml > /tmp/exam/q1901/qos-diagnostics-brief.yaml
```

Expected checks:

- `qos-diagnostics-brief` contains the intended Deployment target, exact resource inspection commands, QoS evidence, events check, and safe manifest guidance
- `/tmp/exam/q1901/qos-diagnostics-checklist.txt` contains the required sections and exact deployment inventory and QoS troubleshooting commands
- `/tmp/exam/q1901/qos-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live resource requests and limits are removed
