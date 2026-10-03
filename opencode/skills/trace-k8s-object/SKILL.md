---
name: trace-k8s-object
description: Use to find who or what created a Kubernetes object and which code reconciles it, especially custom resources (CRDs) that no YAML file creates.
---

1. Read the object with its field owners:
   `kubectl get <kind> <name> -n <ns> -o yaml --show-managed-fields`
   - `metadata.managedFields[].manager` names the program that wrote each part.
     Usually one manager writes `spec` (the creator) and another writes `status` (the controller).
   - `metadata.ownerReferences` points to the parent object, if any.
   - `metadata.labels` and `annotations` are fingerprints of the creating code.
2. Learn the type: `kubectl explain <kind>.spec` and `kubectl get crd <plural>.<group> -o yaml`.
3. Find the creator in code: search the repo for a distinctive label key or value
   (`rg -n '"<label-key>"'`) and for where the type is built and passed to `Create(`.
4. Find the controller: search for a condition reason or type from `.status.conditions`
   (`rg -n '<ReasonName>'`). That code is inside the controller's Reconcile.
5. Explain the chain: who creates it -> the API server stores it -> which controller wakes up
   -> what it creates next (Jobs, PVCs, Deployments) -> what it writes back in status.
