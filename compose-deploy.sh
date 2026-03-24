#!/usr/bin/env bash

# ===============================================================================
# 
#   ██████╗██╗  ██╗ █████╗ ██████╗     ███████╗██╗███╗   ███╗██╗   ██╗██╗      █████╗ ████████╗ ██████╗ ██████╗ 
#  ██╔════╝██║ ██╔╝██╔══██╗██╔══██╗    ██╔════╝██║████╗ ████║██║   ██║██║     ██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗
#  ██║     █████╔╝ ███████║██║  ██║    ███████╗██║██╔████╔██║██║   ██║██║     ███████║   ██║   ██║   ██║██████╔╝
#  ██║     ██╔═██╗ ██╔══██║██║  ██║    ╚════██║██║██║╚██╔╝██║██║   ██║██║     ██╔══██║   ██║   ██║   ██║██╔══██╗
#  ╚██████╗██║  ██╗██║  ██║██████╔╝    ███████║██║██║ ╚═╝ ██║╚██████╔╝███████╗██║  ██║   ██║   ╚██████╔╝██║  ██║
#   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝     ╚══════╝╚═╝╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
#                                                                                                                 
# ===============================================================================
#  Docker Compose CKAD Deployment Script
#  Version: 1.0.0
#  Author: Nishan B
# ===============================================================================

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/scripts/lib/container-runtime.sh"

# Define colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Define symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
INFO="${BLUE}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"
ARROW="${CYAN}➜${NC}"
STAR="${PURPLE}★${NC}"
CLOCK="${YELLOW}⏱${NC}"

# Define variables
SCRIPT_START_TIME=$(date +%s)

# ===============================================================================
# UTILITY FUNCTIONS
# ===============================================================================

