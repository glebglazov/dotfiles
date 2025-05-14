function _find_file_in_pwd_recursively
    if test (count $argv) -eq 0
        echo "Usage: find_in_parents FILENAME"
        return 1
    end

    set filename $argv[1]
    set current_dir (pwd)

    while true
        set found (find "$current_dir" -maxdepth 1 -name "$filename" 2>/dev/null)
        if test -n "$found"
            return 0
        end

        if test "$current_dir" = "/"
            break
        end

        set current_dir (dirname "$current_dir")
    end

    return 1
end
