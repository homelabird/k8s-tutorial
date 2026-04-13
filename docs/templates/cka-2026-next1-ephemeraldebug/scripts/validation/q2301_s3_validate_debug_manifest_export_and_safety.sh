#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q2301/debug-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetPod: orders-api" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm target pod, target container, debug image, and ephemeral container evidence before changing workload manifests" "${MANIFEST}" >/dev/null

! grep -E "kubectl delete pod|kubectl rollout restart|kubectl patch pod|kubectl exec|delete the pod and restart the workload" "${MANIFEST}" >/dev/null
