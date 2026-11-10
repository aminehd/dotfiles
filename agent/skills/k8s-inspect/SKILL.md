---
name: k8s-inspect
description: Use when something in a Kubernetes cluster is broken or unclear (pod not ready, CrashLoopBackOff, Pending, 5xx from a service). A fixed read-only investigation order from context to logs.
---

Investigate in this order. Stop as soon as you find the cause, and explain it.

1. Context: `kubectl config current-context`. Say which cluster.
2. The object: `kubectl get <kind> <name> -n <ns> -o wide`. Read STATUS, READY, RESTARTS, AGE.
3. Describe: `kubectl describe <kind> <name> -n <ns>`. Read **Conditions** and **Events** at the bottom first.
4. Events around it: `kubectl events -n <ns> --for <kind>/<name>`
   (older kubectl: `kubectl get events -n <ns> --sort-by=.lastTimestamp`).
5. Logs: `kubectl logs <pod> -n <ns> -c <container> --tail=100`. If it restarted, add `--previous`.
   Pods with sidecars or init containers need `-c`; list them with
   `kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.initContainers[*].name} {.spec.containers[*].name}'`.
6. Walk the ownership chain up and down:
   up: `kubectl get <kind> <name> -n <ns> -o jsonpath='{.metadata.ownerReferences}'`
   down: find children by the owner's labels (`kubectl get pods -n <ns> -l <selector>`).
7. Common causes to check:
   - Pending: no node fits (resources, taints/tolerations, GPU), or PVC not Bound.
   - ImagePullBackOff: wrong image/tag or missing pull secret in that namespace.
   - CrashLoopBackOff: app error (logs --previous), bad config, failing probe.
   - Init stuck: the init container waits for a dependency (DB, schema). Look at its logs.
   - Service has no endpoints: selector labels do not match pod labels
     (`kubectl get endpointslices -n <ns> -l kubernetes.io/service-name=<svc>`).

Finish with: the cause, the evidence (command + the line that proves it), and the fix as a command
or YAML for me to run. Do not change anything yourself.
