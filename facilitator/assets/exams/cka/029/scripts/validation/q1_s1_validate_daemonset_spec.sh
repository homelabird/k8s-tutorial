#!/usr/bin/env bash
set -euo pipefail

NODE_SELECTOR="$(kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.spec.template.spec.nodeSelector.kubernetes\.io/os}')"
UPDATE_STRATEGY="$(kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.spec.updateStrategy.type}')"

[ "${NODE_SELECTOR}" = "linux" ] || { echo "log-agent must target Linux nodes"; exit 1; }
[ "${UPDATE_STRATEGY}" = "RollingUpdate" ] || { echo "log-agent must keep RollingUpdate strategy"; exit 1; }

echo "DaemonSet log-agent uses the intended Linux node selector and RollingUpdate strategy"
