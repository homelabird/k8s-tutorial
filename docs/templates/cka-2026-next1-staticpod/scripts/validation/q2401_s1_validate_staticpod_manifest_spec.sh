#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/etc/kubernetes/manifests/audit-agent.yaml"

[ -f "${MANIFEST}" ] || {
  echo "Static pod manifest not found at ${MANIFEST}"
  exit 1
}

grep -Eq '^kind:[[:space:]]+Pod$' "${MANIFEST}" || {
  echo "audit-agent manifest must stay a Pod manifest"
  exit 1
}

grep -Eq 'name:[[:space:]]+audit-agent$' "${MANIFEST}" || {
  echo "audit-agent manifest must keep the Pod name"
  exit 1
}

grep -Eq 'namespace:[[:space:]]+staticpod-lab$' "${MANIFEST}" || {
  echo "audit-agent manifest must target namespace staticpod-lab"
  exit 1
}

grep -Eq 'hostNetwork:[[:space:]]+true$' "${MANIFEST}" || {
  echo "audit-agent manifest must enable hostNetwork"
  exit 1
}

grep -Eq 'image:[[:space:]]+busybox:1\.36$' "${MANIFEST}" || {
  echo "audit-agent must keep image busybox:1.36"
  exit 1
}

grep -F 'static-pod-audit' "${MANIFEST}" >/dev/null || {
  echo "audit-agent manifest must print static-pod-audit in the command loop"
  exit 1
}

echo "Static pod manifest keeps the intended Pod identity and host-network command configuration"
