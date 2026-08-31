-- A review session outlives the editor. A session spans a whole stack now, not
-- one afternoon's diff, so quitting must not throw the reading away: the range,
-- the current commit and every comment are written to the repository's own git
-- dir as they change, and read back when nvim next opens in that repository.
--
-- A rewrite is not the end of a session. An amend, a rebase or a git-pile
-- restack takes the commits the session was reading; the range is resolved
-- again from the base it was resolved from, and every comment filed under
-- something the range no longer holds is refiled onto HEAD. Carrying comments
-- onto the commits that replaced the rewritten ones was rejected -- no mapping
-- is right often enough to be trusted (docs/adr/0006) -- so nothing is matched
-- here and nothing is asked of the reader.
local buffers = require('review.buffers')
local state = require('review.state')

local M = {}

local FILE = 'nvim-review-session.json'
-- Bumped when the shape below changes; a file from another shape is ignored
-- rather than half-read.
local VERSION = 1

-- One file per repository, inside its git dir: the session belongs to the
-- checkout it reads, follows that checkout around, and never shows up as an
-- untracked file in the tree under review.
function M.path(root)
  local dir = buffers.gitdir(root or state.repo_root())
  if not dir then return nil end
  return dir .. '/' .. FILE
end

-- Write the session as it stands. Called after every mutation rather than on
-- exit, so a crash costs nothing.
function M.save()
  if not state.active then return false end
  local path = M.path()
  if not path then return false end
  local ok, encoded = pcall(vim.json.encode, {
    version = VERSION,
    spec = state.spec,
    range = state.range,
    current = state.current,
    targeted_from = state.targeted_from,
    comments = state.comments,
    auto_form = state.auto_form,
    show_resolved = state.show_resolved,
  })
  if not ok then return false end
  return vim.fn.writefile({ encoded }, path) == 0
end

-- Sessions written before a comment knew its own commit and path key each
-- comment by the buffer it was typed in -- a real path, or a `fugitive://` name
-- for a revision buffer. The commit each one belongs to was recorded already,
-- so the conversion is the path alone. Converting on read rather than refusing
-- the file is deliberate: a discarded session loses review work that cannot be
-- recovered.
local function migrate(comments)
  local root = state.repo_root()
  for _, c in ipairs(comments or {}) do
    if type(c.path) == 'string' and c.path ~= '' then
      c.path = buffers.display_path(c.path, root)
    end
  end
  return comments
end

-- Sessions written before the changeset was built from a span of commits
-- recorded one current commit and nothing else. That commit is a targeted range
-- of one, so the span begins where it ends -- and the session restores as the
-- review it was. Converting on read rather than refusing the file is the same
-- rule as above: a discarded session loses review work that cannot be recovered.
local function migrate_targeted(data)
  if data.targeted_from == nil then data.targeted_from = data.current end
  return data
end

-- Sessions written before a comment knew the span it was made against recorded
-- one commit per comment. That commit is a targeted range of one, so the span
-- begins where it ends -- and every comment of such a session comes back
-- attached to exactly what it was attached to before, drawn wherever it was
-- drawn before. Same house rule again: convert on read, because a discarded
-- session loses review work that cannot be recovered.
local function migrate_spans(comments)
  for _, c in ipairs(comments or {}) do
    if c.commit_from == nil then c.commit_from = c.commit end
  end
  return comments
end

-- Sessions written while the working tree was a kind of session rather than a
-- member of the range held no range at all, no current commit, and comments
-- filed under no commit. Such a session is exactly a range holding the
-- Uncommitted Tip alone, targeted, with every comment made against that tip --
-- so it converts into one, and comes back as the review it was with every
-- comment intact. Same house rule as the three above: convert on read, because
-- a discarded session loses review work that cannot be recovered.
local function migrate_worktree(data)
  local spec = data.spec or {}
  if not spec.uncommitted then return data end
  local sentinel = state.UNCOMMITTED
  data.spec = { base = require('review.session').rev('HEAD') or 'HEAD' }
  data.range = { state.uncommitted_entry() }
  data.current, data.targeted_from = sentinel, sentinel
  for _, c in ipairs(data.comments or {}) do
    if c.scope ~= 'session' and c.commit == nil then
      c.commit, c.commit_from = sentinel, sentinel
    end
  end
  return data
end

function M.load()
  local path = M.path()
  if not path or vim.fn.filereadable(path) == 0 then return nil end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'),
    -- Absent fields (a session comment has no commit) come back as nil, not as
    -- vim.NIL sentinels every reader would have to know about.
    { luanil = { object = true, array = true } })
  if not ok or type(data) ~= 'table' or data.version ~= VERSION then return nil end
  data.comments = migrate_spans(migrate(data.comments))
  return migrate_worktree(migrate_targeted(data))
