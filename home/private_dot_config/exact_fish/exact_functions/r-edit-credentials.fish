function r-edit-credentials
    env_name=$argv[1]

    RAILS_MASTER_KEY="op://$OP_RAILS_MASTER_KEY_BASE/$env_name" op run -- _be_wrap rails credentials:edit --environment $env_name
end
