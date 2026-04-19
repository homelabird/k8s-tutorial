#!/usr/bin/env bash
set -euo pipefail

RESOLV_CONF="$(kubectl exec -n dnspolicy-lab deploy/dns-client -- cat /etc/resolv.conf)"

printf '%s\n' "${RESOLV_CONF}" | grep -Fx 'nameserver 1.1.1.1' >/dev/null || {
  echo "Resolver file is missing nameserver 1.1.1.1"
  exit 1
}

printf '%s\n' "${RESOLV_CONF}" | grep -Fx 'search lab.local' >/dev/null || {
  echo "Resolver file is missing search lab.local"
  exit 1
}

printf '%s\n' "${RESOLV_CONF}" | grep -F 'options ndots:2' >/dev/null || {
  echo "Resolver file is missing options ndots:2"
  exit 1
}

echo "The running Pod resolver file contains the expected nameserver, search, and ndots settings"
