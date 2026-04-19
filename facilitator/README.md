# Facilitator Service

A Node.js service that provides SSH jumphost functionality and exam management capabilities via a REST API.

## Features

- Execute commands on a remote SSH jumphost
- Support for both password and passwordless SSH authentication
- Manage a single active exam lifecycle from creation through evaluation and cleanup
- Secure and modular architecture
- Comprehensive logging
- Containerization with Docker or Podman
- Integration with Docker Compose or Podman Compose for multi-service deployment

## Prerequisites

- Node.js 18+
- npm or yarn
- SSH access to the target jumphost

## Installation

### Local Development

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:

```bash
npm install
```

4. Create a `.env` file based on the provided example:

```
PORT=3000
NODE_ENV=development

# SSH Jumphost Configuration
SSH_HOST=<your-ssh-host>
SSH_PORT=22
SSH_USERNAME=<your-ssh-username>
SSH_PASSWORD=<your-ssh-password>
# Alternatively, use SSH key authentication
# SSH_PRIVATE_KEY_PATH=/path/to/private/key

# Logging Configuration
LOG_LEVEL=info
```

5. Start the development server:

```bash
npm run dev
```

6. Run the unit tests:

```bash
npm test
```

### Docker Deployment

#### Standalone

1. Build the Docker image:

```bash
docker build -t facilitator-service .
```

2. Run the container:

```bash
docker run -p 3001:3000 --env-file .env facilitator-service
```

#### Compose Stack

The facilitator service is integrated into the main compose configuration at the project root. To run it with the full stack:

```bash
cd ..
./compose-deploy.sh
# or
docker compose up -d
# or, for Podman on Linux
sudo podman compose -f docker-compose.yaml -f docker-compose.podman.yaml up -d --build --force-recreate
```

This will start the facilitator service along with all other services, including the jumphost that the facilitator connects to for SSH command execution. In the compose stack, the service is configured to use passwordless SSH authentication with the jumphost.

On Podman, the inner `k3d` exam cluster is created when an exam is prepared, not when the stack first starts.

The service is accessible at:
- URL: http://localhost:3001
- Internal network name: facilitator

## API Endpoints

### SSH Command Execution

- **POST /api/v1/execute**
  - Execute a command on the SSH jumphost
  - Request body: `{ "command": "your-command-here" }`
  - Response: `{ "exitCode": 0, "stdout": "output", "stderr": "errors" }`

### Exam Management

