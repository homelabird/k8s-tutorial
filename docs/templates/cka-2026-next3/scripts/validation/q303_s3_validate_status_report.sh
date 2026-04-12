#!/bin/bash
set -euo pipefail

TARGET_NODE="$(kubectl get nodes -l maintenance-lab=target -o jsonpath='{.items[0].metadata.name}')"
OUTPUT_FILE="/tmp/exam/q303/node-status.txt"

[ -n "$TARGET_NODE" ] || {
  echo "No maintenance target node found"
  exit 1
}

[ -f "$OUTPUT_FILE" ] || {
  echo "Expected node status file at $OUTPUT_FILE"
  exit 1
}

grep -Fq "$TARGET_NODE" "$OUTPUT_FILE" || {
  echo "Node status report must mention the target node"
  exit 1
}

grep -Eq '\bReady\b' "$OUTPUT_FILE" || {
  echo "Node status report must show the node as Ready"
  exit 1
}

echo "A node status report is saved for the recovered target node"
