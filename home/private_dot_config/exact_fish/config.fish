set -a fish_function_path ~/private/.config/fish/functions
set fish_greeting

source $__fish_config_dir/env.fish

function fish_prompt
    # Save the status of the last command
    set -l last_status $transient_status

    # Get the current working directory
    set -l cwd (pwd | sed "s|$HOME|~|")

    # Extract the last part of the path
    set -l last_part (basename $cwd)

    # Get the parent path (everything except the last part)
    set -l parent_path (dirname $cwd)

    # Handle special cases for paths
    if test "$cwd" = "/"
        # For root directory - special case where we want to display everything in regular blue
        set parent_path "∅ /"
        set last_part ""      # Empty to avoid bright blue formatting for root
    else if test "$cwd" = "~"
        # For home directory
        set parent_path ""
        set last_part "~"
    else if string match -q "/*" $cwd
        # Add ∅ symbol for any absolute path starting with /
        # When parent is root, don't add extra slash
        if test "$parent_path" = "/"
            set parent_path "∅ /"
        else
            # For directories under root but not directly in root
            set parent_path "∅ $parent_path/"
        end
    else
        # Add trailing slash to parent path for normal cases
        set parent_path "$parent_path/"
    end

    # Make tilde bold in parent path
    if string match -q "*~*" "$parent_path"
        # Split the path at the tilde
        set -l parts (string split "~" "$parent_path" -m 1)

        # Display the part before tilde in custom blue
        set_color "#0089AE"
        echo -n "$parts[1]"

        # Display the tilde in bold custom LIGHTER blue (same as last_part)
        set_color --bold "#00B1FB"
        echo -n "~"

        # Continue with the rest of the parent path in regular blue
        set_color normal
        set_color "#0089AE"
        if test (count $parts) -gt 1
            echo -n "$parts[2]"
        end
    else
        # Display the parent path in custom blue (#0089AE)
        set_color "#0089AE"
        echo -n "$parent_path"
    end

    # Special handling for last part if it contains tilde
    if string match -q "*~*" "$last_part"
        # Split the path at the tilde
        set -l parts (string split "~" "$last_part" -m 1)

        # Display the part before tilde
        set_color --bold "#00B1FB"
        echo -n "$parts[1]"

        # Display the tilde in bold lighter blue
        set_color --bold "#00B1FB"
        echo -n "~"

        # Continue with the rest of the last part
        if test (count $parts) -gt 1
            echo -n "$parts[2]"
        end
        echo -n " "
    else
        # Display the last part of the path in bold custom lighter blue (#00B1FB)
        set_color --bold "#00B1FB"
        echo -n "$last_part "
    end

    # Display the prompt symbol in custom green (#17D900) or red (#FF0B0C) based on last command status
    if test $last_status -eq 0
        set_color "#17D900"  # Success: green
    else
        set_color "#FF0B0C"  # Failure: red
    end
    echo -n "❯ "

    # Reset colors
    set_color normal
end
