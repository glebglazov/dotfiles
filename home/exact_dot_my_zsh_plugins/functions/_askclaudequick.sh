function _askclaudequick {
    if [ $# -eq 0 ]; then
        echo "Usage: ?? <prompt>"
        echo "       ?? --resume <session_id> <prompt>"
        return 1
    fi

    local claude_args=(--model haiku -p)
    local session_id

    if [ "$1" = "--resume" ]; then
        shift
        session_id="$1"
        shift
        claude "${claude_args[@]}" --resume "$session_id" "$*"
    else
        session_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
        claude "${claude_args[@]}" --session-id "$session_id" "$*"
    fi

    while true; do
        echo ""
        printf ">> "
        read -r followup

        if [ -z "$followup" ]; then
            break
        fi

        claude "${claude_args[@]}" --resume "$session_id" "$followup"
    done

    echo ""
    echo "?? --resume $session_id"
}
