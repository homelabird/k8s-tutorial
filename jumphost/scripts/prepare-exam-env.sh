#!/bin/bash
set -euo pipefail


# Log function with timestamp
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Set defaults
NUMBER_OF_NODES=${1:-1}
EXAM_ID=${2:-""}
TARGET_CLUSTER_NAME=${3:-${CLUSTER_NAME:-cluster}}
QUESTION_IDS_CSV=${4:-""}
TARGET_API_PORT=${5:-${KUBE_API_PORT:-6443}}
K8S_API_SERVER_HOST=${6:-${K8S_API_SERVER_HOST:-k8s-api-server}}

echo "Exam ID: $EXAM_ID"
echo "Number of nodes: $NUMBER_OF_NODES"
echo "Cluster name: $TARGET_CLUSTER_NAME"
echo "Question IDs: ${QUESTION_IDS_CSV:-all}"
echo "Kube API port: $TARGET_API_PORT"

#check docker is running
if ! docker info > /dev/null 2>&1; then
  log "Docker is not running"
  log "Attempting to start docker"
  dockerd &
  sleep 5
  #check docker is running 3 times with 5 second interval
  for i in {1..3}; do
    if docker info > /dev/null 2>&1; then
      log "Docker started successfully"
      break
    fi
    log "Docker failed to start, retrying..."
    sleep 5
  done
fi

log "Starting exam environment preparation with $NUMBER_OF_NODES node(s)"

log "Reconciling stale cluster state for $TARGET_CLUSTER_NAME before setup"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  candidate@"$K8S_API_SERVER_HOST" \
  "env-cleanup $TARGET_CLUSTER_NAME >/dev/null 2>&1 || true"

# Validate input
if ! [[ "$NUMBER_OF_NODES" =~ ^[0-9]+$ ]]; then
  log "ERROR: Number of nodes must be a positive integer"
  exit 1
fi

# Setup kind cluster
if ! ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  candidate@"$K8S_API_SERVER_HOST" \
  "env-setup $NUMBER_OF_NODES $TARGET_CLUSTER_NAME $TARGET_API_PORT"; then
  log "ERROR: Failed to create cluster runtime for $TARGET_CLUSTER_NAME on $K8S_API_SERVER_HOST"
  exit 1
fi

#Pull assets from URL
curl -fsS facilitator:3000/api/v1/exams/$EXAM_ID/assets -o assets.tar.gz

mkdir -p /tmp/exam-assets
#Unzip assets
tar -xzvf assets.tar.gz -C /tmp/exam-assets    

#Remove assets.tar.gz
rm assets.tar.gz

#make every file in /tmp/exam-assets executable
find /tmp/exam-assets -type f -exec chmod +x {} \;

echo "Exam assets downloaded and prepared successfully" 

mkdir -p /home/candidate/.kube
rm -f /home/candidate/.kube/config /home/candidate/.kube/kubeconfig
if ! ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  candidate@"$K8S_API_SERVER_HOST" \
  "env-kubeconfig $TARGET_CLUSTER_NAME" > /home/candidate/.kube/kubeconfig; then
  log "ERROR: Failed to fetch kubeconfig for $TARGET_CLUSTER_NAME from $K8S_API_SERVER_HOST"
  rm -f /home/candidate/.kube/kubeconfig /home/candidate/.kube/config
  exit 1
fi
cp /home/candidate/.kube/kubeconfig /home/candidate/.kube/config
chmod 600 /home/candidate/.kube/kubeconfig /home/candidate/.kube/config

export KUBECONFIG=/home/candidate/.kube/kubeconfig

sleep 5

#wait till api-server is ready
API_SERVER_READY_ATTEMPTS=0
until kubectl get nodes > /dev/null 2>&1; do
  API_SERVER_READY_ATTEMPTS=$((API_SERVER_READY_ATTEMPTS + 1))
  if [ "$API_SERVER_READY_ATTEMPTS" -ge 60 ]; then
    log "ERROR: API server for $TARGET_CLUSTER_NAME did not become ready in time"
    exit 1
  fi
  log "API server is not ready, retrying..."
  sleep 5
done

echo "API server is ready"

#Run setup scripts
if [ -n "$QUESTION_IDS_CSV" ]; then
  IFS=',' read -r -a QUESTION_IDS <<< "$QUESTION_IDS_CSV"
  for question_id in "${QUESTION_IDS[@]}"; do
    script="/tmp/exam-assets/scripts/setup/q${question_id}_setup.sh"
    if [ ! -x "$script" ]; then
      log "ERROR: Setup script not found for question ${question_id}: $script"
      exit 1
    fi
    "$script"
  done
else
  for script in /tmp/exam-assets/scripts/setup/q*_setup.sh; do
    [ -e "$script" ] || continue
    "$script"
  done
fi

log "Exam environment preparation completed successfully"
exit 0 
