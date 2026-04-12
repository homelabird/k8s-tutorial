## Question 1301: Readiness, liveness, and startupProbe diagnostics

Repair the probe diagnostics brief and export both the repaired manifest and a plain-text checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-diagnostics-brief
  namespace: probe-lab
data:
  targetDeployment: health-api
  deploymentInventory: kubectl get deployment health-api -n probe-lab -o wide
  startupProbeCheck: kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}'
  livenessProbeCheck: kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}'
  readinessProbeCheck: kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}'
  portCheck: kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'
  eventCheck: kubectl get events -n probe-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm startup, liveness, readiness probe paths and thresholds before changing the Deployment manifest
EOF_BRIEF

mkdir -p /tmp/exam/q1301
cat <<'EOF_CHECKLIST' > /tmp/exam/q1301/probe-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment health-api -n probe-lab -o wide
- kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'

Probe Checks
- kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}'
- kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}'
- kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}'
- kubectl get events -n probe-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment health-api -n probe-lab -o yaml
- confirm startup, liveness, readiness probe paths and thresholds before changing the Deployment manifest
EOF_CHECKLIST

kubectl get configmap probe-diagnostics-brief -n probe-lab -o yaml > /tmp/exam/q1301/probe-diagnostics-brief.yaml
```

Expected checks:

- `probe-diagnostics-brief` contains the intended Deployment target, exact probe inspection commands, events check, and safe manifest guidance
- `/tmp/exam/q1301/probe-diagnostics-checklist.txt` contains the required sections and exact deployment inventory and probe troubleshooting commands
- `/tmp/exam/q1301/probe-diagnostics-brief.yaml` exports the repaired manifest
- stale unsafe actions such as restarting the Deployment, deleting pods, or patching the live probe fields are removed
