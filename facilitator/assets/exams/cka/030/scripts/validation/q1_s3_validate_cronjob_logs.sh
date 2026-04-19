#!/usr/bin/env bash
set -euo pipefail

POD_NAME="$(kubectl get pods -n cronjob-lab -l job-name=log-pruner-smoke -o jsonpath='{.items[0].metadata.name}')"
[ -n "${POD_NAME}" ] || { echo "Smoke Job pod must exist"; exit 1; }

kubectl logs -n cronjob-lab "${POD_NAME}" | grep -Fx "prune" >/dev/null || {
  echo "Smoke Job must emit prune"
  exit 1
}

echo "The smoke Job emits the expected prune log line from the repaired CronJob template"
