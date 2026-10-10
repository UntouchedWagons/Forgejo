set default-list
set default-script
set no-exit-message
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
flux-operator:
    helm upgrade --install flux-operator \
        --namespace flux-system \
        --create-namespace oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
        --version $(yq '.spec.ref.tag' ../kubernetes/apps/flux-system/flux-operator/app/OCIRepository.yaml) \
        --kubeconfig ~/.kube/$(yq '.clusterName' ../talos/talstomize.yaml)
    kubectl wait crd/fluxinstances.fluxcd.controlplane.io --for=condition=Established --timeout=2m --kubeconfig ~/.kube/$(yq '.clusterName' ../talos/talstomize.yaml)

[private]
flux-instance:
    helm upgrade --install --force-conflicts flux-instance \
        --namespace flux-system \
        --create-namespace oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance \
        --version $(yq '.spec.ref.tag' ../kubernetes/apps/flux-system/flux-instance/app/OCIRepository.yaml) \
        --set instance.sync.url=$(yq '.data.GIT_REPO_URL' ../kubernetes/settings/configMap.yaml) \
        --set instance.sync.ref=refs/heads/$(yq '.data.GIT_REPO_BRANCH' ../kubernetes/settings/configMap.yaml) \
        --set instance.sync.path=kubernetes/flux/cluster \
        --set instance.sync.interval=5m \
        --kubeconfig ~/.kube/$(yq '.clusterName' ../talos/talstomize.yaml)

flux: flux-operator flux-instance
