#!/bin/bash
set -euo pipefail

NAMESPACE="kubeadm-lab"
CONFIGMAP="upgrade-brief"

TARGET_VERSION="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data.targetVersion}')"
ENDPOINT="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data.controlPlaneEndpoint}')"
PLAN_COMMAND="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data.planCommand}')"
APPLY_COMMAND="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data.applyCommand}')"
DRAIN_COMMAND="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data.drainCommand}')"
UNCORDON_COMMAND="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data.uncordonCommand}')"
BACKUP_PATHS="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath='{.data.backupPaths}')"

[ "$TARGET_VERSION" = "v1.31.8" ] || { echo "targetVersion must be v1.31.8"; exit 1; }
[ "$ENDPOINT" = "k8s-api-server:6443" ] || { echo "controlPlaneEndpoint must be k8s-api-server:6443"; exit 1; }
[ "$PLAN_COMMAND" = "kubeadm upgrade plan v1.31.8" ] || { echo "planCommand is incorrect"; exit 1; }
[ "$APPLY_COMMAND" = "kubeadm upgrade apply v1.31.8 -y" ] || { echo "applyCommand is incorrect"; exit 1; }
[ "$DRAIN_COMMAND" = "kubectl drain cp-maint-0 --ignore-daemonsets --delete-emptydir-data" ] || { echo "drainCommand is incorrect"; exit 1; }
[ "$UNCORDON_COMMAND" = "kubectl uncordon cp-maint-0" ] || { echo "uncordonCommand is incorrect"; exit 1; }
[ "$BACKUP_PATHS" = "/etc/kubernetes/admin.conf,/etc/kubernetes/pki,/var/lib/etcd" ] || { echo "backupPaths must include admin.conf, pki, and etcd"; exit 1; }

echo "Upgrade brief ConfigMap contract is repaired"
