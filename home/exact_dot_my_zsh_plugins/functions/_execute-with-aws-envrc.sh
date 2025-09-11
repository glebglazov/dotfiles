function _execute-with-aws-envrc {
    zsh -i -l -c "_cd-to-aws-envrc; eval \"\$*\"" -- "$@"
}