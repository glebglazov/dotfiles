alias vim="nvim"
alias tf="terraform"
alias ide="tmux-ide-layout"
alias git="git-wrapper"

# Source all functions
for func_file in "${0:h}/functions/"*.sh; do
    source "$func_file"
done
