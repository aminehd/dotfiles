---
name: read-helm-chart
description: Use to understand a Helm chart or debug what it installs. Renders it locally without a cluster and explains templates, values, hooks and subcharts.
---

1. Layout: `Chart.yaml` (name, version, dependencies), `values.yaml` (defaults), `templates/`,
   `charts/` (subcharts), and any profile or platform values files.
2. Render without a cluster: `helm template <release> <chart-dir> -n <ns> > /tmp/out.yaml`.
   Count what it makes: `grep '^kind:' /tmp/out.yaml | sort | uniq -c | sort -rn`.
3. To see what a value changes, render twice and diff:
   `helm template ... -f extra-values.yaml > /tmp/out2.yaml && diff /tmp/out.yaml /tmp/out2.yaml`.
4. To find the template behind an object: `rg -n 'name: <object-name>' <chart-dir>/templates`.
5. Values order: chart values.yaml, then each `-f` file in order, then `--set`. Later wins.
6. Hooks: `rg -n 'helm.sh/hook' <chart-dir>/templates`. Lower `hook-weight` runs first.
   Failed hook Jobs stay in the cluster so you can read their logs.
7. `lookup` in a template reads the live cluster. `helm template` has no cluster, so those parts
   render empty. Mention it when output looks incomplete.
8. On a cluster (read-only): `helm list -A`, `helm get values <rel> -n <ns> --all`,
   `helm history <rel> -n <ns>`, `helm get manifest <rel> -n <ns>`.
