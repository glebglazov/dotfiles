-- Revision buffers: a file as it stood at one commit, read-only, with that
-- commit's own hunks in the sign column. Nothing is checked out, so HEAD, the
-- index and the working tree never move, no buffer reloads, no language server
-- re-indexes, and a dirty tree is no obstacle.
--
-- Every place the plugin needs commit content goes through this one seam --
-- "give me a buffer for (sha, path)" -- so the scratch-worktree alternative in
-- docs/adr/0001 can replace it without touching session state, comments or the
-- export.
local M = {}

-- git's empty tree: what a root commit's content is read against, so its files
-- read as wholly added rather than as no change at all.
local EMPTY_TREE = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'

-- What each revision buffer shows, keyed by buffer name. The name alone carries
-- the commit and the path, but neither the diff status that produced it nor the
-- commit it was diffed against -- and a file is read as part of a whole span,
-- whose base is not its own commit's parent, while a deleted file has no hunks
-- of its own and no working-tree twin. Both have to be remembered when the
-- changeset is built.
local shown = {}

-- Split a `fugitive://<gitdir>//<sha>/<rel>` name back into its parts. Buffers
-- opened by some other route (`:Gclog`, `:Gedit`) parse the same way, so they
-- get the same treatment during a session.
function M.parse(name)
  if not vim.startswith(name or '', 'fugitive://') then return nil end
  local parts = vim.split(name, '//', { plain = true })
  local gitdir, tail = parts[2], parts[3]
  if not gitdir or not tail then return nil end
  local sha, rel = tail:match('^([^/]+)/(.+)$')
  if not sha or rel == '' then return nil end
  return { sha = sha, rel = rel, gitdir = gitdir }
end

function M.is_revision(name)
  return M.parse(name) ~= nil
end

-- The commit before `sha`: what a changeset beginning at `sha` is diffed
-- against, and so what the revision buffers of that changeset show their signs
-- against. A root commit has no parent, so its content reads against the empty
-- tree -- wholly added rather than unchanged. The Uncommitted Tip sits past
-- HEAD, so what comes before it is HEAD itself.
function M.parent(sha, root)
  if require('review.state').is_uncommitted(sha) then return 'HEAD' end
  local out = vim.fn.systemlist({
    'git', '-C', root or vim.fn.getcwd(), 'rev-parse', '--verify', '--quiet', sha .. '^',
  })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == '' then return EMPTY_TREE end
  return out[1]
end

-- Fugitive addresses a repo by its git dir, not by its work tree, and asking
-- git for it costs a process -- so each work tree's is looked up once.
local gitdirs = {}
function M.gitdir(root)
  root = root or vim.fn.getcwd()
  if gitdirs[root] == nil then
    local out = vim.fn.systemlist({ 'git', '-C', root, 'rev-parse', '--absolute-git-dir' })
    gitdirs[root] = (vim.v.shell_error == 0 and out[1] and out[1] ~= '') and out[1] or false
  end
  return gitdirs[root] or nil
end

-- The buffer name holding `rel` (repo-relative) as of `sha`. Nil when the
-- object does not exist at that commit.
function M.name(sha, rel, root)
  local dir = M.gitdir(root)
  if not dir then return nil end
  local ok, name = pcall(vim.fn.FugitiveFind, sha .. ':' .. rel, dir)
  if not ok or type(name) ~= 'string' or not vim.startswith(name, 'fugitive://') then return nil end
  return name
end

-- Record what a name was opened to show. The changeset builder calls this so a
-- buffer knows its diff status before anyone opens it.
function M.register(name, info)
  shown[name] = info
end

-- What `name` shows, from the record if there is one and from the name itself
-- otherwise.
function M.info(name)
  local known = shown[name]
  if known then return known end
  local parsed = M.parse(name)
  if not parsed then return nil end
  return { sha = parsed.sha, rel = parsed.rel, status = 'M' }
end

