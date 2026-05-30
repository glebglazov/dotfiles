function codex {
    if [[ -n "${TMUX_PANE:-}" ]] && command -v pop-status >/dev/null 2>&1; then
        pop-status clear codex
    fi

    command codex "$@"
}
