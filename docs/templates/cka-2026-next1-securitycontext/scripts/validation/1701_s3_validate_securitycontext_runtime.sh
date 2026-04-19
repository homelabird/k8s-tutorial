#!/usr/bin/env bash
set -euo pipefail

UID_VALUE="$(kubectl exec -n securitycontext-lab deploy/secure-api -- id -u)"
[ "${UID_VALUE}" = "1000" ] || { echo "secure-api must run as UID 1000"; exit 1; }

kubectl exec -n securitycontext-lab deploy/secure-api -- cat /data/secure.txt | grep -Fx 'secure' >/dev/null || {
  echo "secure-api must write /data/secure.txt"
  exit 1
}

echo "The running container uses UID 1000 and writes the expected file under /data"
