# CKA 2026 Single Domain Drill - HPA Troubleshooting

## Question 1: repair the autoscaling contract

Repair the HPA and its workload resource contract for `worker-api` in namespace `autoscale-lab`.

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

mkdir -p /tmp/exam/q1
kubectl get hpa worker-api-hpa -n autoscale-lab -o yaml > /tmp/exam/q1/worker-api-hpa.yaml
```

The validator also checks that:

- the HPA targets Deployment `worker-api`
- the HPA uses `minReplicas=2`, `maxReplicas=5`, and CPU utilization target `60`
- the `api` container has CPU request `200m`
- the repaired manifest is exported to `/tmp/exam/q1/worker-api-hpa.yaml`
