## Question 501: scheduler and controller-manager troubleshooting

Repair the control-plane recovery brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: component-repair-brief
  namespace: controlplane-lab
data:
  schedulerManifest: /etc/kubernetes/manifests/kube-scheduler.yaml
  controllerManagerManifest: /etc/kubernetes/manifests/kube-controller-manager.yaml
  schedulerHealthz: https://127.0.0.1:10259/healthz
  controllerManagerHealthz: https://127.0.0.1:10257/healthz
  schedulerKubeconfig: /etc/kubernetes/scheduler.conf
  controllerManagerKubeconfig: /etc/kubernetes/controller-manager.conf
  schedulerLogHint: journalctl -u kubelet | grep kube-scheduler
  controllerManagerLogHint: journalctl -u kubelet | grep kube-controller-manager
EOF_BRIEF

mkdir -p /tmp/exam/q501
cat <<'EOF_CHECKLIST' > /tmp/exam/q501/control-plane-checklist.txt
Scheduler
- inspect /etc/kubernetes/manifests/kube-scheduler.yaml
- confirm /etc/kubernetes/scheduler.conf
- curl -k https://127.0.0.1:10259/healthz
- journalctl -u kubelet | grep kube-scheduler

Controller Manager
- inspect /etc/kubernetes/manifests/kube-controller-manager.yaml
- confirm /etc/kubernetes/controller-manager.conf
- curl -k https://127.0.0.1:10257/healthz
- journalctl -u kubelet | grep kube-controller-manager

Verification
- kubectl get pods -n kube-system -l component=kube-scheduler
- kubectl get pods -n kube-system -l component=kube-controller-manager
- kubectl get --raw='/readyz?verbose'
EOF_CHECKLIST

kubectl get configmap component-repair-brief -n controlplane-lab -o yaml > /tmp/exam/q501/component-repair-brief.yaml
```

Expected checks:

- `component-repair-brief` contains the intended manifest paths, health endpoints, kubeconfig references, and safe log hints
- `/tmp/exam/q501/control-plane-checklist.txt` contains the required sections and exact troubleshooting commands
- `/tmp/exam/q501/component-repair-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting static pod manifests or restarting the kubelet are removed

## Question 502: service and pod connectivity diagnostics

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

mkdir -p /tmp/exam/q502
cat <<'EOF_MATRIX' > /tmp/exam/q502/connectivity-matrix.txt
Service Path
- kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz

Pod Path
- kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz

DNS Checks
- kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local
- kubectl get svc echo-api -n connectivity-lab
- kubectl get svc echo-api-headless -n connectivity-lab
EOF_MATRIX

kubectl get configmap connectivity-brief -n connectivity-lab -o yaml > /tmp/exam/q502/connectivity-brief.yaml
```

Expected checks:

- `connectivity-brief` contains the intended debug Pod, Service names, headless DNS name, and exact probe commands
- `/tmp/exam/q502/connectivity-matrix.txt` contains the required sections and exact service, pod, and DNS checks
- `/tmp/exam/q502/connectivity-brief.yaml` exports the repaired manifest
- stale unsafe actions such as deleting Services or restarting workloads are removed
