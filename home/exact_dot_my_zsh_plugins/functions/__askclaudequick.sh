function __askclaudequick {
    if [ $# -eq 0 ]; then
        echo "Usage: ?? <prompt>"
        echo "       ?? --resume <session_id> <prompt>"
        return 1
    fi

    local claude_args=(--model haiku -p --output-format stream-json --verbose --include-partial-messages)
    local session_id
    local jq_filter='select(.type == "stream_event" and .event.delta.type? == "text_delta") | .event.delta.text'

    __askclaudequick_stream() {
        claude "${@}" 2>/dev/null | jq -rj "$jq_filter"
        echo ""
    }

    if [ "$1" = "--resume" ]; then
        shift
        session_id="$1"
        shift
        __askclaudequick_stream "${claude_args[@]}" --resume "$session_id" "$*"
    else
        session_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
        __askclaudequick_stream "${claude_args[@]}" --session-id "$session_id" "$*"
    fi

    while true; do
        echo ""
        printf ">> "
        read -r followup

        if [ -z "$followup" ]; then
            break
        fi

        __askclaudequick_stream "${claude_args[@]}" --resume "$session_id" "$followup"
    done

    unfunction __askclaudequick_stream 2>/dev/null

    echo ""
    echo "Resume this session with:"
    echo "  claude --resume $session_id"
    echo "or"
    echo "  ?? --resume $session_id"
}
