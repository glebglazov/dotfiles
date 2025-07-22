function git-clone-to-folder {
    local remote=$(git-ssh-repo-name-from-any-link "$1")
    local branch=$(git ls-remote --symref "git@github.com:$remote" HEAD | head -1 | awk '{print $2}' | cut -d/ -f3)

    git init
    git remote add origin "git@github.com:$remote"
    git pull origin "$branch"
}