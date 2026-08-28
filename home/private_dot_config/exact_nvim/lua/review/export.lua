-- Turning the comment store into the Markdown block an agent reads: build it,
-- copy it, show it for triage, or type it straight into an agent pane.
--
-- The shape is for a machine reader first. It groups by the span a comment was
-- written against, so a comment is read against the change it is about, and
-- every member of the range gets a heading whether or not it collected comments
-- — an agent has to be able to tell "reviewed and fine" from "not reviewed".
--
-- Most reviews are of one commit at a time, and those read exactly as they
-- always have: one heading per commit, hash and subject. Only feedback that
-- genuinely spans several commits is headed by a span, because only then does
-- the agent need to be told.
local agent_pane = require('agent_pane')
local buffers = require('review.buffers')
local landing = require('review.landing')
local render = require('review.render')
local state = require('review.state')

local M = {}

-- What the review covers, as the summary line says it. A range holding nothing
-- but the Uncommitted Tip is named by what it is rather than by the base it was
-- resolved against, which for that session is only "HEAD as it stood".
local function range_label()
  local spec = state.spec
  if not spec then return 'the working tree' end
  if #state.range == 1 and state.is_uncommitted(state.range[1].hash) then
    return 'the working tree'
  end
  local head = (spec.head and spec.head ~= '') and spec.head or 'HEAD'
  return ('%s..%s'):format(spec.base, head)
end

-- How many commits the range holds. The Uncommitted Tip is a member of it but
-- not a commit, so the summary counts around it.
local function commit_count()
  return #state.range - (state.index_of(state.UNCOMMITTED) and 1 or 0)
end

-- What one group of `state.comment_groups()` is headed by. A span of one is the
-- commit heading this export has always had; a wider one names both ends and
-- how many commits lie between them, which is the whole of what the reader of
-- the export needs in order to know what the feedback under it is about.
-- Comments made against the Uncommitted Tip say so, and go on saying so once
-- the work is committed: they were written about lines that were not yet in any
-- commit, and the lines that were committed may differ from them.
local function heading(g)
  if not g.hash then return 'Working tree' end
  if state.is_uncommitted(g.hash) and g.from == g.hash then
    return 'uncommitted — work not committed at the time of review'
  end
  if g.from == g.hash then return ('%s — %s'):format(g.hash, g.subject or '') end
  if not g.commits then return ('%s..%s'):format(g.from, g.hash) end
  return ('%s..%s — %d read as one diff'):format(g.from, g.hash, g.commits)
end

