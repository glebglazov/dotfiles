function bwug {
	file="$HOME/.bw_sessions"

	key=$(bw unlock --raw)
	echo "export BW_SESSION=$key" >> $file
	source $file
}

function bwul {
	export "BW_SESSION=$(bw unlock --raw)"
}

function _bw {
  zparseopts -D -- \
    nl=no_lock -no-lock=no_lock \
    g=global -global=global

	bw --nointeraction --quiet sync
	if [[ ! "$?" -eq "0" ]]; then
		[[ -z "$global" ]] && bwul || bwug

		bw --nointeraction --quiet sync
	fi

	eval "$@"

	if [[ ! -z "$no_lock" ]]; then
		echo "WARNING: You are not locking Bitwarden!" >&2
	else
		bw --quiet lock
	fi
}

function bwnl {
	_bw -nl -- $@
}
