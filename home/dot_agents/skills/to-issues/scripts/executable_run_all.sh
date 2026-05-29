#!/usr/bin/env bash
# run_all.sh — invoke run_one.sh repeatedly until no eligible issues remain.
#
# Source of truth: <issues-folder>/index.json (see the to-issues skill).
#
# Usage: run_all.sh <issues-folder>
# Env:   forwarded to run_one.sh (AGENT_CMD, MAX_TRIES, TRY_TIMEOUT, ALLOW_DIRTY).
#
# Exit:  0 if every issue ended with status=done.
#        nonzero otherwise (some failed or stuck-blocked).

set -euo pipefail

[[ $# -ge 1 ]] || { echo "usage: run_all.sh <issues-folder>" >&2; exit 3; }
FOLDER=$1
MANIFEST="$FOLDER/index.json"

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RUN_ONE="$DIR/run_one.sh"
[[ -x $RUN_ONE ]] || { echo "run_all: $RUN_ONE not executable" >&2; exit 3; }
command -v jq >/dev/null || { echo "run_all: jq not found" >&2; exit 3; }
[[ -f $MANIFEST ]] || { echo "run_all: manifest not found: $MANIFEST" >&2; exit 3; }

LOG() { echo "[$(date '+%H:%M:%S')] run_all: $*"; }
STARTED=$SECONDS
iteration=0

LOG "starting — folder: $FOLDER"

while :; do
  iteration=$((iteration+1))
  LOG "--- iteration $iteration ---"
  set +e
  "$RUN_ONE" "$FOLDER"
  rc=$?
  set -e
  case $rc in
    0) LOG "iteration $iteration: issue completed successfully"; continue ;;
    1) LOG "iteration $iteration: issue failed (recorded)"; continue ;;
    2) LOG "all eligible issues processed"; break ;;
    *) exit "$rc" ;;
  esac
done

# Summarize. Exit 0 iff every issue is status=done.
read -r total done_count failed_count other_count < <(jq -r '
  .issues as $a
  | [ ($a|length),
      ([ $a[]|select(.status=="done")   ]|length),
      ([ $a[]|select(.status=="failed") ]|length),
      ([ $a[]|select(.status!="done" and .status!="failed") ]|length)
    ] | @tsv
' "$MANIFEST")

elapsed=$((SECONDS - STARTED))
LOG "finished in ${elapsed}s — total=$total done=$done_count failed=$failed_count blocked=$other_count"

[[ $done_count -eq $total ]] && exit 0
exit 1
