-- The lifecycle of a review: what is being reviewed -- the range of commits
-- from a base, with the working tree as its last member while anything is
-- uncommitted -- turning that into a changeset, and tearing everything down
-- again.
local export = require('review.export')
local hunks = require('review.hunks')
local render = require('review.render')
local state = require('review.state')

local M = {}

-- Where a session with no explicit base starts from. `setup{ default_base = ... }`
-- replaces this with the editor's own default-remote-branch lookup.
function M.default_base()
  return 'origin/main'
end

-- A ref as the short hash it names right now.
function M.rev(ref)
  local out = vim.fn.systemlist({ 'git', 'rev-parse', '--short', '--verify', '--quiet', ref })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == '' then return nil end
  return out[1]
end

-- Normalize a session spec into the two values the git commands take.
-- `uncommitted` reviews the working tree alone -- a range whose only member is
-- the Uncommitted Tip -- so its base is HEAD, resolved to a hash so that the
-- range goes on meaning the same thing once the reader commits. A bare `base`
-- is used as the base; nothing at all falls back to the default remote branch.
function M.resolve(spec)
  spec = spec or {}
  if spec.uncommitted then return M.rev('HEAD') or 'HEAD', nil end
  local base = (spec.base and spec.base ~= '') and spec.base or M.default_base()
  return base, spec.head
end

-- The commits of `base..head`, oldest first: the committed part of the range.
function M.commits(base, head)
  local out = vim.fn.systemlist({
    'git', '--no-pager', 'log', '--reverse', '--date=short',
    '--format=%h%x09%ad%x09%s', base .. '..' .. ((head and head ~= '') and head or 'HEAD'),
  })
  if vim.v.shell_error ~= 0 then return {} end
  local commits = {}
  for _, line in ipairs(out) do
    local hash, date, subject = line:match('^(%S+)\t(%S+)\t(.*)$')
    if hash then
      table.insert(commits, { hash = hash, date = date, subject = subject })
    end
  end
  return commits
end

-- Whether the working tree holds anything uncommitted -- staged, unstaged or
-- untracked. This one question is the whole of what makes the Uncommitted Tip
-- a member of the range.
function M.dirty()
  local root = state.repo_root() or vim.fn.getcwd()
  local out = vim.fn.systemlist({ 'git', '-C', root, 'status', '--porcelain' })
  return vim.v.shell_error == 0 and #out > 0
end

-- Whether a range that runs to `head` holds the Uncommitted Tip right now. Only
-- a range ending at HEAD carries it -- one ending at an older commit has nothing
-- to do with what is on disk -- and then only while there is something
-- uncommitted to carry.
function M.carries_tip(head)
  return (head == nil or head == '' or head == 'HEAD') and M.dirty()
end

-- The members of `base..head`, oldest first: its commits, and the Uncommitted
-- Tip past them while the range carries it.
function M.members(base, head)
  local members = M.commits(base, head)
  if M.carries_tip(head) then table.insert(members, state.uncommitted_entry()) end
  return members
end

