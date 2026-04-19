#!/usr/bin/env bash
set -euo pipefail

for _ in $(seq 1 30); do
  if kubectl logs -n debug-lab orders-api -c debugger 2>/dev/null | grep -Fx "debug-ready" >/dev/null; then
    echo "The debugger ephemeral container logs debug-ready"
    exit 0
  fi
  sleep 2
done

echo "debugger logs must contain debug-ready"
exit 1
