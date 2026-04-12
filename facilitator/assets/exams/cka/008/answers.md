# CKA 2026 Single Domain Drill - Scheduling Constraints

## Question 1: scheduling with taints, tolerations, and node targeting

The existing Deployment `metrics-agent` in namespace `scheduling-lab` must be updated so it runs only on the ops node pool.

```bash
kubectl patch deployment metrics-agent -n scheduling-lab --type merge -p '{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": {
          "workload": "ops"
        },
        "tolerations": [
          {
            "key": "dedicated",
            "operator": "Equal",
            "value": "ops",
            "effect": "NoSchedule"
          }
        ]
      }
    }
  }
}'

kubectl rollout status deployment metrics-agent -n scheduling-lab
```

The validator also checks that:

- the Deployment tolerates `dedicated=ops:NoSchedule`
- the Deployment targets nodes labeled `workload=ops`
- the running Pod stays on the intended ops node pool rather than a broader general pool
