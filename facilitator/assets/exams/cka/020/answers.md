# CKA 2026 Single Domain Drill - Service and Pod Connectivity Diagnostics

## Question 1: repair the connectivity diagnostics brief and export the evidence

Repair the connectivity diagnostics brief and export both the repaired manifest and a plain-text connectivity matrix.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: connectivity-brief
  namespace: connectivity-lab
data:
  debugPod: net-debug
  serviceName: echo-api
  servicePort: "8080"
  headlessServiceName: echo-api-headless
  podDnsName: echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local
  serviceProbe: kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz
  podProbe: kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz
  dnsProbe: kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local
EOF_BRIEF

mkdir -p /tmp/exam/q1
cat <<'EOF_MATRIX' > /tmp/exam/q1/connectivity-matrix.txt
Service Path
- kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz

Pod Path
- kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz

DNS Checks
- kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local
- kubectl get svc echo-api -n connectivity-lab
- kubectl get svc echo-api-headless -n connectivity-lab
EOF_MATRIX

kubectl get configmap connectivity-brief -n connectivity-lab -o yaml > /tmp/exam/q1/connectivity-brief.yaml
```

Expected checks:

- `connectivity-brief` contains the intended debug Pod, Service names, headless DNS name, and exact probe commands
- `/tmp/exam/q1/connectivity-matrix.txt` contains the required sections and exact service, pod, and DNS checks
- `/tmp/exam/q1/connectivity-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting Services or restarting workloads are removed
