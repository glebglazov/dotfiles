function _websearch {
    if [ $# -eq 0 ]; then
        echo "Usage: ? <search query>"
        return 1
    fi

    local query=$(echo "$*" | sed 's/ /+/g')
    w3m -o accept_encoding=identity "https://duckduckgo.com/?q=${query}"
}
