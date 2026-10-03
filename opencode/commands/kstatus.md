---
description: Quick health of the current cluster (read-only)
agent: k8s
---
Here is the current cluster state:

Context: !`kubectl config current-context`
Nodes: !`kubectl get nodes -o wide 2>&1 | head -20`
Pods that are not healthy: !`kubectl get pods -A --no-headers 2>&1 | grep -vE 'Running|Completed' | head -30`
Recent warnings: !`kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp 2>&1 | tail -15`

Summarize in a few lines: which cluster, is it healthy, and the top problem if any.
For each problem, say the next command you would run to dig in. $ARGUMENTS
