#!/usr/bin/env -S just --justfile

set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
default:
    just -l

[doc('Applies SOPS secret then bootstrap core apps')]
go: sops flux-operator flux-instance

[doc('Apply SOPS secret')]
sops:
    sops -d kubernetes/secret.yaml | kubectl apply -f -

[doc('Install flux operator')]
flux-operator:
    helm upgrade --install flux-operator \
        --namespace flux-system \
        --create-namespace oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
        --version $(yq '.spec.ref.tag' kubernetes/apps/flux-system/flux-operator/app/OCIRepository.yaml)
    kubectl wait crd/fluxinstances.fluxcd.controlplane.io --for=condition=Established --timeout=2m

[doc('Bootstrap flux instance')]
flux-instance:
    helm upgrade --install --force-conflicts flux-instance \
        --namespace flux-system \
        --create-namespace oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance \
        --version $(yq '.spec.ref.tag' kubernetes/apps/flux-system/flux-instance/app/OCIRepository.yaml) \
        --set instance.sync.url=$(yq '.data.GIT_REPO_URL' kubernetes/settings/configMap.yaml) \
        --set instance.sync.ref=refs/heads/$(yq '.data.GIT_REPO_BRANCH' kubernetes/settings/configMap.yaml) \
        --set instance.sync.path=kubernetes/flux/cluster \
        --set instance.sync.interval=5m
