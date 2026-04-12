#!/bin/bash
set -euo pipefail

NAMESPACE="cronjob-lab"
CONFIGMAP="cronjob-diagnostics-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetCronJob)" = "log-pruner" ] || { echo "targetCronJob must be log-pruner"; exit 1; }
[ "$(get_key cronJobInventory)" = "kubectl get cronjob log-pruner -n cronjob-lab -o wide" ] || { echo "cronJobInventory is incorrect"; exit 1; }
[ "$(get_key scheduleCheck)" = "kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.schedule}'" ] || { echo "scheduleCheck is incorrect"; exit 1; }
[ "$(get_key suspendCheck)" = "kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.suspend}'" ] || { echo "suspendCheck is incorrect"; exit 1; }
[ "$(get_key concurrencyPolicyCheck)" = "kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.concurrencyPolicy}'" ] || { echo "concurrencyPolicyCheck is incorrect"; exit 1; }
[ "$(get_key historyLimitsCheck)" = "kubectl get cronjob log-pruner -n cronjob-lab -o custom-columns=SUCCESS:.spec.successfulJobsHistoryLimit,FAILED:.spec.failedJobsHistoryLimit" ] || { echo "historyLimitsCheck is incorrect"; exit 1; }
[ "$(get_key jobTemplateCheck)" = "kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}'" ] || { echo "jobTemplateCheck is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm schedule, suspend=false, and history limits before changing the CronJob manifest" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "cronjob diagnostics brief contract is repaired"
