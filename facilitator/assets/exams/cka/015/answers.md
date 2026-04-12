# CKA 2026 Single Domain Drill - Logs and Resource Usage Triage

## Question 1: capture triage evidence and repair the multi-container workload

Capture the crashing sidecar evidence first, then repair the Deployment contract and export pod resource usage for the healthy pod.

```bash
mkdir -p /tmp/exam/q1
BROKEN_POD=""
for attempt in $(seq 1 30); do
  BROKEN_POD="$(kubectl get pods -n triage-lab -l app=ops-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [ -n "$BROKEN_POD" ] && kubectl logs "$BROKEN_POD" -n triage-lab -c log-agent --previous > /tmp/exam/q1/log-agent-previous.log 2>/dev/null; then
    break
  fi
  sleep 2
done

kubectl patch deployment ops-api -n triage-lab --type strategic -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "api",
            "ports": [{"containerPort": 80}],
            "resources": {
              "requests": {"cpu": "50m", "memory": "128Mi"},
              "limits": {"cpu": "100m", "memory": "256Mi"}
            },
            "livenessProbe": {
              "httpGet": {"path": "/", "port": 80},
              "initialDelaySeconds": 3,
              "periodSeconds": 3
            }
          },
          {
            "name": "log-agent",
            "env": [{"name": "LOG_TARGET", "value": "/var/log/ops/app.log"}]
          }
        ]
      }
    }
  }
}'

kubectl rollout status deployment/ops-api -n triage-lab

for attempt in $(seq 1 30); do
  POD_NAME="$(kubectl get pods -n triage-lab -l app=ops-api -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.deletionTimestamp}{"|"}{.status.phase}{"\n"}{end}' | awk -F'|' '$2=="" && $3=="Running" {print $1; exit}')"
  if [ -n "$POD_NAME" ] && kubectl top pod "$POD_NAME" -n triage-lab --containers > /tmp/exam/q1/ops-api-top.txt 2>/dev/null; then
    break
  fi
  sleep 2
done
```

The validator also checks that:

- `api` uses port `80`, memory limit `256Mi`, and a liveness probe on port `80`
- `log-agent` now uses `LOG_TARGET=/var/log/ops/app.log`
- `/tmp/exam/q1/log-agent-previous.log` contains the crashing sidecar evidence
- `/tmp/exam/q1/ops-api-top.txt` contains `kubectl top` output for the active pod and both containers
- the repaired Deployment becomes Available and the active `log-agent` stops restarting
