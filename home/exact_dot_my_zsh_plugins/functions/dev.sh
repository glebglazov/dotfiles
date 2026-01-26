function dev {
    # Handle --init option
    if [ "$1" = "--init" ]; then
        if [ -d ".devcontainer" ]; then
            echo -n ".devcontainer already exists. Overwrite? [y/N] "
            read -r answer
            if [[ ! "$answer" =~ ^[Yy]$ ]]; then
                echo "Aborted."
                return 1
            fi
        fi

        local project_name=$(basename "$(pwd)")
        local template_dir="$HOME/.local/share/glebglazov/dev.sh/templates"

        mkdir -p .devcontainer

        sed "s/__PROJECT_NAME__/${project_name}/g" "$template_dir/devcontainer.json" > .devcontainer/devcontainer.json

        cp "$template_dir/post-create.sh" .devcontainer/post-create.sh
        chmod +x .devcontainer/post-create.sh

        echo "Initialized .devcontainer/ for '$project_name'"
        echo "  - Edit .devcontainer/devcontainer.json to customize image and features"
        echo "  - Edit .devcontainer/post-create.sh to add project-specific setup"
        return 0
    fi

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

    # No cmds: exec in container, starting it first if needed
    if [ -z "$cmds" ]; then
        # Check if container is running first
        if ! devcontainer exec --workspace-folder . true 2>/dev/null; then
            devcontainer up --workspace-folder . || return 1
        fi
        if [ ${#exec_cmd[@]} -eq 0 ]; then
            devcontainer exec --workspace-folder . bash
        else
            devcontainer exec --workspace-folder . "${exec_cmd[@]}"
        fi
        return $?
    fi

    for cmd in $(echo "$cmds" | grep -o .); do
        case "$cmd" in
            o)
                open "http://$DEVCONTAINER_DOMAIN:3000"
                ;;
            r)
                devcontainer exec --workspace-folder . .devcontainer/post-create.sh
                ;;
            R)
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
