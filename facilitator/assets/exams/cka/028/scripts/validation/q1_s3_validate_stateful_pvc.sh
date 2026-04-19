#!/usr/bin/env bash
set -euo pipefail

for pvc in www-data-web-0 www-data-web-1; do
  phase="$(kubectl get pvc "${pvc}" -n stateful-lab -o jsonpath='{.status.phase}')"
  [ "${phase}" = "Bound" ] || { echo "${pvc} must remain Bound"; exit 1; }
done

echo "Both StatefulSet PVCs remain Bound after the network identity repair"
