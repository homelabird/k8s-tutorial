#!/bin/bash
set -euo pipefail

# cleanup-exam-env.sh
# 
# This script cleans up the exam environment on the jumphost.
# It removes all resources created during the exam to prepare for a new exam.
#
# Usage: cleanup-exam-env.sh
#
# Example: cleanup-exam-env.sh

# Log function with timestamp
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

TARGET_CLUSTER_NAME=${1:-${CLUSTER_NAME:-cluster}}
K8S_API_SERVER_HOST=${2:-${K8S_API_SERVER_HOST:-k8s-api-server}}

log "Starting exam environment cleanup"
log "Cleaning up cluster $TARGET_CLUSTER_NAME"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null candidate@"$K8S_API_SERVER_HOST" "env-cleanup $TARGET_CLUSTER_NAME"

#cleanup docker env
log "Cleaning up docker environment"
docker system prune -a --volumes -fa
docker network prune -f
docker image prune -fa

# Remove the exam environment directory
log "Removing exam environment directory"
rm -rf /tmp/exam-env
rm -rf /tmp/exam

# Remove stale kubeconfig files so the next session always gets a fresh cluster context
log "Removing local kubeconfig files"
rm -f /home/candidate/.kube/config /home/candidate/.kube/kubeconfig
rm -rf /home/candidate/.kube/cache

# Remove the exam assets directory
log "Removing exam assets directory"
rm -rf /tmp/exam-assets

log "Exam environment cleanup completed successfully"
exit 0 
