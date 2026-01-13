function _askclaudequick {
    if [ $# -eq 0 ]; then
        echo "Usage: ?? <prompt>"
        return 1
    fi

    local prompt="$*"

    claude -p "$prompt"

    while true; do
        echo ""
        printf ">> "
        read -r followup

        if [ -z "$followup" ]; then
            break
        fi

        claude --model sonnet -p --continue "$followup"
    done
}
