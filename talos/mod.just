set default-list
set default-script
set no-exit-message
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

controller := `yq '.nodes | to_entries | .[0] | select(.value.kind == "controlplane") | .key' talstomize.yaml`
nodes := `yq '.nodes | to_entries | [.[] | select(.value.kind == "controlplane") | .key] | join(" ")' talstomize.yaml`

[doc('Generate and encrypt a new secrets file')]
secret:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if [[ -e "talos-secrets.yaml" ]]; then
        just log error "talos-secrets.yaml already exists" "stage" "{{ recipe_name() }}"
        exit
    fi
    talosctl gen secrets -o talos-secrets.yaml
    sops -e --in-place talos-secrets.yaml

[doc('Delete and remake base files (excluding secrets)')]
prep: clean build
    just log info "Running stage..." "stage" "{{ recipe_name() }}"

[doc('apply, bootstrap, kubeconfig')]
go: apply bootstrap kubeconfig
    just log info "Running stage..." "stage" "{{ recipe_name() }}"

[doc('Delete any generated files')]
clean:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    rm -Rf _out

[doc('Build node files and configure talosconfig')]
build:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    talstomize build .
    talosctl config --talosconfig _out/talosconfig endpoint {{ controller }}
    talosctl config --talosconfig _out/talosconfig node {{ nodes }}

[doc('Applies generated configs to all nodes')]
apply:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    talstomize apply -f . -- --insecure

# Shamelessly borrowed from onedr0p
[doc('Bootstraps the cluster, keeps trying until successful')]
bootstrap:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    until op=$(talosctl --talosconfig _out/talosconfig -n "{{ controller }}" bootstrap 2>&1 || true) && [[ "$op" == *"AlreadyExists"* ]]; do
        just log info "Kubernetes bootstrap in progress. Retrying in 10 seconds..." "stage" "{{ recipe_name() }}"
        sleep 10
    done

[doc('Generate kubeconfig')]
kubeconfig:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    talosctl kubeconfig --talosconfig _out/talosconfig --force ~/.kube/$(yq '.clusterName' talstomize.yaml)
