#!/usr/bin/env bash
# pop-status.sh — notify the pop monitor daemon of a pane status change.
#
# Usage: pop-status.sh <working|unread|idle>
#
# Reads POP_MONITOR_ADDR (host:port), defaults to 127.0.0.1:57341 for
# local-only setups. Override in the environment for cross-host usage
# (e.g. devcontainer → host.docker.internal:57341).
#
# Requires $TMUX_PANE. Fire-and-forget: errors are swallowed so a failed
# status update never breaks the calling hook.

addr=${POP_MONITOR_ADDR:-127.0.0.1:57341}
payload='{"cmd":"set-status","pane_id":"'"$TMUX_PANE"'","status":"'"$1"'"}'
echo "$payload" | nc -w1 "${addr%:*}" "${addr##*:}" >/dev/null 2>&1 || true