# Print timestamp
print_timestamp() {
  echo -e "${GRAY}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Print section header
print_header() {
  local title="$1"
  local title_length=${#title}
  local total_length=80
  local side_length=$(( (total_length - title_length - 2) / 2 ))
  local side_line=$(printf '%*s' "$side_length" | tr ' ' '═')
  
  echo -e "\n${BOLD}${PURPLE}$side_line${NC} ${BOLD}${CYAN}$title${NC} ${BOLD}${PURPLE}$side_line${NC}\n"
}

# Print success message
print_success() {
  print_timestamp "${CHECK} ${GREEN}$1${NC}"
}

# Print info message
print_info() {
  print_timestamp "${INFO} $1"
}

# Print warning message
print_warning() {
  print_timestamp "${WARN} ${YELLOW}$1${NC}"
}

# Print error message
print_error() {
  print_timestamp "${CROSS} ${RED}$1${NC}" >&2
}

# Print progress
print_progress() {
  echo -e "  ${ARROW} ${GRAY}$1${NC}"
}

open_browser() {
  local url="$1"
  local compose_display

  if is_root_user && [ -n "${SUDO_USER:-}" ]; then
    print_warning "Running under sudo, skipping automatic browser launch"
    print_info "Open the simulator manually at ${url}"
    return 0
  fi

  if command_exists xdg-open && xdg-open "${url}" >/dev/null 2>&1; then
    print_success "Browser opened successfully"
    return 0
  fi

  if command_exists open && open "${url}" >/dev/null 2>&1; then
    print_success "Browser opened successfully"
    return 0
  fi

  if command_exists python3 && python3 -m webbrowser "${url}" >/dev/null 2>&1; then
    print_success "Browser opened successfully"
    return 0
  fi

  compose_display=$(compose_display_cmd)
  print_warning "Could not automatically open the browser"
  print_info "Open the simulator manually at ${url}"
  print_info "Check service logs with: ${compose_display} logs -f"
  return 0
}

# Error handler
handle_error() {
  print_error "An error occurred at line $1"
  print_error "Deployment failed!"
  exit 1
}

# Calculate elapsed time
elapsed_time() {
  local end_time=$(date +%s)
  local elapsed=$((end_time - SCRIPT_START_TIME))
  local minutes=$((elapsed / 60))
  local seconds=$((elapsed % 60))
  echo "${minutes}m ${seconds}s"
}

# Setup error handling
trap 'handle_error $LINENO' ERR

# ===============================================================================
# MAIN SCRIPT
# ===============================================================================

print_header "DEPLOYMENT STARTED"

if ! detect_container_runtime; then
  print_error "No supported container runtime was detected"
  print_error "Install Docker Compose v2 or Podman with podman compose/podman-compose"
  exit 1
fi

if is_podman_runtime && [ -f "${SCRIPT_DIR}/docker-compose.podman.yaml" ]; then
  set_compose_files "${SCRIPT_DIR}/docker-compose.yaml" "${SCRIPT_DIR}/docker-compose.podman.yaml"
else
  set_compose_files "${SCRIPT_DIR}/docker-compose.yaml"
fi

print_info "Starting deployment process for CKAD Simulator with ${COMPOSE_PROVIDER}"

if is_podman_runtime; then
  if ! is_root_user; then
    print_error "CK-X requires rootful Podman for privileged services"
    print_error "Re-run this script with sudo so outer compose also uses rootful Podman"
    exit 1
  fi
  print_warning "Podman deployments should use rootful mode for the privileged CK-X services"
fi

# ===============================================================================
# CONTAINER IMAGE BUILDING
# ===============================================================================

print_header "CONTAINER IMAGE BUILDING"

print_progress "Building container images via ${COMPOSE_PROVIDER}..."
if [ "${CONTAINER_RUNTIME}" = "docker" ]; then
  COMPOSE_BAKE=true run_compose build
else
  run_compose build
fi
print_success "All container images built successfully"

# ===============================================================================
# COMPOSE DEPLOYMENT
# ===============================================================================

print_header "COMPOSE DEPLOYMENT"

print_progress "Starting services with ${COMPOSE_PROVIDER}..."
run_compose up -d --remove-orphans
print_success "All services started successfully"

# ===============================================================================
# SERVICE AVAILABILITY CHECK
# ===============================================================================

print_header "SERVICE AVAILABILITY CHECK"

print_progress "${CLOCK} Waiting for services to be ready..."
sleep 15 # Give some time for services to start

# Check if the VNC service is running
if run_compose ps remote-desktop | grep -q "Up"; then
  print_success "VNC service is running"
else
  print_warning "VNC service may not be running properly"
fi

# Check if the webapp service is running
if run_compose ps webapp | grep -q "Up"; then
  print_success "Webapp service is running"
else
  print_warning "Webapp service may not be running properly"
fi

# Check if the Nginx service is running
if run_compose ps nginx | grep -q "Up"; then
  print_success "Nginx service is running"
else
  print_warning "Nginx service may not be running properly"
fi

# Check if the jumphost service is running
if run_compose ps jumphost | grep -q "Up"; then
  print_success "Jump host service is running"
else
  print_warning "Jump host service may not be running properly"
fi

# Check if the Kubernetes cluster service is running
if run_compose ps k8s-api-server | grep -q "Up"; then
  print_success "Kubernetes cluster is running"
  
  # Wait for the K3D cluster to be fully ready
  print_progress "${CLOCK} Waiting for Kubernetes cluster to be fully initialized..."
  sleep 30
  
  # Check if cluster is accessible
  if run_compose exec k8s-api-server sh -lc "k3d cluster list | awk 'NR > 1 && \$1 == \"cluster\" {found=1} END {exit !found}'"; then
    print_success "K3D cluster is operational and accessible"
  else
    print_warning "K3D cluster may still be initializing"
  fi
else
  print_warning "Kubernetes cluster may not be running properly"
fi

# ===============================================================================
# DEPLOYMENT SUMMARY
# ===============================================================================

TOTAL_TIME=$(elapsed_time)

print_header 'DEPLOYMENT SUMMARY'
echo -e "${STAR} ${GREEN}Deployment completed successfully!${NC}"
echo -e "${INFO} ${CYAN}Environment:${NC}           CKAD Simulator (${COMPOSE_PROVIDER})"
echo -e "${INFO} ${CYAN}Services deployed:${NC}     8 (remote-desktop, webapp, nginx, jumphost, remote-terminal, k8s-api-server, redis, facilitator)"
echo -e "${INFO} ${CYAN}Total elapsed time:${NC}    ${YELLOW}${TOTAL_TIME}${NC}"

echo -e "\n${STAR} ${GREEN}Your CKAD simulator is ready to use!${NC} ${STAR}\n"

# ===============================================================================
# ACCESS INFORMATION
# ===============================================================================

print_header "ACCESS INFORMATION"

# Get the host IP address
HOST_IP=$(hostname -I | awk '{print $1}')
if [ -z "$HOST_IP" ]; then
  HOST_IP="localhost"
fi

echo -e "${CYAN}The following services are available:${NC}"
echo -e "\n${STAR} ${GREEN}Access Simulator here:${NC} ${BOLD}http://${HOST_IP}:30080${NC}"

# Open browser on host machine when possible
open_browser "http://${HOST_IP}:30080"
echo -e "${INFO} ${GRAY}Note: All other services (VNC, jumphost, K8s) are only accessible internally through the web application.${NC}"

# ===============================================================================
# HELPFUL COMMANDS
# ===============================================================================

print_header "HELPFUL COMMANDS"

echo -e "${CYAN}To stop the environment:${NC}"
echo -e "  ${GREEN}$(compose_display_cmd) down --volumes --remove-orphans${NC}"

echo -e "\n${CYAN}To restart the environment:${NC}"
echo -e "  ${GREEN}$(compose_display_cmd) restart${NC}"

echo -e "\n${CYAN}To view logs:${NC}"
echo -e "  ${GREEN}$(compose_display_cmd) logs -f${NC}"
