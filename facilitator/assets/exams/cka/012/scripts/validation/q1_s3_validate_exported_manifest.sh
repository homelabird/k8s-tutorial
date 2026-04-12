#!/bin/bash
set -euo pipefail

OUTPUT_FILE="/tmp/exam/q1/worker-api-hpa.yaml"

[ -f "$OUTPUT_FILE" ] || {
  echo "Expected HPA manifest file at $OUTPUT_FILE"
  exit 1
}

grep -Fq 'name: worker-api-hpa' "$OUTPUT_FILE" || {
  echo "Exported file must contain worker-api-hpa metadata"
  exit 1
}

grep -Fq 'name: worker-api' "$OUTPUT_FILE" || {
  echo "Exported file must contain the repaired scale target"
  exit 1
}

grep -Fq 'averageUtilization: 60' "$OUTPUT_FILE" || {
  echo "Exported file must include the repaired CPU target"
  exit 1
}

echo "The repaired HPA manifest is saved to the expected file"
