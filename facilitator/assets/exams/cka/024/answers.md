# CKA 2026 Single Domain Drill - Resource quota and LimitRange troubleshooting

## Question 1: resource quota and LimitRange troubleshooting

Repair the resource guardrails brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: resource-guardrails-brief
  namespace: quota-lab
data:
  targetNamespace: quota-lab
  quotaInspection: kubectl get resourcequota -n quota-lab
  quotaDescribe: kubectl describe resourcequota compute-quota -n quota-lab
  limitRangeInspection: kubectl describe limitrange default-limits -n quota-lab
  workloadInspection: kubectl describe deployment api -n quota-lab
  recommendedPatch: kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/resource-quota-checklist.txt
Quota Inspection
- kubectl get resourcequota -n quota-lab
- kubectl describe resourcequota compute-quota -n quota-lab

LimitRange Inspection
- kubectl describe limitrange default-limits -n quota-lab
- kubectl get limitrange default-limits -n quota-lab -o yaml

Workload Sizing Guidance
- kubectl describe deployment api -n quota-lab
- kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi
EOF_CHECKLIST

kubectl get configmap resource-guardrails-brief -n quota-lab -o yaml > /tmp/exam/q1/resource-guardrails-brief.yaml
```

Expected checks:

- `resource-guardrails-brief` contains the intended namespace target, quota inspection commands, LimitRange inspection, workload review, and safe resource patch guidance
- `/tmp/exam/q1/resource-quota-checklist.txt` contains the required sections and exact troubleshooting commands
- `/tmp/exam/q1/resource-guardrails-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting ResourceQuota or LimitRange objects, scaling workloads to zero, or removing requests/limits are removed
