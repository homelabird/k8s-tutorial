#!/usr/bin/env bash
set -euo pipefail

SCHEDULE="$(kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.schedule}')"
SUSPEND="$(kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.suspend}')"
CONCURRENCY="$(kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.concurrencyPolicy}')"
SUCCESS_HISTORY="$(kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.successfulJobsHistoryLimit}')"
FAILED_HISTORY="$(kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.failedJobsHistoryLimit}')"
RESTART_POLICY="$(kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}')"

[ "${SCHEDULE}" = "*/15 * * * *" ] || { echo "log-pruner must use schedule */15 * * * *"; exit 1; }
[ "${SUSPEND}" = "false" ] || { echo "log-pruner must not be suspended"; exit 1; }
[ "${CONCURRENCY}" = "Forbid" ] || { echo "log-pruner must use concurrencyPolicy Forbid"; exit 1; }
[ "${SUCCESS_HISTORY}" = "3" ] || { echo "log-pruner must keep successfulJobsHistoryLimit 3"; exit 1; }
[ "${FAILED_HISTORY}" = "1" ] || { echo "log-pruner must keep failedJobsHistoryLimit 1"; exit 1; }
[ "${RESTART_POLICY}" = "OnFailure" ] || { echo "log-pruner must keep restartPolicy OnFailure"; exit 1; }

echo "CronJob log-pruner uses the intended schedule, suspend setting, concurrency policy, history limits, and restart policy"