end

function M.clear()
  local path = M.path()
  if path then vim.fn.delete(path) end
end

-- Whether the range no longer holds a home for `c`. A comment is filed under
-- the span it was written against, and a span the range has lost is a span
-- nothing can be drawn against: a rewritten commit, or the Uncommitted Tip once
-- the work is committed. One rule covers both, because both are the same thing
-- said about membership.
--
-- A comment already sitting on `head` is left alone even when the range does not
-- hold it -- a range resolved to an explicit head need not reach HEAD at all --
-- so that a refile happens once rather than on every check.
local function orphaned(c, head)
  if c.scope == 'session' or c.commit == nil then return false end
  if c.commit == head and c.commit_from == head then return false end
  return state.index_of(c.commit) == nil or state.index_of(c.commit_from) == nil
end

-- Every orphaned comment refiled onto HEAD; the number moved. This is the whole
-- of what a rewrite costs a session. Nothing is matched -- carrying a comment
-- onto the commit that replaced the one it was written against cannot be done
-- reliably (docs/adr/0006) -- so the move is unconditional, and everything but
-- the span survives it: the scope, the path and the line numbers arrive exactly
-- as they were, knowingly describing lines that have since moved, which is what
-- `rebound` is on the comment to say.
--
-- HEAD is the target rather than the newest member of the range, because the
-- newest member may be the tip: the tip joins and leaves the range as the reader
-- works, so a comment refiled onto it would be orphaned again by the next
-- commit.
function M.refile(head)
  head = head or require('review.session').rev('HEAD')
  if not head then return 0 end
  local moved = 0
  for _, c in ipairs(state.comments) do
    if orphaned(c, head) then
      c.commit, c.commit_from = head, head
      c.rebound = true
      moved = moved + 1
    end
  end
  if moved > 0 then M.save() end
  return moved
end

-- Ask the range what it holds, on demand (`:Review check`). The Range Refresh
-- is the whole answer -- arrivals admitted, what departures took refiled onto
-- HEAD, the changeset rebuilt around whatever the reader is left reading -- so
-- this is the reader's own way of reaching it between the three places it runs
-- by itself. Returns whether the reading changed; never that the session
-- ended, because it does not.
function M.check()
  if not state.active or #state.range == 0 then return false end
  return require('review.session').refresh_range()
end

-- Drop the session without exporting, and forget the file with it.
function M.discard()
  M.clear()
  require('review.session').teardown()
  vim.notify('Review session discarded', vim.log.levels.INFO)
end

-- How a restored session announces itself.
local function restored_message()
  return ('Review session restored (%d member(s), reading %s, %d comment(s))'):format(
    #state.range, require('review.session').span_label(), #state.comments)
end

-- Pick the saved session back up: comments, range, targeted span and the
-- reader's toggles, then the session dressing a start would have applied.
function M.restore()
  if state.active then return false end
  local data = M.load()
  if not data then return false end
  state.comments = data.comments or {}
  state.range = data.range or {}
  state.current = data.current
  state.targeted_from = data.targeted_from
  state.spec = data.spec
  if data.auto_form ~= nil then state.auto_form = data.auto_form end
  if data.show_resolved ~= nil then state.show_resolved = data.show_resolved end
  state.active = true

  local render = require('review.render')
  -- The branch has moved since the session was saved -- commits made or pulled,
  -- work committed, a rewrite -- so its membership is asked again before
  -- anything is drawn, and the session comes back describing the branch as it
  -- now stands.
  local refreshed = require('review.session').refresh_range()

  local spec = state.spec or {}
  if spec.base then
    require('review.session').dress(spec.base)
  end
  render.all()
  render.set_statusline()
  vim.notify(restored_message(), vim.log.levels.INFO)
  -- The walk comes back with the session, but quietly: the reader opened this
  -- editor on a file of their own, not on the quickfix list. A refresh that
  -- changed the reading has rebuilt it already.
  if not refreshed then
    require('review.hunks').range_hunks(state.targeted_from, state.current, { quiet = true })
  end
  -- Tab ids do not survive quitting nvim, so the restored session adopts the tab
  -- it came back in -- the one whose signs it just dressed and whose changeset
  -- list it just filled. That tab is the review's home in every respect but the
  -- name it was saved under.
  require('review.buffers').set_review_tab()
  return true
end

return M
