#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1401/init-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -Fx "  targetDeployment: report-api" "${MANIFEST}" >/dev/null
grep -Fx "  safeManifestNote: confirm init container command, shared volume name, and mount paths before changing the Deployment manifest" "${MANIFEST}" >/dev/null

! grep -E "rollout restart|kubectl delete pod|kubectl patch deployment|restart the deployment" "${MANIFEST}" >/dev/null
