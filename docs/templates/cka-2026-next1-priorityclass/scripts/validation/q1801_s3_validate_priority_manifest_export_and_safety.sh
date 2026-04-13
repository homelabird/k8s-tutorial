#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1801/priority-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -F "targetDeployment: batch-api" "${MANIFEST}" >/dev/null
grep -F "targetPriorityClass: ops-critical" "${MANIFEST}" >/dev/null
grep -F "safeManifestNote:" "${MANIFEST}" >/dev/null
grep -F "confirm priorityClassName, priority value, preemption policy, and scheduler events before changing the Deployment manifest" "${MANIFEST}" >/dev/null

! grep -E "rollout restart|kubectl delete pod|kubectl patch priorityclass|kubectl patch deployment|restart the deployment" "${MANIFEST}" >/dev/null
