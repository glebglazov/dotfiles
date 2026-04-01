function op-signin {
    local account_shorthand="${1:-personal}"
    local token=$(op signin --account "$account_shorthand" --raw)

    local account_uuid=$(op account list --format=json | jq -r ".[] | select(.shorthand == \"$account_shorthand\") | .account_uuid")
    local user_uuid=$(op account list --format=json | jq -r ".[] | select(.shorthand == \"$account_shorthand\") | .user_uuid")

    export "OP_SESSION_$account_shorthand"="$token"
    export "OP_SESSION_$account_uuid"="$token"
    export "OP_SESSION_$user_uuid"="$token"
}