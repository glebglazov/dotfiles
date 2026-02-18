function cdp {
    tmux display-popup -E -w 60% -h 60% "pop select --tmux-cd $TMUX_PANE --no-history"
}
