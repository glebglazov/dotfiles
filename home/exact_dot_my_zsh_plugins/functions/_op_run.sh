# Runs a command with every op:// env var in scope resolved to its secret.
#
# direnv exports references, not secrets, so nothing that reads a credential
# from the environment works unless it goes through here. op-cache execs the
# command, so what runs is the real binary on PATH — a wrapper function of the
# same name does not recurse into itself.
function _op_run {
    if (( $+commands[op-cache] )); then
        op-cache run -- "$@"
    else
        command "$@"
    fi
}
