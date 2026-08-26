-- The lifecycle of a review: what is being reviewed (base, head, working tree),
-- turning that into a changeset, and tearing everything down again.
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

-- Normalize a session spec into the three values the git commands take.
-- `uncommitted` reviews the working tree (staged + unstaged) against HEAD; a
-- bare `base` is used as the base; nothing at all falls back to the default
-- remote branch.
function M.resolve(spec)
  spec = spec or {}
  if spec.uncommitted then return 'HEAD', true, nil end
  local base = (spec.base and spec.base ~= '') and spec.base or M.default_base()
  return base, false, spec.head
end

-- The commits of `base..head`, oldest first: the range a committed session
-- covers.
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

-- Lazy-load gitsigns and run a function against it (keys-lazy plugin).
function M.with_gitsigns(fn)
  pcall(function()
    require('lazy').load({ plugins = { 'gitsigns.nvim' } })
    fn(require('gitsigns'))
  end)
end

-- Start a review: changeset → quickfix, gitsigns base→<base> + signs on, inline
-- comments on, statusline badge. `spec` is { base, head, uncommitted }; an
-- omitted base means the default remote branch, which is the whole branch.
-- Returns false without touching anything when a committed range holds no
-- commits: there is nothing to read, and saying so beats opening a session that
-- looks like a review of nothing.
function M.start(spec)
  local base, uncommitted, head = M.resolve(spec)
  local commits = not uncommitted and M.commits(base, head) or nil
  if commits and #commits == 0 then
    vim.notify(('Review: no commits in %s..%s — nothing to review against %s; review the working tree instead'):format(
      base, (head and head ~= '') and head or 'HEAD', base), vim.log.levels.WARN)
    return false
  end
  state.active = true
  -- A working-tree session has no commits to switch between, so it has no
  -- current commit either.
  if uncommitted then
    state.clear_range()
    state.spec = { uncommitted = true }
    state.save()
  else
    state.set_range(commits, { base = base, head = head })
  end
  M.with_gitsigns(function(gs)
    gs.change_base(base, true)
    gs.toggle_signs(true)
  end)
  -- With commits targeted the changeset is the whole range read as one diff --
  -- the branch as a pull request would show it -- in revision buffers; a
  -- working-tree session's are its own hunks against HEAD, read on disk.
  if state.current then
    hunks.range_hunks(state.targeted_from, state.current)
  else
    hunks.worktree_hunks()
  end
  render.all()
  render.set_statusline()
  local target = uncommitted and 'working tree'
    or ((head and head ~= '') and (base .. '...' .. head) or ('base: ' .. base))
  local span = state.targeted()
  if #span > 1 then
    target = ('%d commit(s) %s..%s as one diff'):format(#span, span[1].hash, span[#span].hash)
  elseif span[1] then
    target = ('1 commit, %s %s'):format(span[1].hash, span[1].subject)
  end
  vim.notify(('Review started (%s)'):format(target), vim.log.levels.INFO)
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

-- Finish a review: export to clipboard, then clear comments, gitsigns off, badge off.
function M.finish()
  export.export() -- copies to clipboard (warns if empty); we tear down regardless
  M.teardown()
  vim.notify('Review finished', vim.log.levels.INFO)
end

-- Everything a session leaves behind, taken down: comments, range, signs, badge
-- and the file on disk. Shared with `persist.discard`, which drops a stale
-- session without exporting it -- and the persisted state goes first, so a
-- crash mid-teardown cannot resurrect a session that was being ended.
function M.teardown()
  require('review.persist').clear()
  -- The review's own keys come off every buffer they were put on: `]f` and
  -- `<Tab>` mean what the editor means again the moment the session ends.
  require('review.buffers').detach_all()
  M.with_gitsigns(function(gs) gs.toggle_signs(false) end)
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

-- One commit of the range, targeted on its own: a targeted range of one, which
-- is the review of a single commit.
function M.set_current(hash)
  return M.target(hash, hash)
end

-- The whole range targeted again, as the session opened on it: one diff of the
-- branch. This is where the switcher's reset key puts the reader back.
function M.target_whole_range()
  local oldest, newest = state.range[1], state.range[#state.range]
  if not oldest then return false end
  return M.target(oldest.hash, newest.hash)
end

-- Target another part of the range from the switcher: one commit chosen, a run
-- of them marked, or the whole range put back. The session itself is untouched
-- by any of the three, because a stack ends as one body of feedback however it
-- was read.
function M.switch_from_picker()
  require('review.pickers').switch_commit({
    choose = function(commit)
      if M.set_current(commit.hash) then
        vim.notify(('Review: at %s %s (%d/%d)'):format(
          commit.hash, commit.subject, state.current_index() or 0, #state.range), vim.log.levels.INFO)
      end
    end,
    span = function(oldest, newest)
      if M.target(oldest, newest) then
        vim.notify(('Review: reading %d commit(s), %s..%s, as one diff'):format(
          #state.targeted(), oldest, newest), vim.log.levels.INFO)
      end
    end,
    reset = function()
      if M.target_whole_range() then
        vim.notify(('Review: reading the whole range, %d commit(s), as one diff'):format(
          #state.range), vim.log.levels.INFO)
      end
    end,
  })
end

return M
