#!/usr/bin/env bash
set -euo pipefail

kubectl delete job log-pruner-smoke -n cronjob-lab --ignore-not-found >/dev/null 2>&1 || true
kubectl create job --from=cronjob/log-pruner log-pruner-smoke -n cronjob-lab >/dev/null
kubectl wait --for=condition=complete job/log-pruner-smoke -n cronjob-lab --timeout=180s >/dev/null || {
  echo "A smoke Job created from log-pruner must complete successfully"
  exit 1
}

echo "A smoke Job created from CronJob log-pruner completes successfully after the repair"
