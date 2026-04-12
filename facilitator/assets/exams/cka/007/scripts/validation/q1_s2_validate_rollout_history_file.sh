#!/bin/bash
set -euo pipefail

NAMESPACE="rollout-lab"
DEPLOYMENT="web-app"
HISTORY_FILE="/tmp/exam/q1/rollout-history.txt"
ORIGINAL_IMAGE="nginx:1.25.3"
UPDATED_IMAGE="nginx:1.25.5"

kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
}

[ -f "$HISTORY_FILE" ] || {
  echo "Rollout history file not found at '$HISTORY_FILE'"
  exit 1
}

[ -s "$HISTORY_FILE" ] || {
  echo "Rollout history file is empty"
  exit 1
}

grep -Eq 'REVISION|CHANGE-CAUSE|web-app' "$HISTORY_FILE" || {
  echo "Rollout history file does not look like rollout history output"
  exit 1
}

RS_IMAGES="$(kubectl get rs -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].image}{"\n"}{end}')"

echo "$RS_IMAGES" | grep -qx "$ORIGINAL_IMAGE" || {
  echo "ReplicaSet history does not contain original image '$ORIGINAL_IMAGE'"
  exit 1
}

echo "$RS_IMAGES" | grep -qx "$UPDATED_IMAGE" || {
  echo "ReplicaSet history does not contain updated image '$UPDATED_IMAGE'"
  exit 1
}

echo "Rollout history output is saved and reflects the image update"
