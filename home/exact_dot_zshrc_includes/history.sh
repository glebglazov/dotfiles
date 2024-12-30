# Source:
# https://www.reddit.com/r/zsh/comments/y06ugg/read_history_from_multiple_files_but_write_only/

HISTFILE=${ZDOTDIR:-~}/.zsh_history.${(%):-%m}

() {
  emulate -L zsh -o extended_glob
  local hist
  for hist in ~/.zsh_history.*~$HISTFILE(N); do
    fc -RI -- $hist
  done
}
