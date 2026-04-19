#!/usr/bin/env bash
set -euo pipefail

DESIRED="$(kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.status.desiredNumberScheduled}')"
READY="$(kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.status.numberReady}')"
CURRENT="$(kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.status.currentNumberScheduled}')"

[ -n "${DESIRED}" ] && [ "${DESIRED}" -ge 1 ] || { echo "DaemonSet log-agent must target at least one node"; exit 1; }
[ "${READY}" = "${DESIRED}" ] || { echo "DaemonSet ready pods must match desired count"; exit 1; }
[ "${CURRENT}" = "${DESIRED}" ] || { echo "DaemonSet scheduled pods must match desired count"; exit 1; }

echo "Every desired DaemonSet pod is Running after the repair"
