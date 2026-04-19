#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="cronjob-lab"

kubectl delete cronjob log-pruner -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl delete job log-pruner-smoke -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null

cat <<'EOF_CRONJOB' | kubectl apply -f - >/dev/null
apiVersion: batch/v1
kind: CronJob
metadata:
  name: log-pruner
  namespace: cronjob-lab
spec:
  schedule: '0 0 31 2 *'
  suspend: true
  concurrencyPolicy: Allow
  successfulJobsHistoryLimit: 0
  failedJobsHistoryLimit: 0
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: pruner
              image: busybox:1.36
              command:
                - sh
                - -c
                - echo prune && sleep 5
EOF_CRONJOB
