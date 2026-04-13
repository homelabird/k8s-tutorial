#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q2101/reclaim-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetPvc: reports-data" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm PVC binding, PV reclaim policy, claimRef, and workload mount path before changing storage manifests" "${MANIFEST}" >/dev/null

! grep -E "kubectl delete pvc|kubectl delete pv|kubectl scale deployment|kubectl patch pv|delete and patch storage objects" "${MANIFEST}" >/dev/null
