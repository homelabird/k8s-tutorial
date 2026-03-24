# CK-X Simulator Deployment Guide

This guide provides instructions for deploying the CK-X Simulator on different operating systems.

## Prerequisites

- Docker Desktop / Docker Engine with Docker Compose v2, or Podman with `podman compose` / `podman-compose`
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space
- Internet connection
- Port 30080 available

Linux Podman deployments should currently use rootful Podman because `jumphost` and `k8s-api-server` require privileged containers.
The repository includes `docker-compose.podman.yaml` for Podman rootful compatibility, but `k3d` still runs on the inner Docker daemon inside `k8s-api-server`.
When Podman is selected, use `sudo` and expect a local image build so the Podman-specific compatibility overrides are present.

## Quick Install

### Linux & macOS

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/nishanb/CK-X/master/scripts/install.sh | bash
```

or, if the current user does not have the permission to run docker commands:

```bash
curl -fsSL https://raw.githubusercontent.com/nishanb/CK-X/master/scripts/install.sh | sudo bash
```

For Podman on Linux, prefer the `sudo` form so the install runs against rootful Podman.

### Windows

Open PowerShell as Administrator and run:

```powershell
irm https://raw.githubusercontent.com/nishanb/CK-X/master/scripts/install.ps1 | iex
```

## Manual Installation

# By cloning the repository

1. Clone the repository:
   ```bash
   git clone https://github.com/nishanb/CK-X.git
   cd CK-X
   ```

2. Build and start the services using your compose provider:
   ```bash
   docker compose up -d
   # or
   sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml up -d --build
   ```

### Via Script 

If you prefer to install manually or the quick install doesn't work:

1. Download the installation script:
   - Linux/macOS: [install.sh](https://raw.githubusercontent.com/nishanb/CK-X/master/scripts/install.sh)
   - Windows: [install.ps1](https://raw.githubusercontent.com/nishanb/CK-X/master/scripts/install.ps1)

2. Run the script:
   - Linux/macOS:
     ```bash
     chmod +x install.sh
     ./install.sh
     ```
   - Windows (in PowerShell as Administrator):
     ```powershell
     .\install.ps1
     ```

## Post-Installation

After successful installation, you can access CK-X Simulator at:
```
http://localhost:30080
```

## Managing CK-X Simulator

### Start Services
```bash
docker compose up -d
# or
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml up -d --build
```

### Stop Services
```bash
docker compose down
# or
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml down
```

### View Logs
```bash
docker compose logs -f
# or
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml logs -f
```

### Update
```bash
docker compose pull
docker compose up -d
# or
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml build
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml up -d
```

## Troubleshooting

### Common Issues

1. **Port 30080 Already in Use**
   - Check what's using the port: 
     - Windows: `netstat -ano | findstr :30080`
     - Linux/Mac: `lsof -i :30080`
   - Stop the conflicting service or change the port in docker-compose.yml

2. **Container Runtime Not Running**
   - Docker on Windows/Mac: Start Docker Desktop
   - Docker on Linux: `sudo systemctl start docker`
   - Podman on Linux: ensure the rootful Podman service/socket is available for your setup and run CK-X commands with `sudo`

3. **Permission Issues**
   - Windows: Run PowerShell as Administrator
   - Linux: Add user to docker group or use sudo

4. **Services Not Starting**
   - Check logs: `docker compose logs -f` or `sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml logs -f`
   - Ensure sufficient system resources

### Getting Help

If you encounter issues:
1. Check the logs: `docker compose logs -f` or `sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml logs -f`
2. Visit our [GitHub Issues](https://github.com/nishanb/CK-X/issues)
3. Contact support with logs and system information

## Uninstallation

To completely remove CK-X Simulator:

```bash
# Stop and remove containers
docker compose down
# or
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml down

# Remove downloaded files
cd ..
rm -rf ck-x-simulator
```
