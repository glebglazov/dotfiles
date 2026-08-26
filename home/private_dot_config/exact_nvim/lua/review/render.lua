-- Everything the reviewer sees of the comment store: sign-column range bars,
-- inline labels at the head line of each comment, and the statusline badge.
local state = require('review.state')

local M = {}

local ns = vim.api.nvim_create_namespace('glebglazov-review')
local default_statusline = vim.o.statusline

-- Muted, easy-on-the-eyes review statusline badge (gruvbox neutral aqua on bg1).
vim.api.nvim_set_hl(0, 'ReviewStatus', { fg = '#83a598', bg = '#3c3836', bold = true })
-- Left-margin range bars: aqua while unresolved, muted grey once resolved.
vim.api.nvim_set_hl(0, 'ReviewBar', { fg = '#83a598' })
vim.api.nvim_set_hl(0, 'ReviewBarResolved', { fg = '#665c54' })

-- A file comment is about no line, so it is drawn as lines of its own above the
-- first: the reader meets it on opening the file, before anything in it.
local function file_lines(c, resolved)
  local hl = resolved and 'Comment' or 'DiagnosticVirtualTextInfo'
  local out = {}
  for i, line in ipairs(vim.split(c.text, '\n', { plain = true })) do
    local prefix = (i == 1) and ((resolved and '󰄬' or '󰆉') .. ' file: ') or '        '
    table.insert(out, { { prefix .. line, hl } })
  end
  return out
end

-- What one buffer shows of the store. The buffer is resolved to the span of
-- commits and the path it holds rather than compared by name, so the same file
-- opened as commit content and off disk draws the same comments -- and a
-- comment written against another span is left undrawn, because the diff it was
-- about is not the diff on screen.
function M.buffer(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if #state.comments == 0 then return end
  local loc = require('review.buffers').locate(bufnr)
  if not loc then return end
  local total = vim.api.nvim_buf_line_count(bufnr)
  -- A file on disk shows HEAD rather than the commit being read, so its line
  -- numbers are not the comment's; the file comment, which has no line at all,
  -- is at home in either.
  local lines_true = loc.revision or loc.commit == nil
  local above = {}
  for _, c in ipairs(state.for_location(loc.from, loc.commit, loc.rel)) do
    local resolved = c.status == 'resolved'
    -- A resolved comment stays in the store and in the preview; hiding it here
    -- is only about the buffer, so a second read sees the lines it left alone.
    if (not resolved or state.show_resolved) and c.scope == 'file' then
      for _, line in ipairs(file_lines(c, resolved)) do table.insert(above, line) end
    elseif (not resolved or state.show_resolved) and lines_true then
      -- Left bar spanning every line of the commented range (priority above
      -- gitsigns so the range wins the sign cell on its own lines).
      local bar_hl = resolved and 'ReviewBarResolved' or 'ReviewBar'
      for l = c.lnum, math.min(c.end_line or c.lnum, total) do
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, l - 1, 0, {
          sign_text = '▌',
          sign_hl_group = bar_hl,
          priority = 100,
        })
      end
      -- Inline label at the head line.
      local first = c.text:match('[^\n]*') or c.text
      local label = first
      if c.text:find('\n') then label = first .. ' …' end
      local icon = resolved and '󰄬' or '󰆉'
      local hl = resolved and 'Comment' or 'DiagnosticVirtualTextInfo'
      pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, c.lnum - 1, 0, {
        virt_text = { { icon .. ' ' .. label, hl } },
        virt_text_pos = 'eol',
      })
    end
  end
  if #above > 0 then
    pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, 0, 0, {
      virt_lines = above,
      virt_lines_above = true,
    })
  end
end

-- Re-render every loaded buffer that has comments (and the current one).
function M.all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      M.buffer(bufnr)
    end
  end
  -- The commit comment lives in the changeset window's title, which is no
  -- buffer's extmark -- so it is redrawn from here with everything else.
  require('review.hunks').set_title()
  vim.cmd('redrawstatus!')
end

