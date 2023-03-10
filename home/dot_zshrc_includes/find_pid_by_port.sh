function find_pid_by_port {
	pid=$1

	lsof -i tcp:$pid | tail -1 | awk '{print $2}'
}
