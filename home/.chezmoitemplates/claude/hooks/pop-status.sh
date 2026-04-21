#!/usr/bin/env bash
# pop-status.sh — notify the pop monitor daemon of a pane status change.
#
# Usage: pop-status.sh <working|unread|idle>
#
# Reads POP_MONITOR_ADDR (host:port). Falls back to
# ${LOCAL_NETWORK_HOST:-127.0.0.1}:${POP_MONITOR_PORT:-57341}. Override
# POP_MONITOR_ADDR for cross-host usage (e.g. devcontainer →
# host.docker.internal:57341).
#
# Requires $TMUX_PANE. Fire-and-forget: errors are swallowed so a failed
# status update never breaks the calling hook.

host=${LOCAL_NETWORK_HOST:-127.0.0.1}
port=${POP_MONITOR_PORT:-57341}
addr=${POP_MONITOR_ADDR:-${host}:${port}}
payload='{"cmd":"set-status","pane_id":"'"$TMUX_PANE"'","status":"'"$1"'"}'
echo "$payload" | nc -w1 "${addr%:*}" "${addr##*:}" >/dev/null 2>&1 || true
