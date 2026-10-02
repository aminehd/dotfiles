# Every cluster in one list: ~/.kube/config plus any file in ~/.kube/config.d/.
# kubectl, helm, k9s and lfk all read KUBECONFIG, so they all see the same clusters.
mkdir -p ~/.kube/config.d
KUBECONFIG="$HOME/.kube/config"
for f in ~/.kube/config.d/*(N); do KUBECONFIG+=":$f"; done
export KUBECONFIG

alias lfr='lfk --read-only'
