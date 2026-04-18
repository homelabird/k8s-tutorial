# Local Setup Guide for CK-X Simulator

## Quick Setup

1. Clone the repository:
```bash
git clone https://github.com/nishanb/CK-X.git
cd CK-X
```

2. Run the deployment script:
```bash
./compose-deploy.sh
```

Alternatively,

2. Use `docker compose up -d` or `sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml up -d --build --force-recreate` and manually navigate to `http://localhost:30080` in your browser

The script will deploy all services locally and open the application in your browser.

If you use Podman on Linux, use rootful Podman for CK-X because the `jumphost` and `k8s-api-server` services run privileged nested-container workloads.
`./compose-deploy.sh` automatically adds the Podman override file when Podman is detected.

After the stack is up, the internal `k3d` exam cluster is created on demand when you start an exam. Seeing only the long-lived runtime containers after deployment is expected.

After making any changes to the code, you can redeploy with:
```bash
docker compose up -d
# or
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml up -d --build --force-recreate
```

To run the Podman smoke check for the single-question CKAD flow:
```bash
./scripts/verify/ckad-003-podman-smoke.sh
```

To run the full local CKA 2026 regression sweep:

```bash
./scripts/verify/run-cka-2026-regressions.sh
```

If you only need to confirm the regression entrypoint wiring without restarting the stack:

```bash
./scripts/verify/run-cka-2026-regressions.sh --list
```

To override the aggregated runner timeout for slower hosts:

```bash
SUITE_TIMEOUT_SECONDS=3000 ./scripts/verify/run-cka-2026-regressions.sh
```

To collect the same diagnostics bundle used by the self-hosted regression workflow:

```bash
./scripts/verify/collect-cka-2026-diagnostics.sh
```

The matching GitHub Actions workflow is `.github/workflows/cka-2026-regressions.yml`. It is designed for a Linux self-hosted runner with Podman and privileged containers enabled.

For a smaller nightly sample across the promoted single-domain drills, inspect the lane inventory with:

```bash
./scripts/verify/cka-2026-single-domain-inventory.sh --nightly-describe
```

The matching self-hosted workflow is `.github/workflows/cka-2026-single-domain-nightly.yml`. It runs a balanced lane matrix with `max-parallel: 1` so fixed-port Podman resources do not collide on the same runner host.

This setup has been tested on Mac and Linux environments. 
