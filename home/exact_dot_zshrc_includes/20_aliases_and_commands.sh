alias vim="nvim"
alias ide="tmux-ide-layout"

# All functions below are functions and not aliases just because of the fact
# that this way we're not breaking original auto-completion

function bundle {
    op run --no-masking -- command bundle "$@"
}

function gh {
    op run --no-masking -- command gh "$@"
}

function yarn {
    op run --no-masking -- command yarn "$@"
}

function bun {
    op run --no-masking -- command bun "$@"
}

function pnpm {
    op run --no-masking -- command pnpm "$@"
}

function terraform {
    if [[ -v NEEDS_PERSISTED_KEYPAIRS ]] then
        for f in $(ls ~/.ssh/*.template); do
            op inject -i $f -o ~/.ssh/$(basename $f .template)
        done
    fi

    op run --no-masking -- command terraform "$@"

    if [[ -v NEEDS_PERSISTED_KEYPAIRS ]] then
        for f in $(ls ~/.ssh/*.template); do
            rm ~/.ssh/$(basename $f .template)
        done
    fi
}

function __aws_envrc_path_cd {
    [ -v AWS_ENVRC_PATH ] && cd $AWS_ENVRC_PATH
}

function aws {
    (__aws_envrc_path_cd; op run --no-masking -- command aws "$@")
}

function kubectl {
    (__aws_envrc_path_cd; op run --no-masking -- command kubectl "$@")
}

function docker-login-ecr {
    (__aws_envrc_path_cd; aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 412041701469.dkr.ecr.us-east-1.amazonaws.com)
}

function docker-login-ghcr {
    op read op://Private/pj4ygw2cha76xlxbiqehnl4au4/token | docker login ghcr.io -u glebglazov --password-stdin
}

function docker-login {
    docker-login-ecr
    docker-login-ghcr
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
