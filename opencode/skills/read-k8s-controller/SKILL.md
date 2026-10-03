---
name: read-k8s-controller
description: Use to read or change a Go Kubernetes controller or operator (kubebuilder / controller-runtime). Maps the repo layout and explains the Reconcile loop.
---

Where things live in a kubebuilder project:
- `api/<version>/*_types.go`: the Go structs for the custom resources (Spec, Status).
  The CRD YAML is generated from these by controller-gen (`make manifests`). Edit the Go, not the YAML.
- `internal/controller/*_controller.go` (or `controllers/`): one Reconciler per type.
- `cmd/main.go`: builds the scheme (`AddToScheme`), creates the manager, registers reconcilers.
- `config/` or the Helm chart: CRDs, RBAC (`//+kubebuilder:rbac` markers), the controller Deployment.

How to read a Reconcile function:
1. Get the object. If not found, it was deleted: return without error.
2. Deletion: is `DeletionTimestamp` set? Then finalizer cleanup, then remove the finalizer.
3. Compare desired (spec) with actual (look up the child objects it owns).
4. Create or update what is missing, with `controllerutil.SetControllerReference` so children
   get garbage-collected with the parent.
5. Write conditions into status with `r.Status().Update` (never into spec).
6. Return `ctrl.Result{RequeueAfter: ...}` to check again later, or an error to retry with backoff.

Rules when changing one: Reconcile must be safe to run many times (idempotent), must not keep state
in memory, and must only write status from the controller. Add new RBAC markers when you touch
new kinds, then regenerate manifests. Run the unit tests (envtest) before saying done.
