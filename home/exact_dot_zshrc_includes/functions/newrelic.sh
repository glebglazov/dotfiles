function newrelic {
    # As RTX prepends path and newrelic_rpm gem has a binstub of "newrelic" in bin/ path
    # I've decided to use direct alias to target homebrew folder
    $BREW_PREFIX/newrelic-cli/bin/newrelic "$@"
}