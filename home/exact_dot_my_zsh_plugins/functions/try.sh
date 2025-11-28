function try {
    unset -f try
    eval "$(~/.local/bin/try.rb init ~/Dev/tries)"
    try "$@"
}
