---
fragment: A1945895
generation: 0004
branch: master
---

+ Session Dressing
  The editor-wide state a Review Session takes over while it runs — the diff base every Revision Buffer is read against, the sign column, and deleted lines shown inline — applied identically when a session starts and when an old one is picked up again, and given back when the session ends.
  avoid: gitsigns setup, review mode setup
  under: Review

+ Review Tab
  The tab a Review Session is read in: the Revision Buffers and the Changeset window. A session knows it from the moment it starts or is restored, it is reachable from anywhere in the editor, and it is rebuilt from the session's own state when it is gone.
  avoid: main tab, session tab, home tab
  under: Review

~ Investigation Tab
  The separate tab a Review Session opens a file's working-tree copy in, where a language server attaches and the reader can move freely across files. Leaving it returns to the Review Tab, which is rebuilt if it no longer exists.
  avoid: worktree tab, scratch tab, jump target
  was: The separate tab a Review Session opens a file's working-tree copy in, where a language server attaches and the reader can move freely across files. Leaving it restores the review tab exactly as it was left. (the review's own tab is a named thing now, and returning no longer depends on it having survived)
