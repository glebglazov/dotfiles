function _find_file_in_pwd_recursively {
    if [[ $# -eq 0 ]]; then
        echo "Usage: _find_file_in_pwd_recursively FILENAME"
        return 1
    fi

    local filename="$1"
    local current_dir="$(pwd)"

    while true; do
        local found=$(find "$current_dir" -maxdepth 1 -name "$filename" 2>/dev/null)
        if [[ -n "$found" ]]; then
            return 0
        fi

        if [[ "$current_dir" == "/" ]]; then
            break
        fi

        current_dir=$(dirname "$current_dir")
    done

    return 1
}