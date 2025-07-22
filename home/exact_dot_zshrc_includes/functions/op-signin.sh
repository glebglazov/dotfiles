function op-signin {
    local account_shorthand="$1"
    local user_id=$(op account list | grep "$account_shorthand" | awk '{print $4}')

    local token=$(op signin --account "$user_id" --raw)
    export "OP_SESSION_$user_id"="$token"

    local account_id=$(op account get | grep "ID" | awk '{print $2}')
    export "OP_SESSION_$account_id"="$token"
}