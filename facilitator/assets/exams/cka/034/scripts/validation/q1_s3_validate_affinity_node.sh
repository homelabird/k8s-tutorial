#!/usr/bin/env bash
set -euo pipefail

POD_NAME="$(kubectl get pods -n affinity-lab -l app=api-fleet -o jsonpath='{.items[0].metadata.name}')"
NODE_NAME="$(kubectl get pod "${POD_NAME}" -n affinity-lab -o jsonpath='{.spec.nodeName}')"
NODE_OS="$(kubectl get node "${NODE_NAME}" -o jsonpath='{.metadata.labels.kubernetes\.io/os}')"

[ -n "${NODE_NAME}" ] || { echo "api-fleet Pod must be scheduled onto a node"; exit 1; }
[ "${NODE_OS}" = "linux" ] || { echo "api-fleet Pod must land on a Linux node"; exit 1; }

echo "The running Pod is scheduled onto a Linux node after the placement repair"