-- The review as Markdown. Numbering runs continuously from the first line to
-- the last, across commits and scopes, so any comment can be pointed at by
-- number alone. `opts.resolved` keeps resolved comments in and marks each with
-- a checkbox — that is the preview; the export leaves them out entirely.
-- `opts.rebound` marks the comments a rewrite carried onto HEAD, and is the
-- preview's alone for the same reason: it says a line number is not to be
-- trusted, which is nothing the agent reading the export can act on.
--
-- Returns the lines, the number of comments in them, and a line → comment map
-- for the preview to jump and toggle from.
local function sections(opts)
  opts = opts or {}
  local body, n, map = {}, 0, {}

  local function push(line, c)
    table.insert(body, line)
    if c then map[#body] = c end
  end

  local function emit(c)
    if not opts.resolved and c.status == 'resolved' then return end
    n = n + 1
    local mark = opts.resolved and ((c.status == 'resolved' and '[x] ') or '[ ] ') or ''
    local label = state.label(c)
    -- The mark rides beside the label rather than inside its backticks: it is
    -- about that pointer, not part of it.
    local flag = (opts.rebound and c.rebound)
      and (' ' .. require('review.render').rebound_mark) or ''
    if c.text:find('\n') then
      push(('%d. %s`%s`%s:'):format(n, mark, label, flag), c)
      for _, l in ipairs(vim.split(c.text, '\n', { plain = true })) do
        push('   ' .. l, c)
      end
    else
      push(('%d. %s`%s`%s - %s'):format(n, mark, label, flag, c.text), c)
    end
  end

  local function section(heading, comments, always)
    local before = n
    local at = #body
    if #body > 0 then push('') end
    push('## ' .. heading)
    push('')
    for _, c in ipairs(comments) do emit(c) end
    if n == before then
      if always then
        push('_No comments._')
      else
        -- An empty section nobody asked for: unwind the heading again.
        for i = #body, at + 1, -1 do table.remove(body, i) end
      end
    end
  end

  section('Session', state.for_session(), false)
  for _, g in ipairs(state.comment_groups()) do
    -- A member of the range says "no comments" out loud, because the silence is
    -- the finding. A span exists only because something was said about it, so
    -- it is dropped again when the export has nothing to put under it.
    section(heading(g), state.for_span(g.from, g.hash), g.from == g.hash)
  end

  local summary = ('# Review of %s — %d commit(s), %d comment(s)'):format(
    range_label(), commit_count(), n)
  local lines = { summary, '' }
  local offset = #lines
  for _, line in ipairs(body) do table.insert(lines, line) end
  -- The map was built against the body, so shift it past the summary line.
  local shifted = {}
  for i, c in pairs(map) do shifted[i + offset] = c end
  return lines, n, shifted
end

-- Build the Markdown review body and a count of comments (resolved are skipped).
function M.build()
  local lines, n = sections()
  return lines, n
end

function M.export()
  local out, n = M.build()
  if n == 0 then
    vim.notify('No review comments to export', vim.log.levels.WARN)
    return false
  end
  vim.fn.setreg('+', table.concat(out, '\n'))
  vim.notify(('Exported %d review comment(s) to clipboard'):format(n), vim.log.levels.INFO)
  return true
end

-- Preview the assembled review in a floating scratch buffer (no clipboard
-- write). Same grouping as the export, but resolved comments stay in and every
-- comment carries a [ ]/[x] checkbox: `t` toggles the one under the cursor,
-- `<CR>` jumps to it. Only unresolved comments are exported.
function M.preview()
  if #state.comments == 0 then
    vim.notify('No review comments to preview', vim.log.levels.WARN)
    return
  end
  -- Window <CR> jumps into: the one we came from, unless that's the quickfix
  -- list (an :edit there would replace the changeset window), in which case the
  -- first ordinary window wins.
  local origin_win = vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(origin_win)].buftype ~= '' then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].buftype == '' then
        origin_win = w
        break
      end
    end
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'

  -- line → comment; every line of a multi-line comment maps back to the same one.
  local map = {}
  local function render_preview()
    local lines, _, m = sections({ resolved = true, rebound = true })
    map = m
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
  end
  render_preview()

  local nlines = vim.api.nvim_buf_line_count(buf)
  local width = math.min(140, math.floor(vim.o.columns * 0.9))
  local max_height = math.floor(vim.o.lines * 0.9)
  local height = math.max(math.min(nlines + 1, max_height), math.min(20, max_height))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = 'rounded',
    title = ' Review preview  (<CR> jump · t toggle resolved · <Esc> close) ',
    title_pos = 'center',
    style = 'minimal',
  })
  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.keymap.set('n', 't', function()
    local c = map[vim.fn.line('.')]
    if not c then return end
    c.status = (c.status == 'resolved') and 'unresolved' or 'resolved'
    state.save() -- resolved state is the reader's progress; it survives a quit too
    local pos = vim.api.nvim_win_get_cursor(win)
    render_preview()
    pcall(vim.api.nvim_win_set_cursor, win, pos)
    render.all() -- reflect status in inline virt_text on source buffers
  end, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<CR>', function()
    local c = map[vim.fn.line('.')]
    if not c then return end
    -- Only the narrower scopes have somewhere to land; a commit or session
    -- comment is about no file in particular.
    if not c.path then
      vim.notify(('A %s comment has no location'):format(c.scope), vim.log.levels.INFO)
      return
    end
    local rel, lnum = c.path, c.lnum or 1
    close()
    if vim.api.nvim_win_is_valid(origin_win) then
      vim.api.nvim_set_current_win(origin_win)
    end
    -- A comment names a span of commits and a path, not a buffer: one made
    -- against a span puts the review back on that span and opens its content
    -- again, and one made against the working tree opens the file on disk.
    if c.commit and state.active and not state.targets(c) then
      require('review.session').target(c.commit_from, c.commit)
    end
    local root = state.repo_root()
    -- A comment against the tip is about the file on disk -- there is no
    -- revision buffer that could hold what was never committed.
    if c.commit and not state.is_uncommitted(c.commit)
      and buffers.name(c.commit, rel, root) then
      buffers.open(c.commit, rel, root)
    else
      vim.cmd('edit ' .. vim.fn.fnameescape(root and (root .. '/' .. rel) or rel))
    end
    pcall(vim.api.nvim_win_set_cursor, 0, { math.min(lnum, vim.api.nvim_buf_line_count(0)), 0 })
    landing.land()
  end, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true })
end

-- The export, in an editable float that types itself into a Pop agent pane.
function M.send_preview()
  local out, n = M.build()
  if n == 0 then
    vim.notify('No review comments to send', vim.log.levels.WARN)
    return
  end

  local lines = vim.split(table.concat(out, '\n'), '\n', { plain = true })
  local nlines = #lines
  local width = math.min(140, math.floor(vim.o.columns * 0.9))
  local max_height = math.floor(vim.o.lines * 0.9)
  local height = math.max(math.min(nlines + 1, max_height), math.min(20, max_height))
  local buf, _, close = agent_pane.text_float(' Review send  (Enter type · Shift+Enter send · q close) ', width, height)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  agent_pane.map_text_send(buf, close, 'No review text to send', 'Sent review to %s')
end

return M
