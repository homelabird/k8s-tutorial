#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/qos-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetDeployment: reporting-api" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm requests, limits, QoS class, and namespace events before changing the Deployment manifest" "${MANIFEST}" >/dev/null

! grep -E "rollout restart|kubectl delete pod|kubectl set resources|kubectl patch deployment|restart the deployment" "${MANIFEST}" >/dev/null
