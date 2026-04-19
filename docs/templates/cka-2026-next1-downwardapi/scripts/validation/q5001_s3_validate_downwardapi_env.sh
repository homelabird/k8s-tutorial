#!/usr/bin/env bash
set -euo pipefail

POD_NAME="$(kubectl get pods -n downwardapi-lab -l app=meta-api -o jsonpath='{.items[0].metadata.name}')"
[ -n "${POD_NAME}" ] || {
  echo "No Pod found for meta-api"
  exit 1
}

POD_ENV_NAME="$(kubectl exec -n downwardapi-lab "${POD_NAME}" -- printenv POD_NAME)"
POD_ENV_NAMESPACE="$(kubectl exec -n downwardapi-lab "${POD_NAME}" -- printenv POD_NAMESPACE)"

[ -n "${POD_ENV_NAME}" ] || {
  echo "POD_NAME is empty in the running container"
  exit 1
}

[ "${POD_ENV_NAMESPACE}" = "downwardapi-lab" ] || {
  echo "POD_NAMESPACE is not downwardapi-lab in the running container"
  exit 1
}

echo "The running container prints the expected POD_NAME and POD_NAMESPACE values"
