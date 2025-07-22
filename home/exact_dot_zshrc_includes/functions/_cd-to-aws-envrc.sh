function _cd-to-aws-envrc {
    [[ -v AWS_ENVRC_PATH ]] && cd "$AWS_ENVRC_PATH" && direnv reload
}