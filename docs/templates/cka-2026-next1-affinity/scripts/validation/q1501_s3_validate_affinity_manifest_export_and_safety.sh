#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1501/placement-diagnostics-brief.yaml"
[[ -f "${MANIFEST}" ]]

grep -Fx "  targetDeployment: api-fleet" "${MANIFEST}" >/dev/null
grep -Fx "  safeManifestNote: confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest" "${MANIFEST}" >/dev/null

! grep -E "rollout restart|kubectl delete pod|kubectl patch deployment|kubectl scale deployment|restart the deployment" "${MANIFEST}" >/dev/null
