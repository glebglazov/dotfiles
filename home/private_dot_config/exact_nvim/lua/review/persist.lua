-- A review session outlives the editor. A session spans a whole stack now, not
-- one afternoon's diff, so quitting must not throw the reading away: the range,
-- the current commit and every comment are written to the repository's own git
-- dir as they change, and read back when nvim next opens in that repository.
--
-- Deliberately absent: carrying comments over onto rewritten commits. A rebase
-- that changed the very lines a comment is about cannot be followed, so the
-- session only notices that its commits are gone, says so, and offers the
-- comments up while they still mean something.
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

function M.load()
  local path = M.path()
  if not path or vim.fn.filereadable(path) == 0 then return nil end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), '\n'),
    -- Absent fields (a working-tree session has no range, a session comment no
    -- commit) come back as nil, not as vim.NIL sentinels every reader would
    -- have to know about.
    { luanil = { object = true, array = true } })
  if not ok or type(data) ~= 'table' or data.version ~= VERSION then return nil end
  data.comments = migrate_spans(migrate(data.comments))
  return migrate_targeted(data)
end

function M.clear()
  local path = M.path()
  if path then vim.fn.delete(path) end
end

-- The commits of `range` the session can no longer read. A rewrite -- amend,
-- rebase, a git-pile restack -- replaces commits rather than editing them, but
-- the old objects linger in the repository until gc, so existence proves
-- nothing: what matters is reachability. A rewritten commit stops being an
-- ancestor of the branch the session was started on, and `--is-ancestor`
-- answers for a vanished object too (it simply fails).
function M.missing(range)
  local root = state.repo_root()
  if not root then return {} end
  local spec = state.spec or {}
  local head = (spec.head and spec.head ~= '') and spec.head or 'HEAD'
  local gone = {}
  for _, c in ipairs(range or {}) do
    vim.fn.system({ 'git', '-C', root, 'merge-base', '--is-ancestor', c.hash, head })
    if vim.v.shell_error ~= 0 then table.insert(gone, c) end
  end
  return gone
end

-- What a stale session tells the reader: which commits went, and that the
-- comments outlived them.
function M.stale_message(missing)
  missing = missing or {}
  local lines = {
    ('Review session is stale: %d of %d commit(s) under review no longer exist — the stack was amended or rebased.')
      :format(#missing, #state.range),
  }
  for _, c in ipairs(missing) do
    table.insert(lines, ('  %s %s'):format(c.hash, c.subject or ''))
  end
  table.insert(lines,
    ('%d comment(s) are still here, but they point at commits that are gone. Export them before the state is lost.')
      :format(#state.comments))
  return table.concat(lines, '\n')
end

-- The way out of a stale session: take the comments now, keep reading anyway,
-- or drop it. Asked rather than assumed -- with git-pile and jj a mid-review
-- rewrite is the normal case, and the reader often still wants what is on
-- screen.
function M.offer_export()
  local choices = { 'Export comments to clipboard', 'Keep the stale session', 'Discard the session' }
  vim.ui.select(choices, { prompt = 'Review session is stale — its commits were rewritten:' }, function(choice)
    if choice == choices[1] then
      require('review.export').export()
    elseif choice == choices[3] then
      M.discard()
    end
  end)
end

-- Look for a rewrite; if there was one, mark the session, say what happened and
-- offer the comments up. Runs on restore and on demand (`:Review check`).
-- `opts.quiet` reports without prompting.
function M.check(opts)
  if not state.active or #state.range == 0 then return false end
  local missing = M.missing(state.range)
  state.stale = (#missing > 0) and missing or nil
  require('review.render').set_statusline()
  if not state.stale then return false end
  vim.notify(M.stale_message(missing), vim.log.levels.WARN)
  if not (opts and opts.quiet) then M.offer_export() end
  return true
end

-- Drop the session without exporting, and forget the file with it.
function M.discard()
  M.clear()
  require('review.session').teardown()
  vim.notify('Review session discarded', vim.log.levels.INFO)
end

-- How a restored session announces itself.
local function restored_message()
  local span = state.targeted()
  local where = 'working tree'
  if #span > 1 then
    where = ('%d commit(s), reading %s..%s as one diff'):format(
      #state.range, span[1].hash, span[#span].hash)
  elseif span[1] then
    where = ('%d commit(s), at %s %s'):format(#state.range, span[1].hash, span[1].subject)
  end
  return ('Review session restored (%s, %d comment(s))'):format(where, #state.comments)
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
  state.stale = nil
  if data.auto_form ~= nil then state.auto_form = data.auto_form end
  if data.show_resolved ~= nil then state.show_resolved = data.show_resolved end
  state.active = true

  local render = require('review.render')
  -- What a start would have handed gitsigns: the session's base, or HEAD for a
  -- working-tree session.
  local spec = state.spec or {}
  local base = spec.base or (spec.uncommitted and 'HEAD' or nil)
  if base then
    require('review.session').with_gitsigns(function(gs)
      gs.change_base(base, true)
      gs.toggle_signs(true)
    end)
  end
  render.all()
  render.set_statusline()
  vim.notify(restored_message(), vim.log.levels.INFO)
  -- A stale session gets the warning and the offer instead of a walk: its hunks
  -- would have to be read out of commits that no longer exist.
  if not M.check() then
    -- The walk comes back with the session, but quietly: the reader opened this
    -- editor on a file of their own, not on the quickfix list.
    if state.current then
      require('review.hunks').range_hunks(state.targeted_from, state.current, { quiet = true })
    elseif spec.uncommitted then
      require('review.hunks').worktree_hunks({ quiet = true })
    end
  end
  return true
end

return M
