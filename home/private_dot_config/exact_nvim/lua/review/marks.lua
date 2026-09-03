-- The Diff Marks: what the Targeted Range changed, drawn on the buffers that
-- hold it. Signs for the lines a hunk added or changed, and the removed text
-- itself where it was taken from.
--
-- These come from the review's own diff -- the single `git diff --unified=0`
-- run the Changeset is built from -- rather than from a signs plugin asked to
-- re-derive them per buffer. That is what makes them uniform: a plugin that
-- attaches to buffers has to have attached, has to have been given the right
-- base, and refuses whole classes of file (untracked ones, files over its
-- length limit, files with `-diff` set), and every one of those refusals is
-- silent. The review already knows the answer for every entry in its walk, so
-- the marks are the same fact the quickfix list is: read once, from git, for
-- the whole span.
local state = require('review.state')

local M = {}

local ns = vim.api.nvim_create_namespace('glebglazov-review-diff')

-- Gruvbox, matching the review's own palette in `render`: green added, yellow
-- changed, red removed.
vim.api.nvim_set_hl(0, 'ReviewDiffAdd', { fg = '#b8bb26' })
vim.api.nvim_set_hl(0, 'ReviewDiffChange', { fg = '#fabd2f' })
vim.api.nvim_set_hl(0, 'ReviewDiffDelete', { fg = '#fb4934' })
-- The removed text itself. Linked rather than coloured, because a whole line of
-- it sits among the file's own syntax highlighting and has to read as the
-- colourscheme's idea of deleted text there.
vim.api.nvim_set_hl(0, 'ReviewDiffRemoved', { link = 'DiffDelete', default = true })

-- A thinner bar than a comment's `▌`, and drawn under it: the sign cell belongs
-- to a comment wherever there is one, because the marks are the diff the reader
-- can see anyway and the comment is the thing they wrote.
local SIGN = '│'
local SIGN_GONE = '▁'
local PRIORITY = 10

-- What the span changed, keyed by repository-relative path -- one record per
-- file, because a Changeset holds each file once however many members touched
-- it. `deleted` says the buffer holds the removed side (a file read at the base,
-- the last place it had content).
local marks = {}

-- Where the records came from, so one file's can be asked again after a write.
local ctx = nil

-- The reader's two toggles. Neither is persisted: they are how a file is looked
-- at for a moment, not part of what is being reviewed.
M.signs = true
M.deleted = true

-- One `git diff --unified=0` run as per-file records. The content lines are kept
-- and not just the `@@` headers the Changeset walk is built from, because the
-- removed text exists nowhere else: no buffer of the review holds a line the
-- span took out.
local function parse(out)
  local files = {}
  local file, hunk, old_rel = nil, nil, nil
  for _, line in ipairs(out) do
    if vim.startswith(line, 'diff --git ') then
      file, hunk, old_rel = nil, nil, nil
    elseif vim.startswith(line, '--- ') then
      old_rel = line:sub(5):gsub('^a/', '')
    elseif vim.startswith(line, '+++ ') then
      -- A deleted file's new side is /dev/null; its own path is on the old side,
      -- and the buffer for it is read at the base.
      local new_rel = line:sub(5)
      local deleted = new_rel == '/dev/null'
      local rel = deleted and old_rel or new_rel:gsub('^b/', '')
      hunk = nil
      if rel and rel ~= '/dev/null' then
        file = { deleted = deleted, hunks = {} }
        files[rel] = file
      else
        file = nil
      end
    elseif file and vim.startswith(line, '@@') then
      -- An omitted count means one line: `@@ -5 +5,2 @@`.
      local old_start, old_count, new_start, new_count =
        line:match('^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@')
      if old_start then
        hunk = {
          old_start = tonumber(old_start),
          old_count = tonumber(old_count) or 1,
          new_start = tonumber(new_start),
          new_count = tonumber(new_count) or 1,
          removed = {},
        }
        table.insert(file.hunks, hunk)
      else
        hunk = nil
      end
    elseif hunk and vim.startswith(line, '-') then
      table.insert(hunk.removed, line:sub(2))
    end
  end
  return files
end

local function removed_lines(hunk)
  local out = {}
  for _, line in ipairs(hunk.removed) do
    table.insert(out, { { line, 'ReviewDiffRemoved' } })
  end
  return out
end

