#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/pull-auth-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetDeployment: private-api" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm imagePullSecrets, ServiceAccount wiring, secret type, and image reference before changing the Deployment manifest" "${MANIFEST}" >/dev/null

! grep -E "rollout restart|kubectl delete pod|kubectl set serviceaccount|kubectl patch deployment|restart the deployment" "${MANIFEST}" >/dev/null
