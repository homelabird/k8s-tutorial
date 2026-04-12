## Question 401: Gateway API traffic management

Repair the Gateway API contract in `gateway-lab` without recreating the backend workloads.

```bash
cat <<'EOF_GATEWAY' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: cka-014-gc
spec:
  controllerName: example.com/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: main-gateway
  namespace: gateway-lab
spec:
  gatewayClassName: cka-014-gc
  listeners:
  - name: http
    port: 80
    protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: app-routes
  namespace: gateway-lab
spec:
  hostnames:
  - apps.example.local
  parentRefs:
  - name: main-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /app1
    backendRefs:
    - name: app1-svc
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /app2
    backendRefs:
    - name: app2-svc
      port: 8080
EOF_GATEWAY

mkdir -p /tmp/exam/q401
kubectl get httproute app-routes -n gateway-lab -o yaml > /tmp/exam/q401/app-routes.yaml
```

Expected checks:

- `GatewayClass` `cka-014-gc` exists and uses controller `example.com/gateway-controller`
- `Gateway` `main-gateway` listens on HTTP port `80` and uses GatewayClass `cka-014-gc`
- `HTTPRoute` `app-routes` attaches to `main-gateway`
- `/app1` routes to `app1-svc:8080` and `/app2` routes to `app2-svc:8080`
- no `/legacy` route remains
- backend Deployments and Services stay ready
- the repaired manifest is exported to `/tmp/exam/q401/app-routes.yaml`

## Question 402: logs and resource usage triage

Capture the crashing sidecar evidence first, then repair the Deployment contract and export pod resource usage for the healthy pod.

```bash
mkdir -p /tmp/exam/q402
BROKEN_POD=""
for attempt in $(seq 1 30); do
  BROKEN_POD="$(kubectl get pods -n triage-lab -l app=ops-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [ -n "$BROKEN_POD" ] && kubectl logs "$BROKEN_POD" -n triage-lab -c log-agent --previous > /tmp/exam/q402/log-agent-previous.log 2>/dev/null; then
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
  if [ -n "$POD_NAME" ] && kubectl top pod "$POD_NAME" -n triage-lab --containers > /tmp/exam/q402/ops-api-top.txt 2>/dev/null; then
    break
  fi
  sleep 2
done
```

Expected checks:

- `api` uses port `80`, memory limit `256Mi`, and a liveness probe on port `80`
- `log-agent` now uses `LOG_TARGET=/var/log/ops/app.log`
- `/tmp/exam/q402/log-agent-previous.log` contains the crashing sidecar evidence
- `/tmp/exam/q402/ops-api-top.txt` contains `kubectl top` output for the active pod and both containers
- the repaired Deployment becomes Available and the active `log-agent` stops restarting
