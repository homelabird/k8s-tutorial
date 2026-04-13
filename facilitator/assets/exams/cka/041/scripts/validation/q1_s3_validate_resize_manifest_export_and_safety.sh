#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/resize-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetPvc: analytics-data" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm requested size, current capacity, resize support, PVC conditions, and mount path before changing storage manifests" "${MANIFEST}" >/dev/null

! grep -E "kubectl edit pvc|kubectl delete pvc|kubectl patch storageclass|kubectl rollout restart|edit the pvc and restart the workload" "${MANIFEST}" >/dev/null
