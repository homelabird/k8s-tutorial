#!/bin/sh

# ===============================================================================
#   K3D Cluster Setup Entrypoint Script
#   Purpose: Initialize a Docker-compatible runtime and prepare K3D
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== INITIALIZATION STARTED ====="
echo "$(date '+%Y-%m-%d %H:%M:%S') | Executing container startup script..."

RUNTIME_ENV_FILE=/etc/ckx-cluster-runtime.env

if [ "${CLUSTER_RUNTIME:-docker}" = "podman" ]; then
    export DOCKER_HOST="${DOCKER_HOST:-unix:///run/podman/podman.sock}"
    export DOCKER_SOCK="${DOCKER_SOCK:-/run/podman/podman.sock}"

    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Using Podman Docker API socket: ${DOCKER_SOCK}"

    mkdir -p /var/run
    ln -sf "${DOCKER_SOCK}" /var/run/docker.sock
else
    # Execute current entrypoint script
    if [ -f /usr/local/bin/startup.sh ]; then
        STORAGE_DRIVER_ARGS=""

        if [ -n "${DOCKER_STORAGE_DRIVER:-}" ]; then
            STORAGE_DRIVER_ARGS="--storage-driver=${DOCKER_STORAGE_DRIVER}"
        elif [ -n "${DOCKER_DRIVER:-}" ]; then
            STORAGE_DRIVER_ARGS="--storage-driver=${DOCKER_DRIVER}"
        fi

        sh /usr/local/bin/startup.sh ${STORAGE_DRIVER_ARGS} &
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Default startup script not found at /usr/local/bin/startup.sh"
    fi
fi

cat > "${RUNTIME_ENV_FILE}" <<EOF
CLUSTER_RUNTIME=${CLUSTER_RUNTIME:-docker}
DOCKER_HOST=${DOCKER_HOST:-}
DOCKER_SOCK=${DOCKER_SOCK:-}
KUBE_API_ENDPOINT=${KUBE_API_ENDPOINT:-k8s-api-server}
K3D_PODMAN_NETWORK=${K3D_PODMAN_NETWORK:-k3d}
EOF
chmod 0644 "${RUNTIME_ENV_FILE}"

# ===============================================================================
#   Runtime Readiness Check
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | Checking container runtime status..."
RUNTIME_CHECK_COUNT=0

# Wait for the configured Docker-compatible API to be ready
while ! docker ps; do   
    RUNTIME_CHECK_COUNT=$((RUNTIME_CHECK_COUNT+1))
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [WAITING] Container runtime not ready yet... (attempt $RUNTIME_CHECK_COUNT)"
    sleep 5
done

echo "$(date '+%Y-%m-%d %H:%M:%S') | [SUCCESS] Container runtime is ready and operational"

#pull kindest/node image
# docker pull kindest/node:$KIND_DEFAULT_VERSION

#add user for ssh access
adduser -S -D -H -s /sbin/nologin -G sshd sshd

#start ssh service
/usr/sbin/sshd -D &

#install k3d
echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Installing k3d"
TAG=v5.8.3 bash /usr/local/bin/k3d-install.sh

cluster_exists() {
    target_cluster="$1"
    [ -n "$target_cluster" ] || return 1
    k3d cluster list | awk 'NR > 1 { print $1 }' | grep -Fxq "$target_cluster"
}

reconcile_default_cluster() {
    target_cluster="${CLUSTER_NAME:-}"
    [ -n "$target_cluster" ] || return 0

    if ! cluster_exists "$target_cluster"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] No stale cluster reconciliation needed for '$target_cluster'"
        return 0
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Removing stale cluster '$target_cluster' left behind by a previous hard shutdown"
    k3d cluster delete "$target_cluster"

    while cluster_exists "$target_cluster"; do
        sleep 1
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Stale cluster '$target_cluster' removed"
}

if [ "${CKX_RECONCILE_STALE_CLUSTER_ON_BOOT:-true}" = "true" ]; then
    reconcile_default_cluster
fi

sleep 10
touch /ready

# Keep container running
tail -f /dev/null
