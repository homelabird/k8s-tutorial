#!/bin/bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ -f "${SCRIPT_DIR}/lib/container-runtime.sh" ]; then
    source "${SCRIPT_DIR}/lib/container-runtime.sh"
else
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

    set_compose_files() {
        COMPOSE_FILE_ARGS=()

        while [ "$#" -gt 0 ]; do
            COMPOSE_FILE_ARGS+=(-f "$1")
            shift
        done
    }

    run_compose() {
        "${COMPOSE_CMD[@]}" "${COMPOSE_FILE_ARGS[@]}" "$@"
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

    service_is_healthy() {
        local service="$1"
        local output

        if is_podman_runtime; then
            output=$(podman ps --filter "label=io.podman.compose.service=${service}" --format '{{.Status}}')
            printf '%s\n' "${output}" | grep -q "(healthy)"
            return
        fi

        output=$(run_compose ps "$service" 2>/dev/null || true)
        printf '%s\n' "${output}" | grep -q "healthy"
    }

    compose_display_cmd() {
        local parts=()
        local rendered

        if is_podman_runtime && is_root_user && [ -n "${SUDO_USER:-}" ]; then
            parts+=(sudo)
        fi

        parts+=("${COMPOSE_CMD[@]}")

        if [ "${#COMPOSE_FILE_ARGS[@]}" -gt 0 ]; then
            parts+=("${COMPOSE_FILE_ARGS[@]}")
        fi

        printf -v rendered '%q ' "${parts[@]}"
        printf '%s' "${rendered% }"
    }
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art and Description
print_header() {
    echo -e "${BLUE}"
    echo "░█████╗░██╗░░██╗░░░░░░██╗░░██╗  ░██████╗██╗███╗░░░███╗██╗░░░██╗██╗░░░░░░█████╗░████████╗░█████╗░██████╗░"
    echo "██╔══██╗██║░██╔╝░░░░░░╚██╗██╔╝  ██╔════╝██║████╗░████║██║░░░██║██║░░░░░██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗"
    echo "██║░░╚═╝█████═╝░█████╗░╚███╔╝░  ╚█████╗░██║██╔████╔██║██║░░░██║██║░░░░░███████║░░░██║░░░██║░░██║██████╔╝" 
    echo "██║░░██╗██╔═██╗░╚════╝░██╔██╗░  ░╚═══██╗██║██║╚██╔╝██║██║░░░██║██║░░░░░██╔══██║░░░██║░░░██║░░██║██╔══██╗"
    echo "╚█████╔╝██║░╚██╗░░░░░░██╔╝╚██╗  ██████╔╝██║██║░╚═╝░██║╚██████╔╝███████╗██║░░██║░░░██║░░░╚█████╔╝██║░░██║"
    echo "░╚════╝░╚═╝░░╚═╝░░░░░░╚═╝░░╚═╝  ╚═════╝░╚═╝╚═╝░░░░░╚═╝░╚═════╝░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝"
    echo -e "${NC}"
    echo -e "${CYAN}==============================================================${NC}"
    echo -e "${CYAN}CK-X Simulator: Kubernetes Certification Exam Simulator${NC}"
    echo -e "${CYAN}Practice in a realistic environment for CKA, CKAD, and more${NC}"
    echo -e "${CYAN}==============================================================${NC}"
    echo -e "${CYAN} Facing any issues? Please report at: https://github.com/nishanb/CK-X/issues${NC}"
    echo
}

# Function to check if the selected container runtime is running
check_container_runtime_running() {
    if ! container_runtime_info >/dev/null 2>&1; then
        echo -e "${RED}✗ ${CONTAINER_RUNTIME_LABEL} is not running${NC}"
        echo -e "${YELLOW}Please start ${CONTAINER_RUNTIME_LABEL} and try again${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ ${CONTAINER_RUNTIME_LABEL} is running${NC}"
    echo
}

# Function to check system requirements
check_requirements() {
    echo -e "${BLUE}Checking System Requirements${NC}"
    echo -e "${CYAN}==============================================================${NC}"
    
    if ! detect_container_runtime; then
        echo -e "${RED}✗ No supported container runtime was detected${NC}"
        echo -e "${YELLOW}Install one of the following and try again:${NC}"
        echo -e "${CYAN}- Docker with Docker Compose v2${NC}"
        echo -e "${CYAN}- Podman with podman compose or podman-compose${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Using ${CONTAINER_RUNTIME_LABEL} via ${COMPOSE_PROVIDER}${NC}"
    
    # Check if the selected runtime is running
    check_container_runtime_running

    if is_podman_runtime; then
        if ! is_root_user; then
            echo -e "${RED}✗ CK-X requires rootful Podman for privileged services${NC}"
            echo -e "${YELLOW}Re-run this installer with sudo so outer compose also uses rootful Podman${NC}"
            exit 1
        fi
        echo -e "${YELLOW}Podman deployments should use rootful mode for the privileged CK-X services${NC}"
        echo
    fi
    
    # Check curl
    if ! command_exists curl; then
        echo -e "${RED}✗ curl is not installed${NC}"
        echo -e "${YELLOW}Please install curl first${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ curl is installed${NC}"
    
    echo -e "${GREEN}✓ All system requirements satisfied${NC}"
    echo
}

# Function to check if ports are available
check_ports() {
    local port=30080
    
    echo -e "${BLUE}Checking Port Availability${NC}"
    echo -e "${CYAN}==============================================================${NC}"
    
    # Try different methods to check port availability
    if command_exists ss; then
        # Using ss (modern alternative to netstat)
        if ss -tuln | grep -q ":${port} "; then
            echo -e "${RED}✗ Port ${port} is already in use${NC}"
            echo -e "${YELLOW}Please free this port and try again${NC}"
            exit 1
        fi
    elif command_exists lsof; then
        # Using lsof
        if lsof -i :${port} >/dev/null 2>&1; then
            echo -e "${RED}✗ Port ${port} is already in use${NC}"
            echo -e "${YELLOW}Please free this port and try again${NC}"
            exit 1
        fi
    else
        # Fallback: try to bind to the port
        if timeout 1 bash -c ">/dev/tcp/localhost/${port}" 2>/dev/null; then
            echo -e "${RED}✗ Port ${port} is already in use${NC}"
            echo -e "${YELLOW}Please free this port and try again${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✓ Port ${port} is available${NC}"
    echo
}

# Function to wait for service health (modified to be silent)
wait_for_service() {
    local service=$1
    local max_attempts=30
    local attempt=1
    
    # No output headers here anymore
    
    while [ $attempt -le $max_attempts ]; do
        if service_is_healthy "$service"; then
            return 0
        fi
        # No progress dots
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}✗ Timeout waiting for $service to be ready${NC}"
    return 1
}

