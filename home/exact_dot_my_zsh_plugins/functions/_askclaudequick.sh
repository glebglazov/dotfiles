function _askclaudequick {
    if [ $# -eq 0 ]; then
        echo "Usage: ?? <prompt>"
        return 1
    fi

    local prompt="$*"
    local session_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local claude_args=(--model haiku -p)

    claude "${claude_args[@]}" --session-id "$session_id" "$prompt"

    while true; do
        echo ""
        printf ">> "
        read -r followup

        if [ -z "$followup" ]; then
            break
        fi

        claude "${claude_args[@]}" --resume "$session_id" "$followup"
    done
}
