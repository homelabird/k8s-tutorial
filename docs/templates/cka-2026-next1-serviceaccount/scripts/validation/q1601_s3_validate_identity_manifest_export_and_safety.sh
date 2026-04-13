#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1601/identity-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -Fx "  targetDeployment: metrics-api" "${MANIFEST}" >/dev/null
grep -Fx "  safeManifestNote: confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest" "${MANIFEST}" >/dev/null

! grep -E "rollout restart|kubectl delete pod|kubectl patch deployment|restart the deployment" "${MANIFEST}" >/dev/null