-- A buffer name of either kind as a repository-relative path -- the half of a
-- comment's identity that is not the commit. This is what converts a session
-- saved before comments knew their own path.
function M.display_path(name, root)
  local info = M.info(name)
  if info then return info.rel end
  if root and root ~= '' and name:sub(1, #root) == root then return name:sub(#root + 2) end
  return name
end

-- What a buffer is about, as a comment records it: the span of the range it was
-- opened as part of -- `from`..`commit`, oldest and newest -- and the path it
-- holds inside the repository. A revision buffer carries its span on the record
-- the changeset builder left; a file on disk is the span the session is reading
-- now -- which is the span itself when that span ends at the Uncommitted Tip --
-- so the two resolve to the same triple and to the same comments. A buffer
-- of some other route (`:Gedit`, `:Gclog`) has no record, and is the one commit
-- its name names. Nil for a buffer the review cannot place -- one with no name,
-- or a file outside this repository.
--
-- This is the one seam between a buffer and a comment's identity: widen it and
-- everything that draws, adds, finds or deletes a comment widens with it.
function M.locate(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name == '' then return nil end
  local state = require('review.state')
  local info = M.info(name)
  if info then
    return { from = info.from or info.sha, commit = info.sha, rel = info.rel, revision = true }
  end
  local root = state.repo_root()
  if not root or root == '' or name:sub(1, #root + 1) ~= root .. '/' then return nil end
  return {
    from = state.targeted_from,
    commit = state.current,
    rel = name:sub(#root + 2),
    revision = false,
  }
end

-- The keys that live only on the review's own surfaces. `]e`, `]f` and `<Tab>`
-- all shadow something the editor already means, so they are attached to the
-- buffers a session is reading and to the changeset window, and to nothing
-- else -- which is also why no walk has to warn "no session": outside a session
-- the keys are not there to press.
local local_keys = {}

-- Buffers we have attached to, so the end of a session can give the keys back.
local attached = {}

-- The tab the reader left the review for, while an investigation is open. See
-- M.investigate.
local investigation = nil

-- The tab the review is read in. The review knows it from the moment a session
-- starts or is restored, rather than noticing it on the way out, so the way back
-- never depends on the reader having left by a particular key. Nothing defends
-- it -- see docs/adr/0005: when it is gone, M.home builds another one out of the
-- session's own state.
local review_tab = nil

-- `setup{}` hands over the review-local half of its key table once; every
-- attachment below binds exactly this.
function M.set_local_keys(maps)
  local_keys = maps or {}
end

-- Does this buffer belong to the session being read? A span of commits is read
-- in revision buffers, which we registered ourselves; a span ending at the
-- Uncommitted Tip is read in real files, which are the session's only by being
-- in its changeset. The
-- changeset window counts too -- it is where the walk is steered from.
function M.member(bufnr)
  if not require('review.state').active then return false end
  if vim.bo[bufnr].buftype == 'quickfix' then return true end
  if M.info(vim.api.nvim_buf_get_name(bufnr)) then return true end
  for _, item in ipairs(vim.fn.getqflist({ items = 0 }).items or {}) do
    if item.bufnr == bufnr then return true end
  end
  return false
end

-- Put the review's keys on one buffer, or take them off again when the buffer
-- has stopped being part of a session.
function M.attach(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if not M.member(bufnr) then
    if attached[bufnr] then M.detach(bufnr) end
    return
  end
  if attached[bufnr] then return end
  for _, map in ipairs(local_keys) do
    vim.keymap.set(map.mode, map.lhs, map.fn,
      { buffer = bufnr, silent = true, nowait = true, desc = map.desc })
  end
  attached[bufnr] = true
end

-- Whether `bufnr` currently carries the review's keys, for callers (and tests)
-- that need to tell "attached" from "never attached" and "forgotten" apart.
function M.is_attached(bufnr)
  return attached[bufnr] == true
end

function M.detach(bufnr)
  attached[bufnr] = nil
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  for _, map in ipairs(local_keys) do
    pcall(vim.keymap.del, map.mode, map.lhs, { buffer = bufnr })
  end
end

-- The end of a session hands `]f` and `<Tab>` back everywhere at once, rather
-- than leaving them shadowed on whatever buffers the reader had open.
function M.detach_all()
  for bufnr in pairs(vim.deepcopy(attached)) do M.detach(bufnr) end
  -- The next session gets its own tabs: a fresh home, and a fresh investigation
  -- to leave it for, rather than the ones the last reader left open.
  investigation = nil
  review_tab = nil
end

-- gitsigns attaches to these buffers asynchronously and only takes a
-- buffer-local base for the buffer that is current, so the base lands on a
-- retry -- and only while the buffer is still the one in front of the user.
-- Abandoning is safe: the next BufEnter dresses it again.
local function apply_base(bufnr, base, tries)
  if vim.api.nvim_get_current_buf() ~= bufnr then return end
  if vim.b[bufnr].gitsigns_status_dict then
    pcall(function()
      require('lazy').load({ plugins = { 'gitsigns.nvim' } })
      require('gitsigns').change_base(base)
    end)
    vim.b[bufnr].review_base = base
    return
  end
  if tries <= 0 then return end
  vim.defer_fn(function() apply_base(bufnr, base, tries - 1) end, 50)
end

-- Make a revision buffer read what it should: never writable, and diffed
-- against the commit before the span it is being read as part of. Without the
-- base change gitsigns sets the buffer's base to the very commit it is showing,
-- which yields no signs at all -- and pinning it to the span's base rather than
-- to the commit's own parent is what makes the signs the whole span's changes.
function M.dress(bufnr)
  if not require('review.state').active then return end
  local name = vim.api.nvim_buf_get_name(bufnr)
  local info = M.info(name)
  if not info then return end
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true
  -- A file the span deleted is shown at the base, where it still had content; it
  -- has no hunks of its own, so it gets no signs.
  if info.status == 'D' then return end
  if vim.b[bufnr].review_base then return end
  apply_base(bufnr, info.base or M.parent(info.sha, info.root), 40)
end

-- Whether `sha` holds `rel` at all. Asked here rather than left to the read:
-- fugitive builds a name for a path a commit does not hold and only fails when
-- the buffer is loaded, leaving the reader on an empty buffer with git's own
-- fatal in the messages. A comment refiled onto HEAD by a rewrite keeps the path
-- it was written against, so a path the commit does not hold is a thing this
-- seam is asked for in normal use.
local function holds(sha, rel, root)
  vim.fn.system({ 'git', '-C', root or vim.fn.getcwd(), 'cat-file', '-e', sha .. ':' .. rel })
  return vim.v.shell_error == 0
end

-- Open `rel` as of `sha` in the current window. The direct form of the seam --
-- the changeset list reaches the same buffers through quickfix entries.
--
-- Opening the newest commit of the span being read opens it as part of that
-- span: the signs are the span's changes and a comment made here belongs to the
-- span, the same as one made in a buffer the changeset opened. Any other commit
-- is only itself.
function M.open(sha, rel, root)
  local name = M.name(sha, rel, root)
  if not name or not holds(sha, rel, root) then
    vim.notify(('Review: %s does not exist at %s'):format(rel, sha), vim.log.levels.WARN)
    return nil
  end
  local state = require('review.state')
  local from = (sha == state.current and state.targeted_from) or sha
  M.register(name,
    { sha = sha, rel = rel, root = root, status = 'M', from = from, base = M.parent(from, root) })
  vim.cmd('edit ' .. vim.fn.fnameescape(name))
  return vim.api.nvim_get_current_buf()
end

local function tab_valid(tab)
  return tab ~= nil and vim.api.nvim_tabpage_is_valid(tab)
end

-- The Review Tab: where the review is read, and the one place in the editor a
-- single key always leads. It is never protected -- an ordinary file opened into
-- it by habit is a non-event -- because everything it holds can be laid out
-- again from the session, which is what the rest of this section does.

-- Adopt the current tab as the review's home. Called by everything that opens a
-- review -- a fresh start, a restored session, a rebuild -- so the home is
-- always the tab the changeset was last laid out in.
function M.set_review_tab(tab)
  review_tab = tab or vim.api.nvim_get_current_tabpage()
end

-- Which tab that is, while it still exists, for anything that has to tell the
-- review's tab from the investigation's.
function M.review_tab()
  return tab_valid(review_tab) and review_tab or nil
end

-- The review's home laid out from scratch: the changeset list, the entry being
-- read in the window beside it, and the cursor on that entry's hunk. This is all
-- the Review Tab ever holds, and every part of it is read back out of the
-- session -- which is what makes losing the tab a non-event.
local function lay_out(idx)
  require('review.hunks').reopen()
  -- From the changeset window `cc` opens the entry in the window beside it and
  -- takes the reader there, so the layout comes out the same whether the list
  -- was already on screen or has just been put back.
  vim.cmd(('%dcc'):format(idx))
  require('review.landing').land()
  return true
end

-- Back to the review, from anywhere in the editor. From another tab it is the
-- review exactly as the reader left it; pressed in the review's own tab -- where
-- a file search has usually just dropped a working-tree file over the top of it
-- -- it lays the reading position out again; and with the tab gone it builds the
-- review in a new one. Nothing here depends on a window, a buffer or a tab
-- having survived, only on the session.
function M.home()
  if not require('review.state').active then
    vim.notify('Review: no session to go back to', vim.log.levels.WARN)
    return false
  end
  if tab_valid(review_tab) and vim.api.nvim_get_current_tabpage() ~= review_tab then
    vim.api.nvim_set_current_tabpage(review_tab)
    return true
  end
  local qf = vim.fn.getqflist({ idx = 0, size = 0 })
  local size = qf.size or 0
  if size == 0 then
    vim.notify('Review: no changeset to go back to', vim.log.levels.WARN)
    return false
  end
  if not tab_valid(review_tab) then
    vim.cmd('tabnew')
    review_tab = vim.api.nvim_get_current_tabpage()
  end
  return lay_out(math.min(math.max(qf.idx or 1, 1), size))
end

-- The Investigation Tab: the working-tree copy of the file being read, in a tab
-- of its own. Reading a commit answers what changed; investigating answers what
-- the code around it does now, which needs whole files and a language server --
-- and a Revision Buffer is not a file on disk, so it has neither.
--
-- Keeping it in another tab is what makes the trip free: the review's windows,
-- its cursor and its changeset window are never touched, so coming back needs no
-- restoring. The reader may wander across as many files as they like in there.

-- Leave the review to investigate, or come back from investigating. One key
-- both ways: which one it means is which tab it is pressed in.
function M.investigate()
  -- The way back is the review's own way home, so an investigation outlives the
  -- tab it was started from: the review is rebuilt rather than reported missing.
  if investigation and vim.api.nvim_get_current_tabpage() == investigation.tab then
    return M.home()
  end

  local name = vim.api.nvim_buf_get_name(0)
  local info = M.info(name)
  if not M.parse(name) or not info then
    vim.notify('Review: not a revision buffer', vim.log.levels.WARN)
    return false
  end
  local lnum, col = vim.fn.line('.'), vim.fn.col('.')
  local ok, path = pcall(vim.fn.FugitiveReal, name)
  if not ok or type(path) ~= 'string' or path == '' then
    path = (info.root and (info.root .. '/' .. info.rel)) or info.rel
  end
  if vim.fn.filereadable(path) == 0 then
    vim.notify(('Review: %s is not in the working tree'):format(info.rel), vim.log.levels.WARN)
    return false
  end

  -- One tab for the whole investigation: a second trip out lands in the tab the
  -- reader was already investigating in, with whatever they had opened there.
  if tab_valid(investigation and investigation.tab) then
    vim.api.nvim_set_current_tabpage(investigation.tab)
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
  else
    vim.cmd('tabedit ' .. vim.fn.fnameescape(path))
    investigation = { tab = vim.api.nvim_get_current_tabpage() }
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { math.min(lnum, vim.api.nvim_buf_line_count(0)), col - 1 })
  require('review.landing').land()
  return true
end

-- Which tab is the Investigation Tab, for the tests and for anything that has to
-- tell the two apart.
function M.investigation_tab()
  return tab_valid(investigation and investigation.tab) and investigation.tab or nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup('glebglazov-review-buffers', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufEnter', 'FileType' }, {
    group = group,
    callback = function(args)
      M.dress(args.buf)
      M.attach(args.buf)
    end,
  })
  -- Buffer-local keys die with the buffer they were set on, and `attach`'s
  -- early return reads the stale `true` left here as "already attached" -- so
  -- once a buffer has gone away the review's keys never come back to it.
  -- Revision buffers make this the common case, not the corner one: fugitive
  -- gives its blob buffers `bufhidden=delete`, so every jump away from a file
  -- deletes it, and the same buffer number is reloaded on the way back.
  -- Forgetting the number on unload, delete or wipe is what makes the next
  -- BufReadPost see it as new and bind the keys again.
  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufDelete', 'BufWipeout' }, {
    group = group,
    callback = function(args) attached[args.buf] = nil end,
  })
end

return M
