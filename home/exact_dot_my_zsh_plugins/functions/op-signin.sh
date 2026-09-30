function op-signin {
    local account_shorthand="${1:-personal}"

    # Accounts that come from the 1Password desktop app have no shorthand,
    # so resolve the name to the sign-in address, which op accepts everywhere.
    local account_address account_email
    case "$account_shorthand" in
        personal) account_address="my.1password.com"; account_email="glazov.gleb@gmail.com" ;;
        work) account_address="tripledotstudios.1password.eu"; account_email="gleb.glazov@tripledotstudios.com" ;;
        *) echo "op-signin: unknown account \"$account_shorthand\" (use personal or work)" >&2; return 1 ;;
    esac

    # On macOS, op otherwise signs in through the desktop app with Touch ID.
    # With the app integration off, the password prompt stays in the terminal,
    # but op sees only the accounts added with `op account add` in this mode.
    local account=$(OP_BIOMETRIC_UNLOCK_ENABLED=false op account list --format=json | jq -c --arg address "$account_address" '.[] | select(.url | ltrimstr("https://") == $address)')
    if [[ -z "$account" ]]; then
        echo "op-signin: add the account first:" >&2
        echo "  OP_BIOMETRIC_UNLOCK_ENABLED=false op account add --address $account_address --email $account_email --shorthand $account_shorthand" >&2
        return 1
    fi

    local token
    token=$(OP_BIOMETRIC_UNLOCK_ENABLED=false op signin --account "$account_address" --raw) || return 1

    # Later op and op-cache calls in this shell use the token, not Touch ID.
    export OP_BIOMETRIC_UNLOCK_ENABLED=false
    export "OP_SESSION_$account_shorthand"="$token"
    export "OP_SESSION_$(jq -r .account_uuid <<< "$account")"="$token"
    export "OP_SESSION_$(jq -r .user_uuid <<< "$account")"="$token"
}
