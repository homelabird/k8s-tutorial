#!/usr/bin/env bash
set -euo pipefail

QOS_CLASS="$(kubectl get pods -n qos-lab -l app=reporting-api -o jsonpath='{.items[0].status.qosClass}')"
[ "${QOS_CLASS}" = "Guaranteed" ] || { echo "The running Pod must report QoS class Guaranteed"; exit 1; }

echo "The running Pod reports QoS class Guaranteed"
