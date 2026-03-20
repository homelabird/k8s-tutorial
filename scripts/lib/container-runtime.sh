#!/usr/bin/env bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_container_runtime() {
    if command_exists docker && docker compose version >/dev/null 2>&1; then
        CONTAINER_RUNTIME="docker"
        CONTAINER_RUNTIME_LABEL="Docker"
        COMPOSE_PROVIDER="docker compose"
        COMPOSE_CMD=(docker compose)
        return 0
    fi

    if command_exists podman && podman compose version >/dev/null 2>&1; then
        CONTAINER_RUNTIME="podman"
        CONTAINER_RUNTIME_LABEL="Podman"
        COMPOSE_PROVIDER="podman compose"
        COMPOSE_CMD=(podman compose)
        return 0
    fi

    if command_exists podman-compose; then
        CONTAINER_RUNTIME="podman"
        CONTAINER_RUNTIME_LABEL="Podman"
        COMPOSE_PROVIDER="podman-compose"
        COMPOSE_CMD=(podman-compose)
        return 0
    fi

    return 1
}

run_compose() {
    "${COMPOSE_CMD[@]}" "${COMPOSE_FILE_ARGS[@]}" "$@"
}

set_compose_files() {
    COMPOSE_FILE_ARGS=()

    while [ "$#" -gt 0 ]; do
        COMPOSE_FILE_ARGS+=(-f "$1")
        shift
    done
}

container_runtime_info() {
    case "${CONTAINER_RUNTIME:-}" in
        docker)
            docker info
            ;;
        podman)
            podman info
            ;;
        *)
            return 1
            ;;
    esac
}

is_podman_runtime() {
    [ "${CONTAINER_RUNTIME:-}" = "podman" ]
}

is_root_user() {
    [ "$(id -u)" -eq 0 ]
}

compose_display_cmd() {
    if is_podman_runtime && is_root_user && [ -n "${SUDO_USER:-}" ]; then
        printf 'sudo %s' "${COMPOSE_PROVIDER}"
    else
        printf '%s' "${COMPOSE_PROVIDER}"
    fi
}
