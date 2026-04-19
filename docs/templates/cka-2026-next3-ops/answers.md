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

## Question 502: service and pod connectivity repair

One valid repair flow is:

```bash
kubectl apply -n connectivity-lab -f - <<'EOF_SERVICE'
apiVersion: v1
kind: Service
metadata:
  name: echo-api
spec:
  selector:
    app: echo-api
  ports:
    - port: 8080
      targetPort: 8080
EOF_SERVICE

kubectl apply -n connectivity-lab -f - <<'EOF_HEADLESS'
apiVersion: v1
kind: Service
metadata:
  name: echo-api-headless
spec:
  clusterIP: None
  selector:
    app: echo-api
  ports:
    - port: 8080
      targetPort: 8080
EOF_HEADLESS

kubectl rollout status statefulset/echo-api -n connectivity-lab
kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local
kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz
kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz
```

Expected checks:

- Services `echo-api` and `echo-api-headless` use the intended selectors and ports
- StatefulSet `echo-api` stays Ready with `serviceName: echo-api-headless`
- `net-debug` resolves the Service name and fetches `ok` through both the ClusterIP and headless ordinal DNS paths

## Question 503: service exposure and endpoint repair

One valid repair flow is:

```bash
kubectl apply -n service-debug-lab -f - <<'EOF_SERVICE'
apiVersion: v1
kind: Service
metadata:
  name: echo-api
spec:
  type: ClusterIP
  selector:
    app: echo-api
  ports:
    - port: 8080
      targetPort: 8080
EOF_SERVICE

kubectl rollout status deployment/echo-api -n service-debug-lab
kubectl get endpoints echo-api -n service-debug-lab -o wide
kubectl exec -n service-debug-lab net-debug -- wget -qO- http://echo-api:8080/healthz
```

Expected checks:

- Service `echo-api` uses the intended type, selector, and port wiring
- Deployment `echo-api` stays Available and Service `echo-api` publishes two ready endpoints
- `net-debug` fetches `ok` through `http://echo-api:8080/healthz`
