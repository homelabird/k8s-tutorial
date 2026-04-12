## Question 1: CronJob schedule, suspend, and history diagnostics

Repair the CronJob diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cronjob-diagnostics-brief
  namespace: cronjob-lab
data:
  targetCronJob: log-pruner
  cronJobInventory: kubectl get cronjob log-pruner -n cronjob-lab -o wide
  scheduleCheck: kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.schedule}'
  suspendCheck: kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.suspend}'
  concurrencyPolicyCheck: kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.concurrencyPolicy}'
  historyLimitsCheck: kubectl get cronjob log-pruner -n cronjob-lab -o custom-columns=SUCCESS:.spec.successfulJobsHistoryLimit,FAILED:.spec.failedJobsHistoryLimit
  jobTemplateCheck: kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}'
  safeManifestNote: "confirm schedule, suspend=false, and history limits before changing the CronJob manifest"
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/cronjob-diagnostics-checklist.txt
CronJob Inventory
- kubectl get cronjob log-pruner -n cronjob-lab -o wide

Scheduling Checks
- kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.schedule}'
- kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.suspend}'
- kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.concurrencyPolicy}'
- kubectl get cronjob log-pruner -n cronjob-lab -o custom-columns=SUCCESS:.spec.successfulJobsHistoryLimit,FAILED:.spec.failedJobsHistoryLimit
- kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}'

Safe Manifest Review
- confirm schedule, suspend=false, and history limits before changing the CronJob manifest
EOF_CHECKLIST

kubectl get configmap cronjob-diagnostics-brief -n cronjob-lab -o yaml > /tmp/exam/q1/cronjob-diagnostics-brief.yaml
```

Expected checks:

- `cronjob-diagnostics-brief` contains the intended CronJob target, exact scheduling inspection commands, and safe manifest note
- `/tmp/exam/q1/cronjob-diagnostics-checklist.txt` contains the required sections and exact inventory, schedule, suspend, concurrency, history, and job template inspection steps
- `/tmp/exam/q1/cronjob-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting the CronJob, forcing a manual Job run, or patching the schedule are removed
