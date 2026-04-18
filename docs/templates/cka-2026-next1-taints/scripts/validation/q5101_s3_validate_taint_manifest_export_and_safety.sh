#!/usr/bin/env bash
set -euo pipefail

MANIFEST="/tmp/exam/q1/taint-diagnostics-brief.yaml"
[[ -f "$MANIFEST" ]]

grep -F "targetDeployment: taint-api" "$MANIFEST" >/dev/null
grep -F "safeManifestNote" "$MANIFEST" >/dev/null
grep -F "confirm taint effect, toleration seconds, and node selector before changing workload manifests or mutating node taints" "$MANIFEST" >/dev/null
! grep -Eq 'kubectl drain|kubectl delete pod -n taints-lab -l app=taint-api|kubectl rollout restart deployment taint-api|patch taints until the workload stabilizes' "$MANIFEST"
