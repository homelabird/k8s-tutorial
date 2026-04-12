# CKA 2026 Single Domain Drill - Node Troubleshooting and Maintenance

## Question 1: return the maintenance node to service

Find the node labeled `maintenance-lab=target`, return it to service, and confirm the workload can run there again.

```bash
TARGET_NODE="$(kubectl get nodes -l maintenance-lab=target -o jsonpath='{.items[0].metadata.name}')"
kubectl uncordon "$TARGET_NODE"
kubectl rollout status deployment/queue-consumer -n node-lab
mkdir -p /tmp/exam/q1
kubectl get node "$TARGET_NODE" -o wide > /tmp/exam/q1/node-status.txt
```

The validator also checks that:

- the maintenance target node is schedulable again
- the target node remains labeled `maintenance-lab=target`
- `queue-consumer` becomes Running on that labeled node
- `/tmp/exam/q1/node-status.txt` contains the recovered node status
