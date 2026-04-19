#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n probe-lab deploy/health-api -- wget -qO- http://127.0.0.1:8080/healthz | grep -Fx 'ok' >/dev/null || {
  echo "health-api must serve ok at /healthz"
  exit 1
}

echo "The running container serves ok at the repaired /healthz endpoint"
