function __execute_with_aws_envrc {
    zsh -i -l -c '__cd_to_aws_envrc; __op_run "$@"' -- "$@"
}
