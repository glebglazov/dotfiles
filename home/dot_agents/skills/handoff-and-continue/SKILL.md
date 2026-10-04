---
name: handoff-and-continue
description: Hand off the current task and start a fresh agent in a new T3 Code thread or a tmux pane without manually reopening it.
argument-hint: "[target harness] [next task]"
---

# Hand off and continue

1. Use the requested next task or the unfinished objective. Ask only if neither
   exists. Default to the current harness and directory. Choose the route: the
   **T3 route** when a `t3_thread_launch` tool is available, otherwise the
   **tmux route**. For the tmux route, check
   **spawn-agent**'s launch prerequisites before proceeding.
2. Stop this session's writes, including workers and background commands that
   change shared files. Inspect the resulting working tree. Invoke **handoff**
   for the next task, saving its document in a unique OS temporary directory.
   Include the absolute working directory, branch, uncommitted work, active
   processes, next action, and completion checks. Reference existing artifacts
   instead of copying them.
3. Choose an absent acknowledgement-file path beside the handoff. From now on,
   only monitor the transfer. Launch the recipient with this prompt, using
   absolute paths:

   > Read <handoff-file> and the repository instructions. Check the working
   > directory and working tree. Then write <acknowledgement-file> with the
   > handoff path, working directory, and concrete next action. Continue the
   > recorded task within its existing authorization. The previous agent has
   > stopped editing. You are the recipient; do not repeat the handoff.

   - **T3 route:** call `t3_thread_launch` once, with the prompt as `message`
     and a short task title. When this checkout is a worktree, pass an
     `existing_worktree` `workspaceStrategy` with its path and branch; without
     one, the recipient lands in the project root. Set `modelSelection` only
     for a requested harness change.
   - **tmux route:** invoke **spawn-agent** with the prompt.
4. Within two minutes, read the acknowledgement and check that it matches the
   handoff and next task. Check the recipient for startup errors: on the T3
   route with `t3_thread_read` (`view: "activity"`), on the tmux route in the
   pane. On success, report the route, the thread ID or pane ID, handoff path,
   and next action, then end this turn. Retain the old thread or pane and the
   files. Change focus only if requested.
5. If startup or acknowledgement fails, report the transfer as unconfirmed with
   its thread ID or pane ID and saved paths. Keep edits stopped while the
   recipient may run. Inspect or stop it before resuming writes or launching a
   replacement. After a T3 launch error or lost response, find the recipient in
   `t3_thread_list` before any retry: each launch call creates a new thread.
