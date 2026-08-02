function kanata {
    # --enable-logs is ours, not kanata's; everything else passes through untouched.
    local -a args
    local log=/dev/null arg
    for arg in "$@"; do
        if [[ $arg == --enable-logs ]]; then
            local log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/kanata"
            mkdir -p "$log_dir"
            log="$log_dir/$(date +%Y%m%d-%H%M%S).log"

            # Keep the last 10 runs; `om` orders newest first, so [11,-1] is the tail.
            local -a old=("$log_dir"/[0-9]*.log(Nom[11,-1]))
            (( $#old )) && rm -f "${old[@]}"

            ln -sfn "$log" "$log_dir/latest.log"
            print -u2 "kanata: logging to $log"
        else
            args+=("$arg")
        fi
    done

    # The Karabiner driver client prints "virtual_hid_keyboard_ready true" on every
    # daemon heartbeat. It bypasses kanata's logger, so no log flag silences it —
    # drop it from the terminal, but let the log file keep everything.
    zsh -i -l -c 'cd ~/.config/kanata; sudo command kanata "$@" 2>&1' kanata "${args[@]}" \
        | tee "$log" \
        | grep --line-buffered -v '^virtual_hid_keyboard_ready '
}
