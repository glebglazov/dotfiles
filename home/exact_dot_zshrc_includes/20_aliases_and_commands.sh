alias vim="nvim"
alias ide="tmux-ide-layout"

function __aws_envrc_path_cd {
    [ -v AWS_ENVRC_PATH ] && cd $AWS_ENVRC_PATH
}

function aws {
    (__aws_envrc_path_cd; command aws "$@")
}

function kubectl {
    (__aws_envrc_path_cd; command kubectl "$@")
}

function docker-login-ecr {
    (__aws_envrc_path_cd; aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 412041701469.dkr.ecr.us-east-1.amazonaws.com)
}

function docker-login {
    docker-login-ecr
}

function update-kubectl-context {
    for c in $(aws eks list-clusters | jq -r '.clusters | .[]'); do aws eks update-kubeconfig --name $c; done
}

function git-clone-to-folder {
    remote=$1
    branch=${2:-master}

    git init
    git remote add origin "git@github.com:$remote"
    git pull origin master
}

function pid-by-port {
	pid=$1

	lsof -i tcp:$pid | tail -1 | awk '{print $2}'
}

function r-edit-credentials {
    env_name=$1

    RAILS_MASTER_KEY="op://$OP_RAILS_MASTER_KEY_BASE/$env_name" op run -- rails credentials:edit --environment $env_name
}

function get-my-public-ip {
    dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com
}
