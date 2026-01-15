function dev {
    local cmds="$1"
    shift

    for cmd in $(echo "$cmds" | grep -o .); do
        case "$cmd" in
            r)
                devcontainer up --workspace-folder . --remove-existing-container "$@" || return 1
                ;;
            u)
                devcontainer up --workspace-folder . "$@" || return 1
                ;;
            x)
                devcontainer exec --workspace-folder . "$@"
                return $?
                ;;
            *)
                devcontainer "$cmd" "$@"
                return $?
                ;;
        esac
    done
}
