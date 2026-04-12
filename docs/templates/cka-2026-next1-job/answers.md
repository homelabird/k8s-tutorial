## Question 1201: Job completions, parallelism, and backoff diagnostics

Repair the Job diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: job-diagnostics-brief
  namespace: job-lab
data:
  targetJob: report-batch
  jobInventory: kubectl get job report-batch -n job-lab -o wide
  completionsCheck: kubectl get job report-batch -n job-lab -o jsonpath='{.spec.completions}'
  parallelismCheck: kubectl get job report-batch -n job-lab -o jsonpath='{.spec.parallelism}'
  backoffLimitCheck: kubectl get job report-batch -n job-lab -o jsonpath='{.spec.backoffLimit}'
  podEvidenceCheck: kubectl get pods -n job-lab -l job-name=report-batch -o wide
  jobDescribeCheck: kubectl describe job report-batch -n job-lab
  safeManifestNote: confirm completions, parallelism, backoffLimit, and pod template command before changing the Job manifest
EOF_BRIEF

mkdir -p /tmp/exam/q1201
cat <<'EOF_CHECKLIST' > /tmp/exam/q1201/job-diagnostics-checklist.txt
Job Inventory
- kubectl get job report-batch -n job-lab -o wide
- kubectl get job report-batch -n job-lab -o jsonpath='{.spec.completions}'
- kubectl get job report-batch -n job-lab -o jsonpath='{.spec.parallelism}'
- kubectl get job report-batch -n job-lab -o jsonpath='{.spec.backoffLimit}'

Pod Evidence
- kubectl get pods -n job-lab -l job-name=report-batch -o wide
- kubectl describe job report-batch -n job-lab

Safe Manifest Review
- kubectl get job report-batch -n job-lab -o yaml
- confirm completions, parallelism, backoffLimit, and pod template command before changing the Job manifest
EOF_CHECKLIST

kubectl get configmap job-diagnostics-brief -n job-lab -o yaml > /tmp/exam/q1201/job-diagnostics-brief.yaml
```

Expected checks:

- `job-diagnostics-brief` contains the intended Job target, inventory commands, completions/parallelism/backoff checks, pod evidence, and safe manifest guidance
- `/tmp/exam/q1201/job-diagnostics-checklist.txt` contains the required sections and exact job troubleshooting commands
- `/tmp/exam/q1201/job-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting the Job, replacing it with a new Job, deleting pods as remediation, or patching status are removed
