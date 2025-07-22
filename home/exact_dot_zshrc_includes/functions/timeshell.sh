function timeshell {
    local shell="$1"
    if [[ -z "$shell" ]]; then
        shell="$SHELL"
    fi

    for i in {1..10}; do
        time "$shell" -i -c exit
    done
}