# Function to open browser
open_browser() {
    local url="http://localhost:30080/"
    local compose_display

    echo -e "${BLUE}Opening Browser${NC}"
    echo -e "${CYAN}==============================================================${NC}"

    if is_root_user && [ -n "${SUDO_USER:-}" ]; then
        echo -e "${YELLOW}Running under sudo, skipping automatic browser launch.${NC}"
        echo -e "${GREEN}${url}${NC}"
        return 0
    fi
    
    # Try different methods to open browser
    if command_exists xdg-open; then
        # Linux with desktop environment
        xdg-open $url 2>/dev/null && echo -e "${GREEN}✓ Browser opened successfully${NC}" && return 0
    elif command_exists open; then
        # macOS
        open $url 2>/dev/null && echo -e "${GREEN}✓ Browser opened successfully${NC}" && return 0
    elif command_exists python3; then
        # Try Python as fallback
        python3 -m webbrowser $url 2>/dev/null && echo -e "${GREEN}✓ Browser opened successfully${NC}" && return 0
    elif command_exists python; then
        # Try Python 2 as last resort
        python -m webbrowser $url 2>/dev/null && echo -e "${GREEN}✓ Browser opened successfully${NC}" && return 0
    fi
    
    echo -e "${YELLOW}Could not automatically open browser. Please visit:${NC}"
    echo -e "${GREEN}${url}${NC}"
    compose_display=$(compose_display_cmd)
    echo -e "${YELLOW}If the services are not up yet, check:${NC} ${GREEN}${compose_display} logs -f${NC}"
    return 0
}

