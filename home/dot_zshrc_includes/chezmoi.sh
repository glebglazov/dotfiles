function _cm {
	action=$1
	no_lock=$2

	opts=""
	[[ ! -z "$no_lock" ]] && opts+="-nl"

	_bw $opts -- chezmoi $action
}

function cma {
	_cm apply $1
}

function cmu {
	_cm update $1
}

function cmdi {
	_cm diff $1
}

alias cmanl="cma f"
alias cmunl="cmu f"
alias cmdinl="cmdi f"
