---
description: Render and explain a Helm chart without a cluster. Usage: /chart <path-to-chart>
agent: teach
---
Use the read-helm-chart skill on the chart at `$ARGUMENTS`. Render it with `helm template`,
count the kinds, and explain what it installs and which values matter most.
