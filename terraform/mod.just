set default-list
set default-script
set no-exit-message
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

[doc('Initialize Terraform')]
init:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    terraform init

[doc('Check the Terraform plan')]
plan:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    terraform plan

[doc('Apply the Terraform plan')]
apply:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    terraform apply --auto-approve
