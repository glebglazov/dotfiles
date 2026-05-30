function codex {
    if [[ -n "${TMUX_PANE:-}" ]] && command -v pop-status >/dev/null 2>&1; then
        pop-status idle codex
    fi

    command codex "$@"
}
