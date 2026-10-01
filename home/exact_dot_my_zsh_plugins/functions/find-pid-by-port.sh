function find-pid-by-port {
	local port=$1
	local pids=($(lsof -nP -t -iTCP:$port -sTCP:LISTEN | sort -un))
	local pid

	# Forked children inherit the listening socket, so print only holders whose parent does not hold it too.
	for pid in $pids; do
		(( ${pids[(Ie)$(ps -o ppid= -p $pid | tr -d ' ')]} )) || echo $pid
	done
}
