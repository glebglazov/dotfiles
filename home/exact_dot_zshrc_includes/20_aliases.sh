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

function kubectl {
    ([ -v AWS_ENVRC_PATH ] && cd $AWS_ENVRC_PATH; op run --no-masking -- command kubectl "$@")
}
