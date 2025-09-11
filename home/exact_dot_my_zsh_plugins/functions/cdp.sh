function cdp {
    sesh list -z | fzf-tmux -p 55%,60% \
      --no-sort --border-label " sesh " --prompt "⚡  " \
      --bind "enter:execute-silent(tmux send-keys -t $TMUX_PANE 'cd {} && clear' C-m)+abort"
}