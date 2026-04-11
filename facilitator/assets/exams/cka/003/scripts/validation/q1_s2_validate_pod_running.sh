#!/bin/bash
set -e

PHASE=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.status.phase}' 2>/dev/null || true)
IMAGE=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || true)
COMMAND=$(kubectl get pod restricted-shell -n secure-workloads -o jsonpath='{.spec.containers[0].command[*]} {.spec.containers[0].args[*]}' 2>/dev/null || true)

if [ "$PHASE" = "Running" ] && [ "$IMAGE" = "busybox:1.36" ] && printf '%s\n' "$COMMAND" | grep -Eq '(^| )sleep 3600($| )'; then
  echo "Pod 'restricted-shell' is running with the expected image and command"
  exit 0
fi

echo "Expected running pod with image 'busybox:1.36' and command containing 'sleep 3600', got phase='${PHASE:-missing}' image='${IMAGE:-missing}' command='${COMMAND:-missing}'"
exit 1