# Main installation process
main() {
    print_header
    
    # Check requirements
    check_requirements
    
    # Check port
    check_ports
    
    # Create project directory
    echo -e "${BLUE}Setting Up Installation${NC}"
    echo -e "${CYAN}==============================================================${NC}"
    echo -e "${YELLOW}Creating project directory...${NC}"
    mkdir -p ck-x-simulator && cd ck-x-simulator
    
    if is_podman_runtime; then
        echo -e "${YELLOW}Downloading CK-X source archive for Podman-compatible local builds...${NC}"
        curl -fsSL https://github.com/nishanb/CK-X/archive/refs/heads/master.tar.gz -o ck-x-source.tar.gz

        if [ ! -f ck-x-source.tar.gz ]; then
            echo -e "${RED}✗ Failed to download CK-X source archive${NC}"
            exit 1
        fi

        tar -xzf ck-x-source.tar.gz --strip-components=1
        rm -f ck-x-source.tar.gz

        if [ ! -f docker-compose.yaml ] || [ ! -f docker-compose.podman.yaml ]; then
            echo -e "${RED}✗ Failed to prepare local Podman build files${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Source archive extracted${NC}"
        set_compose_files docker-compose.yaml docker-compose.podman.yaml
    else
        # Download the compose file used by the published Docker image workflow
        echo -e "${YELLOW}Downloading compose file...${NC}"
        curl -fsSL https://raw.githubusercontent.com/nishanb/ck-x/master/docker-compose.yaml -o docker-compose.yml
        
        if [ ! -f docker-compose.yml ]; then
            echo -e "${RED}✗ Failed to download docker-compose.yml${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Compose file downloaded${NC}"
        set_compose_files docker-compose.yml
    fi
    
    if is_podman_runtime; then
        echo -e "${YELLOW}Building CK-X images locally for Podman compatibility...${NC}"
        run_compose build
        echo -e "${GREEN}✓ Container images built successfully${NC}"
    else
        # Pull images
        echo -e "${YELLOW}Pulling container images with ${COMPOSE_PROVIDER}...${NC}"
        run_compose pull
        echo -e "${GREEN}✓ Container images pulled successfully${NC}"
    fi
    
    # Start services
    echo -e "${YELLOW}Starting CK-X services...${NC}"
    if is_podman_runtime; then
        run_compose up -d --force-recreate
    else
        run_compose up -d
    fi
    echo -e "${GREEN}✓ Services started${NC}"
    
    # Combined waiting message instead of individual service wait messages
    echo -e "${YELLOW}Waiting for services to initialize...${NC}"
    wait_for_service "webapp" || exit 1
    wait_for_service "facilitator" || exit 1
    echo -e "${GREEN}✓ All services initialized successfully${NC}"
    
    echo -e "\n${BLUE}Installation Complete!${NC}"
    echo -e "${CYAN}==============================================================${NC}"
    echo -e "${GREEN}✓ CK-X Simulator has been installed successfully${NC}"
    
    # Wait a bit for the service to be fully ready
    sleep 5
    
    # Try to open browser
    open_browser
    
    echo -e "\n${BLUE}Useful Commands${NC}"
    echo -e "${CYAN}==============================================================${NC}"
    echo -e "${YELLOW}CK-X Simulator has been installed in:${NC} ${GREEN}$(pwd)${NC}, run all below commands from this directory"
    local compose_display
    compose_display=$(compose_display_cmd)
    echo -e "${YELLOW}To stop CK-X:${NC} ${GREEN}${compose_display} down --volumes --remove-orphans${NC}"
    echo -e "${YELLOW}To Restart CK-X:${NC} ${GREEN}${compose_display} restart${NC}"
    echo -e "${YELLOW}To view logs:${NC} ${GREEN}${compose_display} logs -f${NC}"
    if [ "${CONTAINER_RUNTIME}" = "docker" ]; then
        echo -e "${YELLOW}To clean up all containers and images:${NC} ${GREEN}docker system prune -a${NC}"
    else
        echo -e "${YELLOW}To clean up all containers and images:${NC} ${GREEN}podman system prune -a${NC}"
    fi
    echo -e "${YELLOW}To remove only CK-X images:${NC} ${GREEN}${compose_display} down --rmi all --remove-orphans${NC}"
    echo -e "${YELLOW}To access CK-X Simulator:${NC} ${GREEN}http://localhost:30080/${NC}"
    echo
    echo -e "${CYAN}Thank you for installing CK-X Simulator!${NC}"
}

# Run main function
main 
