#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="job-lab"

kubectl delete job report-batch -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF_JOB' | kubectl apply -f - >/dev/null
apiVersion: batch/v1
kind: Job
metadata:
  name: report-batch
  namespace: job-lab
spec:
  completions: 1
  parallelism: 0
  backoffLimit: 1
  suspend: true
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: worker
          image: busybox:1.36
          command:
            - sh
            - -c
            - echo batch-ready && exit 0
EOF_JOB
