function fish_prompt
    # Get the current working directory
    set -l cwd (pwd | sed "s|$HOME|~|")

    # Extract the last part of the path
    set -l last_part (basename $cwd)

    # Get the parent path (everything except the last part)
    set -l parent_path (dirname $cwd)

    # Handle special cases for paths
    if test "$cwd" = "/"
        # For root directory
        set parent_path ""
        set last_part "∅ /"
    else if test "$cwd" = "~"
        # For home directory
        set parent_path ""
        set last_part "~"
    else if test "$parent_path" = "/"
        # When parent is root, don't add extra slash
        set parent_path "∅ /"
    else
        # Add trailing slash to parent path for normal cases
        set parent_path "$parent_path/"
    end

    # Display the parent path in custom blue (#0089AE)
    set_color "#0089AE"
    echo -n "$parent_path"

    # Display the last part of the path in bold custom lighter blue (#00B1FB)
    set_color --bold "#00B1FB"
    echo -n "$last_part "

    # Display the prompt symbol in custom green (#17D900)
    set_color "#17D900"
    echo -n "❯ "

    # Reset colors
    set_color normal
end