-- One hunk's marks, in the buffer that holds it:
--
--   * a file read at the base holds the removed side, so its own lines *are*
--     the deletion and there is nothing to draw above them;
--   * a pure deletion has no line of its own -- `+N,0` means the removed text
--     sat after line N -- so the sign goes on that line and the text below it;
--   * anything else marks the lines it left behind, with whatever it removed
--     drawn above the first of them.
local function draw(bufnr, hunk, deleted, total)
  local function set(lnum, opts)
    if lnum < 1 or lnum > total then return end
    opts.priority = PRIORITY
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, lnum - 1, 0, opts)
  end
  local function sign(lnum, hl)
    if M.signs then set(lnum, { sign_text = SIGN, sign_hl_group = hl }) end
  end

  if deleted then
    for l = hunk.old_start, hunk.old_start + hunk.old_count - 1 do
      sign(l, 'ReviewDiffDelete')
    end
    return
  end

  if hunk.new_count == 0 then
    if M.signs then
      set(math.max(1, hunk.new_start),
        { sign_text = SIGN_GONE, sign_hl_group = 'ReviewDiffDelete' })
    end
    if M.deleted and #hunk.removed > 0 then
      -- `+0,0` is text removed from before the first line -- the one case where
      -- it goes above the anchor rather than below it.
      set(math.max(1, hunk.new_start),
        { virt_lines = removed_lines(hunk), virt_lines_above = hunk.new_start == 0 })
    end
    return
  end

  local hl = (#hunk.removed > 0) and 'ReviewDiffChange' or 'ReviewDiffAdd'
  for l = hunk.new_start, hunk.new_start + hunk.new_count - 1 do
    sign(l, hl)
  end
  if M.deleted and #hunk.removed > 0 then
    set(hunk.new_start, { virt_lines = removed_lines(hunk), virt_lines_above = true })
  end
end

-- The record for a buffer, when its lines are the span's own. The rule is the
-- comments' rule: a mark is a line number, and a Working Copy read while
-- commits are targeted shows HEAD at line numbers that are not the span's, so
-- there is nowhere true to put one.
local function record_for(bufnr)
  local loc = require('review.buffers').locate(bufnr)
  if not loc then return nil end
  if not (loc.revision or state.is_uncommitted(loc.commit)) then return nil end
  if loc.commit ~= state.current or loc.from ~= state.targeted_from then return nil end
  return marks[loc.rel]
end

-- What one buffer shows of the span's diff, drawn from scratch. Cheap enough to
-- be the only way marks are ever put on a buffer -- every entry into one redraws
-- it -- because a Revision Buffer is deleted the moment the reader jumps away.
function M.buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if not state.active then return end
  local record = record_for(bufnr)
  if not record then return end
  local total = vim.api.nvim_buf_line_count(bufnr)
  for _, hunk in ipairs(record.hunks) do
    draw(bufnr, hunk, record.deleted, total)
  end
end

function M.all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then M.buffer(bufnr) end
  end
end

-- The span's diff, taken as the Changeset was built. `out` is the same command
-- output the list is parsed from, so the marks and the walk can never disagree
-- about what the span changed.
function M.set(out, context)
  marks, ctx = parse(out), context
  M.all()
end

-- Everything the marks put on the editor, taken off: the end of a session, and
-- nothing else. Extmarks are per buffer, so this is the whole of it -- no
-- global option and no other plugin's config is touched, which is why a session
-- ending cannot follow the reader into the next file they open.
function M.clear()
  marks, ctx = {}, nil
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
  end
end

function M.toggle_signs()
  M.signs = not M.signs
  M.all()
  vim.notify('Review: diff signs ' .. (M.signs and 'on' or 'off'), vim.log.levels.INFO)
end

function M.toggle_deleted()
  M.deleted = not M.deleted
  M.all()
  vim.notify('Review: removed lines ' .. (M.deleted and 'shown' or 'hidden'), vim.log.levels.INFO)
end

-- Whether git is tracking `rel` at all. An untracked file is in no tree `git
-- diff` compares, so its own diff has to be asked for the way the Changeset
-- asks for it -- against /dev/null -- and a tracked file with nothing left to
-- show must not fall through to that, or reverting a file would mark the whole
-- of it as added.
local function tracked(root, rel)
  local out = vim.fn.systemlist({ 'git', '-C', root, 'ls-files', '--', rel })
  return vim.v.shell_error == 0 and out[1] ~= nil and out[1] ~= ''
end

-- One file's marks asked again. A Revision Buffer cannot be written, so this is
-- only ever a file on disk while the span ends at the Uncommitted Tip -- and one
-- file's diff is a fraction of the span's, which is what makes it cheap enough
-- to run on every write and every entry into the buffer.
function M.refresh(bufnr)
  if not state.active or not ctx or not ctx.worktree then return end
  local loc = require('review.buffers').locate(bufnr)
  if not loc or loc.revision then return end
  local args
  if tracked(ctx.root, loc.rel) then
    args = { 'git', '-C', ctx.root, '--no-pager', 'diff', '--unified=0', '--no-color',
      ctx.base, '--', loc.rel }
  else
    args = { 'git', '-C', ctx.root, '--no-pager', 'diff', '--no-index', '--unified=0',
      '--no-color', '--', '/dev/null', loc.rel }
  end
  -- `--no-index` exits 1 whenever the two sides differ, which here they always
  -- do, so only the output is read.
  marks[loc.rel] = parse(vim.fn.systemlist(args))[loc.rel]
  M.buffer(bufnr)
end

return M
