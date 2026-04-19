#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="lifecycle-lab"
DEPLOYMENT="lifecycle-api"

GRACE_PERIOD="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}')"
PRESTOP_0="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[0]}')"
PRESTOP_2="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]}')"
IMAGE="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].image}')"
COMMAND_2="$(kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].command[2]}')"

[ "${GRACE_PERIOD}" = "30" ] || {
  echo "lifecycle-api must use terminationGracePeriodSeconds 30"
  exit 1
}

[ "${PRESTOP_0}" = "/bin/sh" ] || {
  echo "lifecycle-api must use an exec preStop hook"
  exit 1
}

[ "${PRESTOP_2}" = "sleep 5" ] || {
  echo "lifecycle-api preStop hook must run sleep 5"
  exit 1
}

[ "${IMAGE}" = "busybox:1.36" ] || {
  echo "lifecycle-api must keep image busybox:1.36"
  exit 1
}

[ "${COMMAND_2}" = "while true; do sleep 30; done" ] || {
  echo "lifecycle-api must keep the long-running sleep loop"
  exit 1
}

echo "Deployment lifecycle-api keeps the intended graceful termination spec"
