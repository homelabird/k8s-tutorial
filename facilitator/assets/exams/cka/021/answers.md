# CKA 2026 Single Domain Drill - Service Exposure and Endpoint Debugging

## Question 1: repair the service exposure brief and export the evidence

Repair the service exposure debugging brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-exposure-brief
  namespace: service-debug-lab
data:
  serviceName: echo-api
  serviceType: ClusterIP
  selectorKey: app
  selectorValue: echo-api
  servicePort: "8080"
  targetPort: "8080"
  endpointCheck: kubectl get endpoints echo-api -n service-debug-lab -o wide
  selectorCheck: kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.selector.app}'
  reachabilityCheck: kubectl exec -n service-debug-lab net-debug -- wget -qO- http://echo-api:8080/healthz
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/service-exposure-checklist.txt
Selector Audit
- kubectl get svc echo-api -n service-debug-lab -o yaml
- kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.selector.app}'

Endpoint Audit
- kubectl get endpoints echo-api -n service-debug-lab -o wide
- kubectl get endpointslices -n service-debug-lab -l kubernetes.io/service-name=echo-api

Reachability
- kubectl exec -n service-debug-lab net-debug -- wget -qO- http://echo-api:8080/healthz
- kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.ports[0].targetPort}'
EOF_CHECKLIST

kubectl get configmap service-exposure-brief -n service-debug-lab -o yaml > /tmp/exam/q1/service-exposure-brief.yaml
```

Expected checks:

- `service-exposure-brief` contains the intended Service name, selector contract, ports, and exact endpoint and reachability checks
- `/tmp/exam/q1/service-exposure-checklist.txt` contains the required sections and exact selector, endpoint, and reachability commands
- `/tmp/exam/q1/service-exposure-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting Services, patching Deployments, or creating Ingress resources are removed
