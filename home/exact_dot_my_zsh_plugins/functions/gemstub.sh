# Stub/unstub local gem paths in .envrc
function gemstub {
    if [[ $# -lt 1 ]]; then
        echo "Usage: gemstub stub <gem-name> [<gem-name>...]"
        echo "       gemstub unstub"
        return 1
    fi

    local command=$1

    case $command in
        stub)
            if [[ $# -lt 2 ]]; then
                echo "Error: 'stub' command requires at least one gem name"
                return 1
            fi

            # Process each gem name
            for gem_name in "${@:2}"; do
                # Convert gem-name to GEM_NAME_PATH
                local env_var_name="${${gem_name:u}//-/_}_PATH"
                local gem_path=$TDS_PROJECTS_PATH/$gem_name
                local export_line="export $env_var_name=$gem_path"

                # Check if .envrc exists
                if [[ ! -f .envrc ]]; then
                    touch .envrc
                fi

                # Check if this variable already exists (uncommented)
                if grep -q "^export $env_var_name=" .envrc; then
                    echo "$env_var_name already stubbed in .envrc"
                else
                    # Check if it exists but is commented out
                    if grep -q "^# export $env_var_name=" .envrc; then
                        # Uncomment it
                        sed -i '' "s|^# export $env_var_name=.*|$export_line|" .envrc
                        echo "Uncommented $env_var_name in .envrc"
                    else
                        # Add new line
                        echo $export_line >> .envrc
                        echo "Added $env_var_name to .envrc"
                    fi
                fi
            done

            # Run direnv allow
            direnv allow
            echo "Ran 'direnv allow'"
            ;;

        unstub)
            # Comment out all *_PATH exports in .envrc
            if [[ -f .envrc ]]; then
                sed -i '' 's|^export \([A-Z_]*_PATH=.*\)|# export \1|' .envrc
                echo "Commented out all *_PATH variables in .envrc"
                direnv allow
                echo "Ran 'direnv allow'"
            else
                echo "No .envrc file found"
                return 1
            fi
            ;;

        *)
            echo "Unknown command: $command"
            echo "Usage: gemstub stub <gem-name> [<gem-name>...]"
            echo "       gemstub unstub"
            return 1
            ;;
    esac
}
