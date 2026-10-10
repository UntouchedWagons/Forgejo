set default-list
set default-script
set no-exit-message
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

nodes := `talosctl config info --talosconfig ../talos/_out/talosconfig -o yaml | yq -r -e '.nodes | join (" ")'`

# Wait until every apiserver answers /readyz. Helm and kubectl calls after this stage are not retried.
# Shamelessly borrowed from onedr0p
[private]
wait-for-api:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    for n in {{ nodes }}; do
        until [[ "$(curl -ks -o /dev/null -w '%{http_code}' --connect-timeout 2 "https://${n}:6443/readyz")" == "200" ]]; do
            just log info "Waiting for kube-apiserver. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}" "node" "$n"
            sleep 5
        done
    done

go: wait-for-api sops crds apps

# [doc('Applies SOPS secret then bootstrap core apps')]
# go: wait-for-api sops flux-operator flux-instance

[private]
sops:
    sops -d secret.yaml | kubectl apply --kubeconfig ~/.kube/$(yq '.clusterName' ../talos/talstomize.yaml) -f -

[private]
crds:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! helmfile -f "{{ source_directory() }}/helmfile/crds.yaml" template -q | yq ea -r -e 'select(.kind == "CustomResourceDefinition")' | kubectl apply --kubeconfig ~/.kube/$(yq '.clusterName' ../talos/talstomize.yaml) --server-side --force-conflicts -f -; then
        just log fatal "Failed to apply base crds" "stage" "{{ recipe_name() }}"
    fi

[private]
apps:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! helmfile -f "{{ source_directory() }}/helmfile/apps.yaml" sync --hide-notes --kubeconfig ~/.kube/$(yq '.clusterName' ../talos/talstomize.yaml); then
        just log fatal "Failed to sync helmfile" "stage" "{{ recipe_name() }}"
    fi
