function dev {
    local cmds=""
    local exec_cmd=()

    # Parse: [cmds] [-- exec_cmd...]
    # If first arg is "--", skip cmd string and use remaining as exec command
    if [ "$1" = "--" ]; then
        shift
        exec_cmd=("$@")
    elif [ -n "$1" ]; then
        cmds="$1"
        shift
        if [ "$1" = "--" ]; then
            shift
            exec_cmd=("$@")
        fi
    fi

    # No cmds: try x, if fails try ux
    if [ -z "$cmds" ]; then
        if [ ${#exec_cmd[@]} -eq 0 ]; then
            devcontainer exec --workspace-folder . bash 2>/dev/null || {
                devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . bash
            }
        else
            devcontainer exec --workspace-folder . "${exec_cmd[@]}" 2>/dev/null || {
                devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . "${exec_cmd[@]}"
            }
        fi
        return $?
    fi

    for cmd in $(echo "$cmds" | grep -o .); do
        case "$cmd" in
            o)
                open "http://$DEVCONTAINER_DOMAIN:3000"
                ;;
            r)
                echo -n "Reset will remove existing container. Continue? [y/N] "
                read -r answer
                if [[ "$answer" =~ ^[Yy]$ ]]; then
                    devcontainer up --workspace-folder . --remove-existing-container || return 1
                else
                    echo "Reset skipped."
                fi
                ;;
            u)
                devcontainer up --workspace-folder . || return 1
                ;;
            v)
                devcontainer exec --workspace-folder . bin/vite dev
                return $?
                ;;
            s)
                devcontainer exec --workspace-folder . bundle exec rails s
                return $?
                ;;
            c)
                devcontainer exec --workspace-folder . claude --dangerously-skip-permissions
                return $?
                ;;
            x)
                if [ ${#exec_cmd[@]} -eq 0 ]; then
                    devcontainer exec --workspace-folder . bash
                else
                    devcontainer exec --workspace-folder . "${exec_cmd[@]}"
                fi
                return $?
                ;;
            *)
                devcontainer "$cmd"
                return $?
                ;;
        esac
    done
}