-- A commit comment has no line of its own: it is drawn in the changeset
-- window's title, which the reader may not even have open, and abbreviated to
-- one line there. So the comment walk arriving at one shows it whole, in a float
-- at the cursor, and leaves the cursor where it stood. It closes on the next
-- move, like any other thing shown in passing.
-- The float above, while it is up. A comment shown in passing has to come down
-- on the next arrival too, not only on the next cursor move: the walk's next
-- stop can be the line the cursor already stands on, which moves nothing.
local commit_float = nil

function M.hide_commit_comment()
  if commit_float and vim.api.nvim_win_is_valid(commit_float) then
    vim.api.nvim_win_close(commit_float, true)
  end
  commit_float = nil
end

-- What the float calls itself. A comment about one commit says only its scope --
-- the changeset around it names the commit already -- while one about a span
-- names the span, because the reader has to know how much of the stack it is
-- about.
local function float_title(c)
  local icon = (c.status == 'resolved') and '󰄬' or '󰆉'
  if c.scope == 'commit' and c.commit_from and c.commit_from ~= c.commit then
    local n = state.span_length(c.commit_from, c.commit)
    return (' %s %s..%s%s comment '):format(icon, c.commit_from, c.commit,
      n and (' · %d commits'):format(n) or '')
  end
  return (' %s %s comment '):format(icon, c.scope)
end

function M.show_commit_comment(c)
  M.hide_commit_comment()
  local lines = vim.split(c.text, '\n', { plain = true })
  local width = 20
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  -- Not focused: the cursor is the reader's position in the walk, and showing
  -- them something must not move it.
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = math.min(width, math.max(20, math.floor(vim.o.columns * 0.6))),
    height = math.min(#lines, 12),
    border = 'rounded',
    title = float_title(c),
    title_pos = 'center',
    style = 'minimal',
    focusable = false,
  })
  commit_float = win
  -- Scheduled so the autocmd is not fired by the keypress that opened the float.
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) then return end
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertEnter', 'BufLeave' }, {
      once = true,
      callback = function()
        if commit_float == win then M.hide_commit_comment() end
      end,
    })
  end)
  return win
end

function M.set_statusline()
  -- setglobal only: a bare `vim.o`/`:set` on this global-local option also resets the
  -- CURRENT window's local statusline, which would clobber the qf-local one we set.
  if state.active then
    vim.go.statusline =
      '%#ReviewStatus# 󰆉 %{v:lua.ReviewCommentCount()} REVIEW%{v:lua.ReviewStaleFlag()}%{v:lua.ReviewCommitFlag()}%{v:lua.ReviewHunkPosition()} %* %f %m%r%=%l:%c '
  else
    vim.go.statusline = default_statusline
  end
end

-- Global because the statusline string above reaches the count through `v:lua`
-- on every redraw.
function _G.ReviewCommentCount()
  return state.pending_count()
end

-- Where the reader is in the changeset's own walk order: ` 3/12`. This lives in
-- the statusline rather than the changeset window's title because the reader is
-- looking at a Revision Buffer, not the quickfix window, while they read; empty
-- outside a session and once the changeset list is empty.
function _G.ReviewHunkPosition()
  local qf = vim.fn.getqflist({ idx = 0, size = 0 })
  if not qf.size or qf.size == 0 then return '' end
  return (' %d/%d'):format(qf.idx or 0, qf.size)
end

-- What is being read: ` abc1234` for a single commit, ` abc1234..def5678` for a
-- wider span. How many commits that is stays out of it -- the badge is read
-- while walking hunks, where the useful counter is the hunk one next to it, and
-- the commit count is in the changeset window's title for when it is wanted.
-- Empty for a working-tree session, which has no range.
function _G.ReviewCommitFlag()
  local span = state.targeted()
  if #span == 0 then return '' end
  if #span > 1 then
    return (' %s..%s'):format(span[1].hash, state.current)
  end
  return (' %s'):format(state.current)
end

-- A rewritten stack is worth seeing at all times, not only in the warning that
-- announced it: the badge says so until the session is exported or discarded.
function _G.ReviewStaleFlag()
  return state.stale and ' STALE' or ''
end

return M
