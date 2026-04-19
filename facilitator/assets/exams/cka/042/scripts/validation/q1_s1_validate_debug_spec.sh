#!/usr/bin/env bash
set -euo pipefail

DEBUGGER_NAME="$(kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[0].name}')"
DEBUGGER_IMAGE="$(kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[0].image}')"
TARGET_CONTAINER="$(kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[0].targetContainerName}')"

[ "${DEBUGGER_NAME}" = "debugger" ] || { echo "orders-api must have ephemeral container debugger"; exit 1; }
[ "${DEBUGGER_IMAGE}" = "busybox:1.36" ] || { echo "debugger must use image busybox:1.36"; exit 1; }
[ "${TARGET_CONTAINER}" = "api" ] || { echo "debugger must target container api"; exit 1; }

echo "Pod orders-api contains the intended ephemeral container name, image, and target container wiring"
