function timeshell
    set shell $argv[1]
    if test -z "$shell"
        set shell $SHELL
    end

    for i in (seq 1 10)
        time $shell -i -c exit
    end
end
