-- The changeset a session reviews, as a quickfix list. It is one entry per hunk,
-- in diff order -- the combined changes of the targeted range, whether that span
-- ends at a commit or at the working tree -- so reading is a walk through the
-- changes rather than through the files, and the walk crosses file boundaries
-- without the reader doing anything about it. A wider stride over the same list
-- walks a file at a time when that is the question instead.
local buffers = require('review.buffers')
local landing = require('review.landing')
local state = require('review.state')

local M = {}

-- --name-status so we can flag added/deleted/renamed files in the qf text;
-- gitsigns only marks hunks within a file (and shows nothing for files absent
-- from the base), so the per-file "new" indicator has to live in the list.
local status_label = { A = '[new] ', D = '[del] ', R = '[ren] ', C = '[cpy] ' }

local function repo_root()
  local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 or not root or root == '' then
    vim.notify('Review: not in a git repo', vim.log.levels.WARN)
    return nil
  end
  return root
end

-- `git diff --name-status <range>` as quickfix items. `locate(status, rel)`
-- decides which buffer an entry opens, which is the only difference between a
-- working-tree list and a commit's own.
local function diff_items(root, range, locate)
  local items = {}
  for _, line in ipairs(vim.fn.systemlist('git -C ' .. root .. ' diff --name-status ' .. range)) do
    -- "A\tpath", "M\tpath", "R100\told\tnew" -- status is the first char, the
    -- path we want is the last tab-separated field.
    local parts = vim.split(line, '\t', { plain = true })
    local status = parts[1]:sub(1, 1)
    local rel = parts[#parts]
    local name = locate(status, rel)
    if name then
      table.insert(items, { filename = name, lnum = 1, text = (status_label[status] or '') .. rel })
    end
  end
  return items
end

-- What the changeset window calls itself: the changeset it holds, and the
-- commit comment when there is one. A commit comment is about exactly this
-- list -- everything the targeted range changed and nothing else -- so the
-- list's own title is where it belongs.
--
-- A span of one names the commit and its subject; a wider one names its two
-- ends and how many commits it covers, because no single subject describes what
-- the reader is looking at.
function M.title()
  local current = state.current_commit()
  local label
  if current then
    local span = state.targeted()
    if #span > 1 then
      label = ('%s..%s %d members (%d/%d)'):format(
        span[1].hash, current.hash, #span, state.current_index() or 0, #state.range)
    elseif state.is_uncommitted(current.hash) then
      label = ('Working tree (%d/%d)'):format(state.current_index() or 0, #state.range)
    else
      label = ('%s %s (%d/%d)'):format(
        current.hash, current.subject, state.current_index() or 0, #state.range)
    end
  else
    label = 'Changed files'
  end
  for _, c in ipairs(state.comments) do
    if c.scope == 'commit' and state.targets(c) then
      local first = c.text:match('[^\n]*') or c.text
      if c.text:find('\n') then first = first .. ' …' end
      return ('%s · %s %s'):format(
        label, (c.status == 'resolved') and '󰄬' or '󰆉', first)
    end
  end
  return label
end

-- Put the title on the list, and on a window already showing it: replacing the
-- title alone leaves an open changeset window's `w:quickfix_title` -- what its
-- statusline reads -- saying whatever it said before.
function M.set_title()
  -- Only a session's own list is retitled: outside one the quickfix list is
  -- whatever the reader put there, and the review has nothing to say about it.
  if not state.active then return end
  local title = M.title()
  vim.fn.setqflist({}, 'r', { title = title })
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      pcall(vim.api.nvim_win_set_var, win.winid, 'quickfix_title', title)
    end
  end
end

local function set_list(items)
  vim.fn.setqflist({}, ' ', { items = items, title = M.title() })
end

-- Show a changeset: replace the quickfix list and land on its first file.
-- `opts.quiet` sets the list without opening or jumping anywhere -- that is how
-- a restored session gets its walk back without taking over the window the
-- reader opened the editor on.
local function show(items, opts)
  if opts and opts.quiet then
    set_list(items)
    return true
  end
  -- Buffer we started from; dropped below so the session opens on a clean,
  -- single-file view (just the first changed file) instead of whatever was open.
  --
  -- Only an ordinary file buffer qualifies. A commit switch is normally made from
  -- the changeset window itself, so the buffer we came from is often the quickfix
  -- buffer -- deleting that closes the window the reader is reading, and leaves a
  -- stale hidden qf buffer whose next reload fires `FileType qf` with no qf window
  -- around it (the crash that used to break the following session start).
  local prev_buf = vim.api.nvim_get_current_buf()
  if vim.bo[prev_buf].buftype ~= '' then prev_buf = nil end
  -- Close any open qf window first: setqflist into an open window reloads its
  -- buffer and fires `FileType qf` while we're still focused elsewhere, which
  -- trips qf_helper's set_qf_defaults (get_win_type() → nil). copen below opens
  -- a fresh window with the qf window focused, so the FileType fires cleanly.
  pcall(vim.cmd, 'cclose')
  set_list(items)
  vim.cmd('copen')
  -- Jump to the first changed file, then drop the buffer we came from.
  if #vim.fn.getqflist() > 0 then
    vim.cmd('cfirst')
    if prev_buf and vim.api.nvim_buf_is_valid(prev_buf)
      and vim.api.nvim_get_current_buf() ~= prev_buf then
      pcall(vim.cmd, 'bdelete ' .. prev_buf)
    end
  else
    -- An empty list would otherwise be silent, and "this commit changes no lines"
    -- (a pure rename, a mode-only change) reads exactly like a list that failed.
    vim.notify('Review: no hunks here', vim.log.levels.INFO)
  end
  return true
end

-- The changeset list put back on screen, exactly as it stands: the same entries
-- and the same position in the walk. Closing the window is how a reader gets the
-- code to themselves, so getting it back must not rebuild anything -- a rebuild
-- would send them to the first hunk of the span and lose where they had read to.
function M.reopen()
  local size = vim.fn.getqflist({ size = 0 }).size or 0
  if size == 0 then
    vim.notify('Review: no changeset to reopen', vim.log.levels.WARN)
    return false
  end
  vim.cmd('copen')
  -- `copen` reloads the window's buffer, so the title it reads is set again here
  -- rather than left saying whatever the last list said.
  M.set_title()
  return true
end

-- Populate the quickfix list with files changed against `base`, using
-- `base...<head>` (merge-base), where <head> defaults to HEAD but may be a
-- single commit (e.g. base=<c>^, head=<c> → just that commit). Entries open the
-- files on disk. This is the list outside a session; a session's own changeset
-- is built by `range_hunks`.
function M.files(base, head)
  local root = repo_root()
  if not root then return false end
  local range = base .. '...' .. ((head and head ~= '') and head or 'HEAD')
  return show(diff_items(root, range, function(_, rel) return root .. '/' .. rel end))
end

-- Where a revision buffer for `rel` lives at `sha`, and the record of what it
-- shows. `base` is what the diff was taken against -- the commit before the
-- targeted range -- and it is carried on the record because the buffer's signs
-- are read against it, not against `sha`'s own parent. `from` is the oldest
-- commit of that span, carried for the same reason a comment carries it: the
-- buffer is a reading of `from`..`sha`, not of `sha` alone. A deleted file has
-- no content at `sha`, so it is shown at `base` -- the last commit where there
-- was anything to read.
local function revision_entry(root, base, from, sha, rel, status)
  local at = (status == 'D') and base or sha
  local name = buffers.name(at, rel, root)
  if not name then return nil end
  buffers.register(name,
    { sha = sha, rel = rel, root = root, status = status, from = from, base = base })
  return name
end

-- The hunks of one `git diff --unified=0` run, in diff order, as quickfix items.
--
-- The hunk headers are the whole source: they give a file's changes as line
-- ranges without any content around them, and they need no buffer open, which
-- is what makes an arbitrary commit's hunks reachable at all -- gitsigns can
-- only collect from buffers it has attached to.
--
-- `locate(rel, status)` names the buffer an entry opens, which is the only
-- difference between a committed changeset and the working tree's.
local function hunk_items(out, locate)
  local items = {}
  local status, old_rel, file
  for _, line in ipairs(out) do
    if vim.startswith(line, 'diff --git ') then
      status, old_rel, file = 'M', nil, nil
    elseif vim.startswith(line, 'new file mode') then
      status = 'A'
    elseif vim.startswith(line, 'deleted file mode') then
      status = 'D'
    elseif vim.startswith(line, 'rename from') then
      status = 'R'
    elseif vim.startswith(line, 'copy from') then
      status = 'C'
    elseif vim.startswith(line, '--- ') then
      old_rel = line:sub(5):gsub('^a/', '')
    elseif vim.startswith(line, '+++ ') then
      local new_rel = line:sub(5)
      -- A deleted file's new side is /dev/null; its own path is on the old side.
      local deleted = new_rel == '/dev/null'
      local rel = deleted and old_rel or new_rel:gsub('^b/', '')
      local name = rel and locate(rel, status)
      file = name and { rel = rel, name = name, deleted = deleted } or nil
    elseif file and vim.startswith(line, '@@') then
      local old_start, old_count, new_start, new_count, context =
        line:match('^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@(.*)$')
      if old_start then
        -- The line to land on is the hunk's first line in the buffer the entry
        -- opens: the new side normally, the old side for a file shown at the
        -- parent. A pure deletion reads `+N,0`, where N is the line the removed
        -- text sat after, so the reader lands next to the gap.
        local lnum = math.max(1, tonumber(file.deleted and old_start or new_start))
        local count = tonumber(file.deleted and old_count or new_count) or 1
        local ctx = vim.trim(context)
        table.insert(items, {
          filename = file.name,
          -- `module` is what the quickfix window prints in place of the file
          -- name, so the reader sees `lua/review/hunks.lua` where the raw
          -- fugitive URL -- git dir, sha and path -- would otherwise be; the
          -- entry still opens `filename`, the revision buffer.
          module = file.rel,
          lnum = lnum,
          -- With an end the window renders the hunk's span itself as `|12-18|`,
          -- which is why neither the range nor the path is in the text.
          end_lnum = math.max(lnum, lnum + count - 1),
          text = ('%s%s'):format(status_label[status] or '', ctx),
        })
      end
    end
  end
  return items
end

-- The hunks a targeted range changed: one diff of the whole span, taken against
-- the member before its oldest. Entries open revision buffers at `newest`, so
-- reading the list reads the span's own content and never the working tree's --
-- and a file several commits of the span touched appears once, at the version
-- the span leaves behind, rather than once per commit at versions that share a
-- path and nothing else.
--
-- A single commit is the span where `oldest` and `newest` are the same commit,
-- and the diff is then that commit's own.
--
-- A span ending at the Uncommitted Tip is the same one diff with its second ref
-- left off -- which is what `git diff <ref>` means -- and its entries open the
-- files on disk: no read-only view of a commit can hold uncommitted content, and
-- these are the changes the reader can still edit. A file the span deleted has
-- nothing left on disk to open, so it is read at the base, the last place it had
-- content. Untracked files are added to that diff on their own (see
-- untracked_diff), because a file git has never seen is uncommitted work like
-- any other.
-- The files git is not tracking yet, each as the diff that adds it. `git diff
-- <ref>` cannot mention them -- they are in no tree it compares -- so a file
-- written during the review would be uncommitted work the changeset never
-- showed. `--no-index` against /dev/null gives each one the shape every other
-- entry is parsed from: a new file, whole, added at line 1.
local function untracked_diff(root)
  local out = {}
  local files = vim.fn.systemlist({ 'git', '-C', root, 'ls-files', '--others', '--exclude-standard' })
  if vim.v.shell_error ~= 0 then return out end
  for _, rel in ipairs(files) do
    -- `--no-index` exits 1 when the two sides differ, which they always do here,
    -- so the exit code says nothing and only the output is read.
    vim.list_extend(out, vim.fn.systemlist({ 'git', '-C', root, '--no-pager', 'diff',
      '--no-index', '--unified=0', '--no-color', '--', '/dev/null', rel }))
  end
  return out
end

function M.range_hunks(oldest, newest, opts)
  local root = repo_root()
  if not root then return false end
  local base = buffers.parent(oldest, root)
  local worktree = state.is_uncommitted(newest)
  local out = vim.fn.systemlist(('git -C %s diff --unified=0 --no-color %s%s'):format(
    root, base, worktree and '' or (' ' .. newest)))
  if worktree then vim.list_extend(out, untracked_diff(root)) end
  return show(hunk_items(out, function(rel, status)
    if worktree and status ~= 'D' then return root .. '/' .. rel end
    return revision_entry(root, base, oldest, newest, rel, status)
  end), opts)
end

-- The walk through those hunks. It wraps at both ends on purpose: running past
-- the last hunk back to the first is how the reader learns the span is read,
-- and nothing here ever steps outside the targeted range -- changing what is
-- targeted is session.target's job alone.
local function jump(idx)
  local size = vim.fn.getqflist({ size = 0 }).size or 0
  if size == 0 then return false end
  vim.cmd(('%dcc'):format(idx))
  landing.land()
  M.on_arrival()
  return true
end

local function walk(step)
  local qf = vim.fn.getqflist({ idx = 0, size = 0 })
  local size = qf.size or 0
  if size == 0 then return false end
  -- ((i - 1 + step) % size) + 1 -- forward off the end lands on 1, back off the
  -- front lands on the last.
  return jump(((qf.idx - 1 + step) % size) + 1)
end

function M.next_hunk() return walk(1) end
function M.prev_hunk() return walk(-1) end

-- The last line of the hunk the cursor is sitting at the top of, when it is
-- one -- the current changeset entry, matched by buffer and by the cursor
-- standing exactly on its first line. Nil off the walk (a manual comment, a
-- foreign qf list, a buffer the current entry isn't about), so a caller falls
-- back to whatever line it already knows about.
function M.current_hunk_end(bufnr, lnum)
  local qf = vim.fn.getqflist({ idx = 0, items = 0 })
  local item = (qf.items or {})[qf.idx]
  if item and item.bufnr == bufnr and item.lnum == lnum and item.end_lnum and item.end_lnum > 0 then
    return item.end_lnum
  end
  return nil
end

-- The file a changeset entry belongs to. `module` carries it for every entry
-- the plugin builds; a list from somewhere else falls back to the buffer name,
-- which for a file on disk is the file. Public because the comment walk reads
-- the changeset for its file order, and must read it exactly the way the file
-- stride does.
function M.entry_file(item)
  if item.module and item.module ~= '' then return item.module end
  if item.bufnr and item.bufnr > 0 then return vim.api.nvim_buf_get_name(item.bufnr) end
  return ''
end

-- Where the file stride lands going `step` files from `idx`. A file's hunks are
-- contiguous -- the changeset is in diff order -- so the stride is the same list
-- read wider, with no second list to keep in step. Both directions land on the
-- target file's *first* hunk, so where the reader stood inside the file they are
-- leaving never shows in where they arrive.
local function file_target(items, idx, step)
  local size = #items
  local here = M.entry_file(items[idx])
  local found, i = nil, idx
  for _ = 1, size do
    i = ((i - 1 + step) % size) + 1
    if M.entry_file(items[i]) ~= here then
      found = i
      break
    end
  end
  -- Only one file in the changeset: the wrap brings the reader back to its start.
  if not found then
    for j = 1, size do
      if M.entry_file(items[j]) == here then return j end
    end
    return nil
  end
  if step < 0 then
    -- Backwards we met the previous file's last hunk; back up to where it began.
    local file = M.entry_file(items[found])
    while true do
      local prev = ((found - 2) % size) + 1
      if prev == idx or M.entry_file(items[prev]) ~= file then break end
      found = prev
    end
  end
  return found
end

local function walk_file(step)
  local qf = vim.fn.getqflist({ idx = 0, items = 0 })
  local items = qf.items or {}
  if #items == 0 then return false end
  local idx = math.min(math.max(qf.idx or 1, 1), #items)
  local target = file_target(items, idx, step)
  return target ~= nil and jump(target)
end

function M.next_file() return walk_file(1) end
function M.prev_file() return walk_file(-1) end

function M.first_hunk()
  return jump(1)
end

function M.last_hunk()
  return jump(vim.fn.getqflist({ size = 0 }).size or 1)
end

-- Landing on a hunk with the auto-form toggle on opens the comment form there,
-- so a reading pass and a commenting pass are one pass. Scheduled because the
-- quickfix jump has to finish moving the cursor before the form reads it.
function M.on_arrival()
  if not state.auto_form then return end
  vim.schedule(function() state.add_normal() end)
end

return M
