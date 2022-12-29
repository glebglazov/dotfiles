#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/Dev ~/.local/share -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected")
window_index=$(tmux list-windows  -F '#I #W' | awk "\$2 ~ /$selected_name/ { print \$1 }")

if [[ -z $window_index ]]; then
    tmux new-window -n $selected_name -c $selected
else
    tmux select-window -t $window_index
fi
