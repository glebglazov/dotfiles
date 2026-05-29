#!/usr/bin/env bash
# run_all_parallel.sh — wave-based parallel issue runner using git worktrees.
#
# Source of truth: <issues-folder>/index.json (see the to-issues skill).
#
# Finds ALL eligible issues per wave. If >1, runs them in parallel worktrees.
# Worktree agents run with DEFER_MANIFEST=1 (they commit code only). Results
# merge back via cherry-pick, after which the parent flips status=done in
# index.json on the main branch. This keeps every agent off index.json so the
# manifest never causes a merge conflict. On a code conflict, the issue is
# retried sequentially.
#
# Usage: run_all_parallel.sh <issues-folder>
# Env:   AGENT_CMD      default: "claude --dangerously-skip-permissions -p"
#        MAX_TRIES      default: 3
#        TRY_TIMEOUT    default: "45m"
#        ALLOW_DIRTY    default: unset
#        MAX_PARALLEL   default: 4

set -euo pipefail

[[ $# -ge 1 ]] || { echo "usage: run_all_parallel.sh <issues-folder>" >&2; exit 3; }
FOLDER=$1
MANIFEST="$FOLDER/index.json"
PROGRESS="$FOLDER/progress.txt"

TRY_TIMEOUT=${TRY_TIMEOUT:-45m}
MAX_PARALLEL=${MAX_PARALLEL:-4}
export TRY_TIMEOUT

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RUN_ONE="$DIR/run_one.sh"
[[ -x $RUN_ONE ]] || { echo "run_all_parallel: $RUN_ONE not executable" >&2; exit 3; }

command -v jq  >/dev/null || { echo "run_all_parallel: jq not found" >&2; exit 3; }
command -v git >/dev/null || { echo "run_all_parallel: git not found" >&2; exit 3; }
[[ -f $MANIFEST ]] || { echo "run_all_parallel: manifest not found: $MANIFEST" >&2; exit 3; }

REPO_ROOT=$(git rev-parse --show-toplevel)
WT_DIR="$REPO_ROOT/.worktrees"
BRANCH=$(git rev-parse --abbrev-ref HEAD)

LOG() { echo "[$(date '+%H:%M:%S')] run_all_parallel: $*"; }
TS()  { date -u +%Y-%m-%dT%H:%M:%SZ; }
STARTED=$SECONDS

cleanup_worktrees() {
  if [[ -d $WT_DIR ]]; then
    for wt in "$WT_DIR"/issue-*; do
      [[ -d $wt ]] || continue
      git worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"
    done
    rmdir "$WT_DIR" 2>/dev/null || true
  fi
  git branch --list '_parallel/*' | while read -r b; do
    git branch -D "$b" 2>/dev/null || true
  done
}
trap cleanup_worktrees EXIT
cleanup_worktrees 2>/dev/null || true

# Eligibility query (same as run_one.sh): status=="open" and all blockers done.
eligible_files() {
  jq -r '
    .issues as $all
    | [ $all[]
        | select(.status=="open")
        | select( all(.blocked_by[]?;
            . as $b
            | ([ $all[] | select(.id==$b) | .status ] | (.[0] // "missing")) == "done") )
      ][]
    | .file
  ' "$MANIFEST"
}

id_for_file() { jq -r --arg f "$1" '.issues[] | select(.file==$f) | .id' "$MANIFEST"; }

mark_done_on_main() {
  local file=$1 id summary=$2 tmp
  id=$(id_for_file "$file")
  tmp=$(mktemp)
  jq --arg id "$id" '(.issues[] | select(.id==$id) | .status) = "done"' "$MANIFEST" > "$tmp" && mv "$tmp" "$MANIFEST"
  {
    echo "$(TS) [$file] DONE"
    echo "$summary"
    echo "---"
  } >> "$PROGRESS"
}

extract_summary() {
  awk '/^SUMMARY_START$/{flag=1; next} /^SUMMARY_END$/{flag=0} flag' "$1"
}

num_of()  { local stem="${1%.md}"; echo "${stem%%-*}"; }
name_of() { local stem="${1%.md}"; echo "${stem#*-}"; }

wave=0
while :; do
  mapfile -t ELIGIBLE < <(eligible_files)
  if [[ ${#ELIGIBLE[@]} -eq 0 ]]; then
    LOG "no eligible issues"
    break
  fi

  wave=$((wave + 1))
  wave_start=$SECONDS
  LOG "wave $wave — ${#ELIGIBLE[@]} eligible: ${ELIGIBLE[*]}"

  # Single eligible: run directly on main, no worktree overhead.
  if [[ ${#ELIGIBLE[@]} -eq 1 ]]; then
    set +e
    ALLOW_DIRTY=${ALLOW_DIRTY:-} "$RUN_ONE" "$FOLDER" "$FOLDER/${ELIGIBLE[0]}"
    rc=$?
    set -e
    case $rc in
      0|1) continue ;;
      2)   break ;;
      *)   exit "$rc" ;;
    esac
  fi

  # Multiple eligible: parallel worktrees, capped at MAX_PARALLEL.
  BATCH=("${ELIGIBLE[@]:0:$MAX_PARALLEL}")
  LOG "launching ${#BATCH[@]} parallel agents"

  mkdir -p "$WT_DIR"
  PIDS=(); WT_PATHS=(); WT_BRANCHES=(); WT_FILES=(); WT_LOGS=()

  for file in "${BATCH[@]}"; do
    num=$(num_of "$file")
    name=$(name_of "$file")
    wt_branch="_parallel/${num}-${name}"
    wt_path="$WT_DIR/issue-${num}-${name}"

    git branch -D "$wt_branch" 2>/dev/null || true
    git worktree add -b "$wt_branch" "$wt_path" HEAD 2>/dev/null || {
      LOG "worktree creation failed for $file, will retry sequentially"
      continue
    }

    # FOLDER may be absolute or relative to REPO_ROOT; resolve into the worktree.
    if [[ $FOLDER == /* ]]; then
      wt_folder="$wt_path/${FOLDER#$REPO_ROOT/}"
    else
      wt_folder="$wt_path/$FOLDER"
    fi

    log_file=$(mktemp)
    WT_PATHS+=("$wt_path"); WT_BRANCHES+=("$wt_branch"); WT_FILES+=("$file"); WT_LOGS+=("$log_file")

    (
      cd "$wt_path"
      ALLOW_DIRTY=1 DEFER_MANIFEST=1 "$RUN_ONE" "$wt_folder" "$wt_folder/$file" > "$log_file" 2>&1
    ) &
    PIDS+=($!)
    LOG "  $file (pid $!) → $wt_path"
  done

  LOG "waiting for ${#PIDS[@]} agents (pids: ${PIDS[*]})..."
  STATUSES=()
  for pid in "${PIDS[@]}"; do
    set +e; wait "$pid"; rc=$?; set -e
    STATUSES+=($rc)
    LOG "  pid $pid finished (exit $rc)"
  done

  for i in "${!WT_LOGS[@]}"; do
    LOG "--- log for ${WT_FILES[$i]} ---"
    cat "${WT_LOGS[$i]}" 2>/dev/null || true
    LOG "--- end log ${WT_FILES[$i]} (exit ${STATUSES[$i]}) ---"
  done

  # Cherry-pick results in batch order, then flip manifest on main.
  RETRY_SEQ=()
  for i in "${!WT_BRANCHES[@]}"; do
    branch="${WT_BRANCHES[$i]}"
    status="${STATUSES[$i]}"
    file="${WT_FILES[$i]}"
    wt_path="${WT_PATHS[$i]}"
    log_file="${WT_LOGS[$i]}"

    commits_ahead=$(git log "${BRANCH}..${branch}" --oneline 2>/dev/null | wc -l | tr -d ' ')

    if [[ $commits_ahead -eq 0 ]]; then
      LOG "$file — no commits (agent failed or no changes)"
      [[ $status -ne 0 ]] && RETRY_SEQ+=("$file")
    else
      set +e
      git cherry-pick "${BRANCH}..${branch}" --no-edit 2>/dev/null
      cp_rc=$?
      set -e
      if [[ $cp_rc -ne 0 ]]; then
        LOG "merge conflict for $file — will retry sequentially"
        git cherry-pick --abort 2>/dev/null || true
        RETRY_SEQ+=("$file")
      else
        summary=$(extract_summary "$log_file"); [[ -z $summary ]] && summary="(no summary provided)"
        mark_done_on_main "$file" "$summary"
        git add -A && git commit --amend --no-edit
        LOG "$file merged successfully"
      fi
    fi

    rm -f "$log_file"
    git worktree remove --force "$wt_path" 2>/dev/null || rm -rf "$wt_path"
    git branch -D "$branch" 2>/dev/null || true
  done

  if [[ ${#RETRY_SEQ[@]} -gt 0 ]]; then
    LOG "retrying ${#RETRY_SEQ[@]} conflicted/failed issues sequentially"
    for file in "${RETRY_SEQ[@]}"; do
      LOG "sequential retry — $file"
      set +e
      ALLOW_DIRTY=${ALLOW_DIRTY:-} "$RUN_ONE" "$FOLDER" "$FOLDER/$file"
      rc=$?
      set -e
      case $rc in
        0|1) ;;
        *)   LOG "unexpected error on retry for $file (rc=$rc)" ;;
      esac
    done
  fi
  LOG "wave $wave completed in $((SECONDS - wave_start))s"
done

# Summary, identical accounting to run_all.sh.
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
