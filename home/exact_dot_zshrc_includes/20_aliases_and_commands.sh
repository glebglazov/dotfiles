alias vim="nvim"
alias tf="terraform"
alias ide="tmux-ide-layout"
alias git="git-wrapper"

function __aws_envrc_path_cd {
    [ -v AWS_ENVRC_PATH ] && cd $AWS_ENVRC_PATH
}

function t {
    tmux new -A -s main
}

function cha {
    chezmoi apply $@
}

function aws {
    (__aws_envrc_path_cd; command aws "$@")
}

function kubectl {
    (__aws_envrc_path_cd; command kubectl "$@")
}

function cdp {
    sesh list -z | fzf-tmux -p 55%,60% \
      --no-sort --border-label " sesh " --prompt "⚡  " \
      --bind "enter:execute-silent(tmux send-keys -t $TMUX_PANE 'cd {} && clear' C-m)+abort"
}

function docker-login {
    docker-login-ecr
}


function git-clone-to-folder {
    remote=$(git-ssh-repo-name-from-any-link $1)
    branch=$(git ls-remote --symref "git@github.com:$remote" HEAD | head -1 | awk '{print $2}' | cut -d/ -f3)

    git init
    git remote add origin "git@github.com:$remote"
    git pull origin $branch
}

function find-pid-by-port {
	pid=$1

	lsof -i tcp:$pid | tail -1 | awk '{print $2}'
}

function newrelic {
    # As RTX prepends path and newrelic_rpm gem has a binstub of "newrelic" in bin/ path
    # I've decided to use direct alias to target homebrew folder
    $BREW_PREFIX/newrelic-cli/bin/newrelic "$@"
}

function r-edit-credentials {
    env_name=$1

    RAILS_MASTER_KEY="op://$OP_RAILS_MASTER_KEY_BASE/$env_name" op run -- rails credentials:edit --environment $env_name
}

function get-my-public-ip {
    dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com
}
