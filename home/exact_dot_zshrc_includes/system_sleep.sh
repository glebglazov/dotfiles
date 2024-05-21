function system_sleep_away_mode() {
    sudo systemsetup -setsleep Never
}

function system_sleep_back_to_defaults() {
    sudo systemsetup -setsleep 10
    sudo systemsetup -setcomputersleep 1
}
