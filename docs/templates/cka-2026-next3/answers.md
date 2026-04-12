## Question 301: ConfigMap and Secret repair

Repair the `report-viewer` Deployment so it reads all runtime configuration from the intended ConfigMap and Secret.

```yaml
kubectl set env deployment/report-viewer -n config-lab APP_MODE- REPORT_USER- REPORT_PASS-

kubectl patch deployment report-viewer -n config-lab --type strategic -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "viewer",
            "env": [
              {
                "name": "APP_MODE",
                "valueFrom": {
                  "configMapKeyRef": {
                    "name": "report-config",
                    "key": "APP_MODE"
                  }
                }
              },
              {
                "name": "REPORT_USER",
                "valueFrom": {
                  "secretKeyRef": {
                    "name": "report-credentials",
                    "key": "username"
                  }
                }
              },
              {
                "name": "REPORT_PASS",
                "valueFrom": {
                  "secretKeyRef": {
                    "name": "report-credentials",
                    "key": "password"
                  }
                }
              }
            ]
          }
        ]
      }
    }
  }
}'
```

Expected checks:

- `APP_MODE` comes from ConfigMap `report-config` key `APP_MODE`
- `REPORT_USER` and `REPORT_PASS` come from Secret `report-credentials`
- no hardcoded replacement is used for the Secret-backed values
- the Deployment becomes Available

## Question 302: HPA troubleshooting

Repair the HPA and its workload resource contract.

```bash
kubectl set resources deployment worker-api -n autoscale-lab --containers=api --requests=cpu=200m

cat <<'EOF_HPA' | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: worker-api-hpa
  namespace: autoscale-lab
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: worker-api
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
EOF_HPA

mkdir -p /tmp/exam/q302
kubectl get hpa worker-api-hpa -n autoscale-lab -o yaml > /tmp/exam/q302/worker-api-hpa.yaml
```

Expected checks:

- the HPA targets Deployment `worker-api`
- the HPA uses `minReplicas=2`, `maxReplicas=5`, and CPU utilization target `60`
- the `api` container has CPU request `200m`
- the repaired manifest is exported to `/tmp/exam/q302/worker-api-hpa.yaml`

## Question 303: Node troubleshooting and maintenance

Find the node labeled `maintenance-lab=target`, return it to service, and confirm the workload can run there again.

```bash
TARGET_NODE="$(kubectl get nodes -l maintenance-lab=target -o jsonpath='{.items[0].metadata.name}')"
kubectl uncordon "$TARGET_NODE"
kubectl rollout status deployment/queue-consumer -n node-lab
mkdir -p /tmp/exam/q303
kubectl get node "$TARGET_NODE" -o wide > /tmp/exam/q303/node-status.txt
```

Expected checks:

- the maintenance target node is schedulable again
- the target node remains labeled `maintenance-lab=target`
- `queue-consumer` becomes Running on that labeled node
- `/tmp/exam/q303/node-status.txt` contains the target node status output
