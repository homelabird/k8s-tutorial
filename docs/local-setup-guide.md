# Local Setup Guide for CK-X Simulator

## Quick Setup

1. Clone the repository:
```bash
git clone https://github.com/nishanb/CK-X.git
cd CK-X
```

2. Run the deployment script:
```bash
./scripts/compose-deploy.sh
```

Alternatively,

2. Use `docker compose up -d` or `sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml up -d --build` and manually navigate to `http://localhost:30080` in your browser

The script will deploy all services locally and open the application in your browser.

If you use Podman on Linux, use rootful Podman for CK-X because the `jumphost` and `k8s-api-server` services run privileged nested-container workloads.
`./scripts/compose-deploy.sh` automatically adds the Podman override file when Podman is detected.

After making any changes to the code, you can redeploy with:
```bash
docker compose up -d
# or
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml up -d --build
```

This setup has been tested on Mac and Linux environments. 
