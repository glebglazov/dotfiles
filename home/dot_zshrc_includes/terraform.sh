function terraform {
    for f in $(ls ~/.ssh/*.template); do
        op inject -i $f -o ~/.ssh/$(basename $f .template)
    done

    command terraform "$@"

    for f in $(ls ~/.ssh/*.template); do
        rm ~/.ssh/$(basename $f .template)
    done
}
