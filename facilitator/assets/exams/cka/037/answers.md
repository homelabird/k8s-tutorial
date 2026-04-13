## Question 1: PriorityClass and preemption diagnostics

Repair the priority diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: priority-diagnostics-brief
  namespace: priority-lab
data:
  targetDeployment: batch-api
  targetPriorityClass: ops-critical
  priorityClassInventory: kubectl get priorityclass ops-critical -o yaml
  deploymentInventory: kubectl get deployment batch-api -n priority-lab -o wide
  priorityClassNameCheck: kubectl get deployment batch-api -n priority-lab -o jsonpath='{.spec.template.spec.priorityClassName}'
  priorityValueCheck: kubectl get priorityclass ops-critical -o jsonpath='{.value}'
  preemptionPolicyCheck: kubectl get priorityclass ops-critical -o jsonpath='{.preemptionPolicy}'
  globalDefaultCheck: kubectl get priorityclass ops-critical -o jsonpath='{.globalDefault}'
  schedulerCheck: kubectl get pods -n priority-lab -o wide
  eventCheck: kubectl get events -n priority-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm priorityClassName, priority value, preemption policy, and scheduler events before changing the Deployment manifest"
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/priority-diagnostics-checklist.txt
PriorityClass Inventory
- kubectl get priorityclass ops-critical -o yaml
- kubectl get priorityclass ops-critical -o jsonpath='{.value}'
- kubectl get priorityclass ops-critical -o jsonpath='{.preemptionPolicy}'
- kubectl get priorityclass ops-critical -o jsonpath='{.globalDefault}'

Workload Checks
- kubectl get deployment batch-api -n priority-lab -o wide
- kubectl get deployment batch-api -n priority-lab -o jsonpath='{.spec.template.spec.priorityClassName}'
- kubectl get pods -n priority-lab -o wide
- kubectl get events -n priority-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment batch-api -n priority-lab -o yaml
- confirm priorityClassName, priority value, preemption policy, and scheduler events before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap priority-diagnostics-brief -n priority-lab -o yaml > /tmp/exam/q1/priority-diagnostics-brief.yaml
```

Expected checks:

- `priority-diagnostics-brief` contains the intended Deployment target, exact PriorityClass inspection commands, scheduler evidence, events check, and safe manifest guidance
- `/tmp/exam/q1/priority-diagnostics-checklist.txt` contains the required sections and exact PriorityClass inventory and workload-priority troubleshooting commands
- `/tmp/exam/q1/priority-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live PriorityClass or Deployment fields are removed
