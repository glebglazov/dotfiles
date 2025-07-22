function find-pid-by-port {
	local pid=$1

	lsof -i tcp:$pid | tail -1 | awk '{print $2}'
}