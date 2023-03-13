alias vim="nvim"
alias ide="tmux-ide-layout"

# All functions below are functions and not aliases just because of the fact
# that this way we're not breaking original auto-completion

function aws {
    op run -- command aws "$@"
}

function bundle {
    op run -- command bundle "$@"
}

function yarn {
    op run -- command yarn "$@"
}

function terraform {
    for f in $(ls ~/.ssh/*.template); do
        op inject -i $f -o ~/.ssh/$(basename $f .template)
    done

    op run -- command terraform "$@"

    for f in $(ls ~/.ssh/*.template); do
        rm ~/.ssh/$(basename $f .template)
    done
}

function kubectl {
    op run -- command kubectl "$@"
}
