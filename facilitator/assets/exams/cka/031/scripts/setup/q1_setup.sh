#!/bin/bash
set -euo pipefail

NAMESPACE="job-lab"
OUTPUT_DIR="/tmp/exam/q1"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/job-diagnostics-brief.yaml" "$OUTPUT_DIR/job-diagnostics-checklist.txt"

cat <<'EOF_JOB' | kubectl apply -f - >/dev/null
apiVersion: batch/v1
kind: Job
metadata:
  name: report-batch
  namespace: job-lab
spec:
  completions: 3
  parallelism: 2
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh", "-c", "echo batch && sleep 600"]
EOF_JOB

cat <<'EOF_BRIEF' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: job-diagnostics-brief
  namespace: job-lab
data:
  targetJob: nightly-batch
  jobInventory: kubectl get jobs -n job-lab
  completionsCheck: kubectl delete job report-batch -n job-lab
  parallelismCheck: kubectl create job report-batch-copy --image=busybox:1.36 -n job-lab
  backoffLimitCheck: kubectl replace --force -f report-batch.yaml
  podEvidenceCheck: kubectl delete pod -n job-lab -l job-name=report-batch
  jobDescribeCheck: kubectl get deployment -n job-lab
  safeManifestNote: rerun the batch from scratch and ignore the existing Job manifest
EOF_BRIEF

cat <<'EOF_STALE' > "$OUTPUT_DIR/job-diagnostics-checklist.txt"
Job Inventory
- kubectl delete job report-batch -n job-lab

Pod Evidence
- kubectl delete pod -n job-lab -l job-name=report-batch
- kubectl create job report-batch-copy --image=busybox:1.36 -n job-lab

Safe Manifest Review
- rerun the batch from scratch and ignore the existing Job manifest
EOF_STALE

exit 0
