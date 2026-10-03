---
name: deploy-verify
description: Use right after a deploy, rollout, helm upgrade or image change, to prove the NEW version is the one running and healthy.
---

An old pod can keep serving and hide a broken new one. Check the new one explicitly.

1. `kubectl rollout status deploy/<name> -n <ns> --timeout=180s`
2. List pods newest first: `kubectl get pods -n <ns> -l <selector> --sort-by=.metadata.creationTimestamp`
   The newest pod must be Running, READY n/n, and RESTARTS 0.
3. Confirm its image is the new one:
   `kubectl get pod <newest> -n <ns> -o jsonpath='{.spec.containers[*].image}'`
4. Read the newest pod's logs (every container, with `-c`). Look for errors at startup.
5. Wait 30-60 seconds and check RESTARTS again. A crash loop can look fine at first.
6. Hit it once: a real request (port-forward plus curl) or its health endpoint.

Report each step's result. Only call it deployed when all six pass.
