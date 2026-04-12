#!/bin/bash
set -euo pipefail

NAMESPACE="cronjob-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/cronjob-diagnostics-brief.yaml" "$OUTPUT_DIR/cronjob-diagnostics-checklist.txt"

cat <<'EOF_CRONJOB' | kubectl apply -f - >/dev/null
apiVersion: batch/v1
kind: CronJob
metadata:
  name: log-pruner
  namespace: cronjob-lab
spec:
  schedule: "*/15 * * * *"
  suspend: false
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: pruner
            image: busybox:1.36
            command: ["sh", "-c", "echo prune && sleep 5"]
EOF_CRONJOB

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: cronjob-diagnostics-brief
  namespace: cronjob-lab
data:
  targetCronJob: metrics-pruner
  cronJobInventory: kubectl get jobs -n cronjob-lab
  scheduleCheck: kubectl patch cronjob log-pruner -n cronjob-lab -p '{"spec":{"schedule":"* * * * *"}}'
  suspendCheck: kubectl create job --from=cronjob/log-pruner manual-pruner -n cronjob-lab
  concurrencyPolicyCheck: kubectl delete cronjob log-pruner -n cronjob-lab
  historyLimitsCheck: kubectl get cronjob log-pruner -n cronjob-lab -o yaml
  jobTemplateCheck: kubectl get deployment -n cronjob-lab
  safeManifestNote: convert the CronJob into a one-off Job and disable history pruning
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/cronjob-diagnostics-checklist.txt"
CronJob Inventory
- kubectl delete cronjob log-pruner -n cronjob-lab

Scheduling Checks
- kubectl create job --from=cronjob/log-pruner manual-pruner -n cronjob-lab
- kubectl patch cronjob log-pruner -n cronjob-lab -p '{"spec":{"schedule":"* * * * *"}}'

Safe Manifest Review
- convert the CronJob into a one-off Job and disable history pruning
EOF_STALE

exit 0
