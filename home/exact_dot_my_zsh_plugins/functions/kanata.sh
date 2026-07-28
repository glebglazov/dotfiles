function kanata {
    # The Karabiner driver client prints "virtual_hid_keyboard_ready true" on every
    # daemon heartbeat. It bypasses kanata's logger, so no log flag silences it —
    # drop it here and keep everything else, including connect_failed diagnostics.
    zsh -i -l -c "cd ~/.config/kanata; eval \"sudo command kanata $*\"" \
        | grep --line-buffered -v '^virtual_hid_keyboard_ready '
}