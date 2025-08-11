function r-edit-credentials {
    local env_name="$1"

    RAILS_MASTER_KEY="op://$OP_RAILS_MASTER_KEY_BASE/$env_name" op run -- zsh -ic "_be_wrap rails credentials:edit --environment '$env_name'"
}
