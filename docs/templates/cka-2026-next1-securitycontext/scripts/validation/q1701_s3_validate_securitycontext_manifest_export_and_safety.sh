#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1701/securitycontext-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetDeployment: secure-api" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest" "${MANIFEST}" >/dev/null

! grep -E "rollout restart|kubectl delete pod|kubectl patch deployment|restart the deployment" "${MANIFEST}" >/dev/null
