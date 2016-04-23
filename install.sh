#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

install_dotfiles () {
    for src in $(find "$DIR/" -maxdepth 2 -name '*.src')
    do
        dst="$HOME/$(basename "${src%.*}")"
        if [ ! -L "$dst" ]; then
            ln -s "$src" "$dst"
        fi
    done
}

install_dotfiles
