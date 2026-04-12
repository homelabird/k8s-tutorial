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
