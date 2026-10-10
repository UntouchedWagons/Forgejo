#!/usr/bin/env -S just --justfile

set minimum-version := '1.55.0'

set default-list
set default-script
set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

# Bootstrap Recipes
[group('Bootstrap')]
mod bootstrap "bootstrap"

# Kube Recipes
[group('Kube')]
mod kube "kubernetes"

# Talos Recipes
[group('Talos')]
mod talos "talos"

go:
    just talos go
    just bootstrap go

[private]
zfs node disk:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    kubectl debug \
        --kubeconfig ~/.kube/$(yq '.clusterName' talos/talstomize.yaml) \
        "node/{{ node }}" \
        -n kube-system \
        --image=busybox:1.36 \
        --profile=sysadmin \
        -it \
        -- \
        chroot /host \
        zpool create \
        -m legacy \
        -O compression=on \
        -O atime=off \
        zfspv-pool \
        {{ disk }}

[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}
