function op-signin {
    local account_shorthand="${1:-personal}"
    local token=$(op signin --account "$account_shorthand" --raw)

    export "OP_SESSION_$account_shorthand"="$token"
}