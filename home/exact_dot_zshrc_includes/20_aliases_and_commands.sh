alias vim="nvim"
alias ide="tmux-ide-layout"

# All functions below are functions and not aliases just because of the fact
# that this way we're not breaking original auto-completion

function aws {
    op run --no-masking -- command aws "$@"
}

function bundle {
    op run --no-masking -- command bundle "$@"
}

function gh {
    op run --no-masking -- command gh "$@"
}

function yarn {
    op run --no-masking -- command yarn "$@"
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

function pid-by-port {
	pid=$1

	lsof -i tcp:$pid | tail -1 | awk '{print $2}'
}