- **POST /api/v1/exams/**
  - Create a new exam from `examId` or an explicit `assetPath`
  - Example body: `{ "examId": "ckad-003" }`
  - Returns `201` with `{ "id": "...", "status": "CREATED", "message": "Exam created successfully and environment preparation started" }`
  - Only one exam can be active at a time; creating another exam while one is active returns `409`

- **GET /api/v1/exams/current**
  - Get the active exam with resolved metadata and environment plan
  - Returns `404` when no exam is active

- **GET /api/v1/exams/:examId/status**
  - Get the exam lifecycle status
  - Typical states include `CREATED`, `PREPARING`, `READY`, `EVALUATING`, `EVALUATED`, and `COMPLETED`

- **GET /api/v1/exams/:examId/assets**
  - Download the exam asset bundle as `assets.tar.gz`

- **GET /api/v1/exams/:examId/questions**
  - Get the exam questions enriched with the resolved `machineHostname` and `environmentId`

- **GET /api/v1/exams/:examId/answers**
  - Download the answers file configured for the exam

- **POST /api/v1/exams/:examId/evaluate**
  - Evaluate an exam
  - Starts asynchronous evaluation on the jumphost
  - Returns `{ "examId": "...", "status": "EVALUATING", "message": "Exam evaluation started" }`

- **GET /api/v1/exams/:examId/result**
  - Get the persisted evaluation result
  - Returns `{ "success": true, "data": { "examId": "...", "status": "EVALUATED", "totalScore": ..., "totalPossibleScore": ..., "percentageScore": ..., "rank": "...", "evaluationResults": [...] } }`

- **POST /api/v1/exams/:examId/terminate**
  - End the active exam and trigger jumphost cleanup
  - Returns `{ "examId": "...", "status": "COMPLETED", "message": "Exam completed successfully" }`

- **POST /api/v1/exams/:examId/events**
  - Merge client-side lifecycle or UX events into the stored exam metadata
  - Request body: `{ "events": { ... } }`

- **POST /api/v1/exams/metrics/:examId**
  - Submit feedback metrics for an exam session

## Example Flow

```bash
# Create an exam
curl -sS -X POST http://localhost:3001/api/v1/exams/ \
  -H 'Content-Type: application/json' \
  -d '{"examId":"ckad-003"}'

# Poll until READY
curl -sS http://localhost:3001/api/v1/exams/<exam-id>/status

# Evaluate and fetch the result
curl -sS -X POST http://localhost:3001/api/v1/exams/<exam-id>/evaluate -H 'Content-Type: application/json' -d '{}'
curl -sS http://localhost:3001/api/v1/exams/<exam-id>/result

# Clean up the active exam
curl -sS -X POST http://localhost:3001/api/v1/exams/<exam-id>/terminate
```

## Verification

Run the facilitator unit tests locally:

```bash
cd facilitator
npm install
npm test
```

The current unit suite covers:

- app-level API wiring such as `409` active-exam conflicts, generic `500` creation failures, JSON parsing, and result passthrough
- service-level lifecycle edges such as async preparation lock release, async evaluation failure fallback to `EVALUATION_FAILED`, and cleanup failure preservation of active exam metadata
- Redis TTL defaults and request validation guards for exam event payloads

From the project root, you can also run the Podman-backed smoke test that creates, evaluates, and cleans up a `ckad-003` exam:

```bash
./scripts/verify/ckad-003-podman-smoke.sh
```

For the CKA 2026 regression suites, use the project-root verify runner:

```bash
./scripts/verify/run-cka-2026-regressions.sh
```

The current single-domain CKA 2026 drills exposed by the facilitator are:

- `cka-004` cluster DNS recovery
- `cka-006` RBAC least privilege
- `cka-007` Deployment rollout and rollback
- `cka-008` scheduling constraints
- `cka-009` NetworkPolicy troubleshooting
- `cka-010` persistent storage troubleshooting
- `cka-011` ConfigMap and Secret repair
- `cka-012` HPA troubleshooting
- `cka-013` node troubleshooting and maintenance
- `cka-014` Gateway API traffic management
- `cka-015` logs and resource usage triage
- `cka-016` kubeadm lifecycle planning
- `cka-017` CRD and operator installation checks
- `cka-018` etcd backup and restore workflow
- `cka-019` scheduler and controller-manager troubleshooting
- `cka-020` service and pod connectivity diagnostics
- `cka-021` service exposure and endpoint debugging
- `cka-022` kubelet and node NotReady troubleshooting
- `cka-023` PKI and certificate expiry troubleshooting
- `cka-024` resource quota and LimitRange troubleshooting
- `cka-025` container runtime and CRI endpoint diagnostics
- `cka-026` StorageClass and dynamic provisioning diagnostics
- `cka-027` PodDisruptionBudget and drain planning
- `cka-028` StatefulSet identity and headless service diagnostics
- `cka-029` DaemonSet rollout and node coverage diagnostics
- `cka-030` CronJob schedule, suspend, and history diagnostics
- `cka-031` Job completions, parallelism, and backoff diagnostics
- `cka-032` readiness, liveness, and startupProbe diagnostics
- `cka-033` initContainer and shared volume diagnostics
- `cka-034` pod anti-affinity and topology spread diagnostics
- `cka-035` ServiceAccount identity and projected token diagnostics
- `cka-036` Pod securityContext and fsGroup diagnostics
- `cka-037` PriorityClass and preemption diagnostics
- `cka-038` Pod resource requests, limits, and QoS diagnostics
- `cka-039` ServiceAccount imagePullSecrets and private registry diagnostics
- `cka-040` PersistentVolume reclaim policy and claimRef diagnostics
- `cka-041` PersistentVolumeClaim expansion and resize diagnostics
- `cka-042` Ephemeral containers and kubectl debug diagnostics
- `cka-043` Static pod manifest repair
- `cka-044` Projected ConfigMap and Secret volume diagnostics
- `cka-045` ConfigMap and Secret envFrom diagnostics
- `cka-046` ConfigMap subPath mount troubleshooting
- `cka-047` ReadWriteOncePod workload repair
- `cka-048` Pod DNS policy repair
- `cka-049` Lifecycle hooks and graceful termination repair
- `cka-050` Downward API env wiring repair
- `cka-051` Taints, tolerations, and NoExecute scheduling repair

To check the runner wiring without starting the Podman stack:

```bash
./scripts/verify/run-cka-2026-regressions.sh --list
```

## License

ISC 
