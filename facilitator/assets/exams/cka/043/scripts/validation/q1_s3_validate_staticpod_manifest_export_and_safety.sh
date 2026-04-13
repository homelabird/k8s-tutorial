#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/staticpod-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetMirrorPod: audit-agent-ckad9999" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm manifest path, mirror pod inventory, hostNetwork setting, and container command before changing static pod manifests" "${MANIFEST}" >/dev/null

! grep -E "kubectl delete pod|systemctl restart kubelet|sudo mv /etc/kubernetes/manifests|delete the mirror pod and restart kubelet" "${MANIFEST}" >/dev/null
