set default-list
set default-script
set no-exit-message
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

nodes := `talosctl config info --talosconfig ../talos/_out/talosconfig -o yaml | yq -r -e '.nodes | join (" ")'`

# Wait until every apiserver answers /readyz. Helm and kubectl calls after this stage are not retried.
# Shamelessly borrowed from onedr0p
[doc('Wait for the kube api to be ready on every control node')]
wait-for-api:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    for n in {{ nodes }}; do
        until [[ "$(curl -ks -o /dev/null -w '%{http_code}' --connect-timeout 2 "https://${n}:6443/readyz")" == "200" ]]; do
            just log info "Waiting for kube-apiserver. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}" "node" "$n"
            sleep 5
        done
    done

[doc('Applies SOPS secret then bootstrap core apps')]
go: wait-for-api sops flux-operator flux-instance

[doc('Apply SOPS secret')]
sops:
    sops -d secret.yaml | kubectl apply -f -

[doc('Install flux operator')]
flux-operator:
    helm upgrade --install flux-operator \
        --namespace flux-system \
        --create-namespace oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
        --version $(yq '.spec.ref.tag' ../kubernetes/apps/flux-system/flux-operator/app/OCIRepository.yaml)
    kubectl wait crd/fluxinstances.fluxcd.controlplane.io --for=condition=Established --timeout=2m

[doc('Bootstrap flux instance')]
flux-instance:
    helm upgrade --install --force-conflicts flux-instance \
        --namespace flux-system \
        --create-namespace oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance \
        --version $(yq '.spec.ref.tag' ../kubernetes/apps/flux-system/flux-instance/app/OCIRepository.yaml) \
        --set instance.sync.url=$(yq '.data.GIT_REPO_URL' ../kubernetes/settings/configMap.yaml) \
        --set instance.sync.ref=refs/heads/$(yq '.data.GIT_REPO_BRANCH' ../kubernetes/settings/configMap.yaml) \
        --set instance.sync.path=kubernetes/flux/cluster \
        --set instance.sync.interval=5m
