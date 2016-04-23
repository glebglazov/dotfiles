#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

install_dotfiles () {
    local overwrite_all=true backup_all=true skip_all=false

    for src in $(find "$DIR/" -maxdepth 2 -name '*.src')
    do
        dst="$HOME/$(basename "${src%.*}")"
        rm "$dst"
        ln -s "$src" "$dst"
    done
}

install_dotfiles
