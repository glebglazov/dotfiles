function __cd_to_aws_envrc {
    [[ -v AWS_ENVRC_PATH ]] && cd "$AWS_ENVRC_PATH" && direnv reload
}