-- What the span being read is called, in a line the reader is told. The tip
-- names itself rather than a hash, because `uncommitted` is not a hash anything
-- else in the editor can be asked about.
function M.span_label()
  local span = state.targeted()
  if #span == 0 then return 'nothing — the span being read has left the range' end
  if #span > 1 then
    return ('%d member(s), %s..%s, as one diff'):format(#span, span[1].hash, span[#span].hash)
  end
  if state.is_uncommitted(span[1].hash) then return 'the working tree' end
  return ('1 commit, %s %s'):format(span[1].hash, span[1].subject)
end

-- Start a review: changeset → quickfix, Diff Marks for the span, inline
-- comments on, statusline badge. `spec` is { base, head, uncommitted } -- see
-- session.resolve. An omitted base means the default remote branch, which is the
-- whole branch. Returns false without touching anything when the range holds no
-- members at all: there is nothing to read, and saying so beats opening a
-- session that looks like a review of nothing.
function M.start(spec)
  local base, head = M.resolve(spec)
  local members = M.members(base, head)
  if #members == 0 then
    vim.notify(('Review: nothing to review — %s..%s holds no commits and nothing is uncommitted'):format(
      base, (head and head ~= '') and head or 'HEAD'), vim.log.levels.WARN)
    return false
  end
  state.active = true
  state.set_range(members, { base = base, head = head })
  -- The range opens on its committed part, the same span the switcher's reset
  -- key puts back: uncommitted work is a row to target, not something the review
  -- shows you before you asked for it.
  state.set_targeted(members[1].hash, (M.newest_commit() or members[#members]).hash)
  -- The whole range as one diff, the way a pull request shows a branch --
  -- revision buffers for its commits, the files on disk when the span ends at
  -- the tip. One path, whatever the range is made of, and the one place the
  -- Diff Marks come from too.
  hunks.range_hunks(state.targeted_from, state.current)
  -- The review's home from here on: the tab the changeset was just laid out in.
  -- Recorded at the start rather than on the way out, so one key leads back to
  -- it from anywhere for as long as the session lasts.
  require('review.buffers').set_review_tab()
  render.all()
  render.set_statusline()
  vim.notify(('Review started (%s)'):format(M.span_label()), vim.log.levels.INFO)
  return true
end

-- Show me my uncommitted work. Outside a session it starts one on the tip
-- alone; inside a session it targets the tip, which is a move within the review
-- rather than the end of it -- no keypress of this plugin destroys a running
-- review.
function M.uncommitted()
  if not state.active then
    if not M.carries_tip(nil) then
      vim.notify('Review: nothing uncommitted to read', vim.log.levels.WARN)
      return false
    end
    return M.start({ uncommitted = true })
  end
  M.refresh_range()
  if not state.index_of(state.UNCOMMITTED) then
    vim.notify('Review: nothing uncommitted to read', vim.log.levels.WARN)
    return false
  end
  if not M.set_current(state.UNCOMMITTED) then return false end
  vim.notify('Review: reading the working tree', vim.log.levels.INFO)
  return true
end

-- The targeted span put back over the range as it now stands. A span the reader
-- chose is kept whole while the range still holds both of its ends; the whole
-- range, which is where the reading rests rather than something chosen, widens
-- onto whatever arrived.
local function repair_target(from, to, resting, tip_left)
  local whole_from, whole_to = M.whole_range_ends()
  if resting then return state.set_targeted(whole_from, whole_to) end
  if state.set_targeted(from, to) then return true end
  -- An end of the chosen span is gone. Work that has just been committed is
  -- still the work on the screen, so a span that ended at the tip follows it
  -- onto the commit that holds it, keeping the end that survived:
  -- `c3..the working tree` becomes `c3..HEAD` -- the same lines, now committed
  -- -- while the tip on its own becomes HEAD on its own. A commit a rewrite
  -- took leaves nothing to follow, so the reader is put back on the branch as
  -- it now stands.
  if tip_left and state.is_uncommitted(to) then
    return state.set_targeted(state.index_of(from) and from or whole_to, whole_to)
  end
  return state.set_targeted(whole_from, whole_to)
end

-- The Range Refresh: the one recompute of what the range holds. `base..head` is
-- asked again, so a commit made here, made from a terminal, or pulled or
-- rebased onto the branch is a member from now on; the Uncommitted Tip joins
-- the range as soon as there is something uncommitted and leaves as soon as
-- there is not. Comments filed under what the range lost are refiled onto HEAD,
-- and the targeted span is repaired around both the arrivals and the
-- departures. Called where docs/adr/0004 says membership is recomputed -- at a
-- start (which builds the range anyway), at a restore, and whenever the
-- switcher opens -- and nowhere else.
--
-- A departure costs the session no more than that refile, whether it was a
-- rewrite or the tip: nothing is matched onto the commits that replaced the
-- ones the range lost (docs/adr/0006), so the comments arrive on HEAD exactly
-- as they were written, knowingly describing lines that have since moved, and
-- the rebound mark on them is what says so.
--
-- Returns whether the reading changed -- the span being read moving, or
-- comments being refiled out from under it -- having rebuilt the changeset and
-- redrawn when it did. That rebuild is quiet: a refresh happens while the
-- reader is wherever they chose to be, and taking their window to the first
-- hunk of a range they did not ask to be moved through is not the refresh's to
-- do.
function M.refresh_range()
  if not state.active then return false end
  local spec = state.spec or {}
  local members = M.members(spec.base or M.default_base(), spec.head)
  -- A review of no members is not a review: whatever git has to say about the
  -- base right now, the range is left as it was rather than emptied.
  if #members == 0 then return false end

  local held, holds = {}, {}
  for _, c in ipairs(state.range) do held[c.hash] = true end
  for _, c in ipairs(members) do holds[c.hash] = true end
  local arrivals, departures = 0, 0
  for _, c in ipairs(members) do if not held[c.hash] then arrivals = arrivals + 1 end end
  for _, c in ipairs(state.range) do if not holds[c.hash] then departures = departures + 1 end end
  if arrivals == 0 and departures == 0 then return false end

  local from, to = state.targeted_from, state.current
  -- Asked of the range as it stood, before the arrivals move where "the whole
  -- range" ends: a span that matches it is the reading at rest, and the rest is
  -- what follows the membership.
  local whole_from, whole_to = M.whole_range_ends()
  local resting = (from == whole_from and to == whole_to)
  local tip_left = held[state.UNCOMMITTED] and not holds[state.UNCOMMITTED]

  state.range = members
  local moved = require('review.persist').refile()
  repair_target(from, to, resting, tip_left)
  state.save()

  local changed = state.targeted_from ~= from or state.current ~= to or moved > 0
  if not changed then return false end
  hunks.range_hunks(state.targeted_from, state.current, { quiet = true })
  render.all()
  render.set_statusline()
  local what
  if tip_left then
    what = 'the uncommitted work is committed'
  elseif departures > 0 then
    what = 'the stack was rewritten'
  else
    what = ('%d commit(s) joined the range'):format(arrivals)
  end
  vim.notify(('Review: %s — reading %s%s'):format(what, M.span_label(),
    (moved > 0) and (', %d comment(s) refiled onto HEAD'):format(moved) or ''), vim.log.levels.INFO)
  return true
end

-- The commit hash in a piece of text, which is how a review is started from
-- whatever the reader has highlighted: a line of `git log --oneline`, a hash in
-- a commit message, a row of a blame. The first run of four or more hex digits
-- that git will own as a commit wins -- `git log` puts the hash first, and a
-- word that only looks hexadecimal ("deadbeef" in prose) is rejected by git
-- rather than by a pattern here.
function M.sha_in_text(text)
  for word in tostring(text or ''):gmatch('%x%x%x%x+') do
    local out = vim.fn.systemlist({ 'git', 'rev-parse', '--verify', '--quiet', word .. '^{commit}' })
    if vim.v.shell_error == 0 and out[1] then return word end
  end
  return nil
end

-- What is highlighted, as one string. Charwise takes the selection exactly;
-- linewise and blockwise take whole lines, because a hash is a word on a line
-- either way.
local function selected_text()
  local mode = vim.fn.mode()
  local from, to = vim.fn.getpos('v'), vim.fn.getpos('.')
  local srow, scol, erow, ecol = from[2], from[3], to[2], to[3]
  if srow > erow or (srow == erow and scol > ecol) then
    srow, scol, erow, ecol = erow, ecol, srow, scol
  end
  if mode ~= 'v' then
    return table.concat(vim.api.nvim_buf_get_lines(0, srow - 1, erow, false), '\n')
  end
  local last = #(vim.api.nvim_buf_get_lines(0, erow - 1, erow, false)[1] or '')
  local ok, text = pcall(vim.api.nvim_buf_get_text, 0,
    srow - 1, scol - 1, erow - 1, math.min(ecol, last), {})
  return ok and table.concat(text, '\n') or ''
end

-- Start a review of everything from the highlighted commit onwards: base is that
-- commit's parent, so the commit itself is the oldest one under review. This is
-- the answer to "review this branch from here" -- point at where the work
-- starts, in a log or a blame, and read forward from it.
--
-- The selection is read before the session opens: starting one moves windows
-- around, and the highlight would be gone by then.
function M.start_from_selection()
  local text = selected_text()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
  local sha = M.sha_in_text(text)
  if not sha then
    vim.notify(('Review: no commit in %q'):format(vim.trim(text):sub(1, 40)), vim.log.levels.WARN)
    return false
  end
  -- A root commit has no parent to diff against, so there is no range starting
  -- before it -- said plainly rather than left to git's own error.
  vim.fn.systemlist({ 'git', 'rev-parse', '--verify', '--quiet', sha .. '^{commit}' })
  local parent = vim.fn.systemlist({ 'git', 'rev-parse', '--verify', '--quiet', sha .. '^^{commit}' })
  if vim.v.shell_error ~= 0 or not parent[1] then
    vim.notify(('Review: %s is the first commit — nothing before it to review against'):format(sha),
      vim.log.levels.WARN)
    return false
  end
  return M.start({ base = sha .. '^' })
end

-- Finish a review: export to clipboard, then clear comments, marks off, badge off.
function M.finish()
  export.export() -- copies to clipboard (warns if empty); we tear down regardless
  M.teardown()
  vim.notify('Review finished', vim.log.levels.INFO)
end

-- Everything a session leaves behind, taken down: comments, range, the Diff
-- Marks, badge and the file on disk. Shared with `persist.discard`, which
-- drops a session without exporting it -- and the persisted state goes first, so
-- a crash mid-teardown cannot resurrect a session that was being ended.
function M.teardown()
  require('review.persist').clear()
  -- The review's own keys come off every buffer they were put on: `]f` and
  -- `<Tab>` mean what the editor means again the moment the session ends.
  require('review.buffers').detach_all()
  require('review.marks').clear()
  state.active = false
  state.clear()
  state.clear_range()
  render.set_statusline()
end

-- Target another span of the range: `oldest`..`newest`, both ends included. The
-- changeset list becomes that span's combined changes, so it keeps answering
-- "what is left to read here", and the session itself is never ended -- every
-- comment, on this span or any other, keeps its text and its resolved state.
-- Refused when the span is not one the range holds, so a bad move leaves the
-- reader where they were rather than on an empty list.
function M.target(oldest, newest)
  if not state.active then return false end
  if not oldest or not newest then return false end
  if not state.set_targeted(oldest, newest) then return false end
  state.save()
  hunks.range_hunks(oldest, newest)
  render.all()
  return true
end

-- One member of the range, targeted on its own: a targeted range of one, which
-- is the review of a single commit -- or of the working tree.
function M.set_current(hash)
  return M.target(hash, hash)
end

-- The newest committed member of `range` (the session's own by default): where
-- "the whole range" ends. Nil for a range that holds nothing but the
-- Uncommitted Tip.
function M.newest_commit(range)
  range = range or state.range
  for i = #range, 1, -1 do
    if not state.is_uncommitted(range[i].hash) then return range[i] end
  end
  return nil
end

-- The two ends "the whole range" means over `range`: its oldest member through
-- its newest commit. One answer for the reset key, for a target left with
-- nowhere to fall back to, and for the test of whether the reading is at rest --
-- so the resting span is the same span in all three.
function M.whole_range_ends(range)
  range = range or state.range
  local oldest = range[1]
  if not oldest then return nil end
  local newest = M.newest_commit(range) or range[#range]
  return oldest.hash, newest.hash
end

-- The whole range targeted again: one diff of the branch, which is one diff of
-- what is committed on it. The tip is left out on purpose -- the uncommitted key
-- is what targets it, and a reset that swept it in would leave no way back to
-- the branch as it stands. A session holding nothing but the tip resets onto the
-- tip, because there is nothing else to put back.
function M.target_whole_range()
  local oldest, newest = M.whole_range_ends()
  if not oldest then return false end
  return M.target(oldest, newest)
end

-- Target another part of the range from the switcher: one commit chosen, a run
-- of them marked, or the whole range put back. The session itself is untouched
-- by any of the three, because a stack ends as one body of feedback however it
-- was read.
function M.switch_from_picker()
  -- The switcher is the list of what the range holds, so it is one of the three
  -- places membership is recomputed: it must not offer commits a rewrite has
  -- taken, nor work that has since been committed, nor hide commits that have
  -- since been made or pulled. One refresh answers all of that, and redraws
  -- around whatever it changed.
  M.refresh_range()
  require('review.pickers').switch_commit({
    choose = function(commit)
      if M.set_current(commit.hash) then
        vim.notify(('Review: reading %s (%d/%d)'):format(
          M.span_label(), state.current_index() or 0, #state.range), vim.log.levels.INFO)
      end
    end,
    span = function(oldest, newest)
      if M.target(oldest, newest) then
        vim.notify(('Review: reading %s'):format(M.span_label()), vim.log.levels.INFO)
      end
    end,
    reset = function()
      if M.target_whole_range() then
        vim.notify(('Review: reading the whole range, %d member(s), as one diff'):format(
          #state.targeted()), vim.log.levels.INFO)
      end
    end,
  })
end

return M
