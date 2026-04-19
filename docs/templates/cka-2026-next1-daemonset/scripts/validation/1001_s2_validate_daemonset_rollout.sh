#!/usr/bin/env bash
set -euo pipefail

kubectl rollout status daemonset/log-agent -n daemonset-lab --timeout=180s >/dev/null || {
  echo "DaemonSet log-agent must become Ready"
  exit 1
}

echo "DaemonSet log-agent becomes Ready after the Linux node coverage repair"
