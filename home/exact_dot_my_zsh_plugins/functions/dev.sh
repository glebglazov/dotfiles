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
                if [ $# -eq 0 ]; then
                    devcontainer exec --workspace-folder . bash
                else
                    devcontainer exec --workspace-folder . "$@"
                fi
                return $?
                ;;
            *)
                devcontainer "$cmd" "$@"
                return $?
                ;;
        esac
    done
}
