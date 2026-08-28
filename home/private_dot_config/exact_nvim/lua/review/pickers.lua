-- The pickers that choose where a review goes. Two of them, listing different
-- things: the switcher offers the range of the session already running, and the
-- comment picker offers everything the reader has said so far. Nothing here
-- starts a session -- a review covers the whole branch, so there is nothing to
-- choose.
local M = {}

-- `spec.columns(item)` returns the cells of one row, each `{ text, hl }` or a
-- bare string; `spec.widths` sizes them. Telescope draws them in columns and the
-- vim.ui.select fallback joins them with two spaces. `spec.ordinal(item)` is what
-- the prompt filters on, and `spec.previewer(previewers)` builds the preview --
-- both defaulted to what a list of commits wants, which is what two of the three
-- callers list. `spec.actions` are the extra keys of one list -- `{ key, fn }`,
-- where `fn(value, ctx)` gets the row under the cursor and the three things a
-- key can do to the list it was pressed in: `ctx.refresh(step)` draws the rows
-- again and moves the cursor on `step` entries, `ctx.close()` dismisses it. An
-- action's `desc`, and `spec.select_desc` for `<CR>`, are what the `<C-h>` help
-- overlay says about it. `spec.default_index` -- a number, or a function
-- returning one -- is the row the list opens on. `spec.on_dismiss` runs when the
-- list closed without a row being chosen, which is how a list opened from
-- another one hands the reader back.
-- A picker's own keys, made to answer on the first press. Telescope binds its
-- defaults after `attach_mappings` has run, and some of them are longer keys
-- that begin with one of ours -- `<C-r><C-w>` and friends against our `<C-r>`.
-- With both bound, the short key is ambiguous: nvim holds it for `timeoutlen`
-- waiting for a second press that is never coming, and the key reads as dead.
-- The longer ones lose: pasting a register into the prompt is worth less than
-- the picker's own key working.
local function drop_ambiguous_maps(bufnr, actions)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  local prefixes = {}
  for _, action in ipairs(actions or {}) do
    table.insert(prefixes, vim.api.nvim_replace_termcodes(action.key, true, true, true))
  end
  if #prefixes == 0 then return end
  for _, mode in ipairs({ 'i', 'n' }) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
      local lhs = vim.api.nvim_replace_termcodes(map.lhs, true, true, true)
      for _, prefix in ipairs(prefixes) do
        if #lhs > #prefix and lhs:sub(1, #prefix) == prefix then
          pcall(vim.api.nvim_buf_del_keymap, bufnr, mode, map.lhs)
        end
      end
    end
  end
end

-- A list's title, which an action may have just made out of date: `spec.title`
-- is either the text or a function returning it, and the ones a key can change
-- pass the function.
local function title_of(spec)
  return (type(spec.title) == 'function') and spec.title() or spec.title
end

-- The keys of a list, said out loud. A prompt title has room for what the list
-- is, not for what its keys do -- a long title is cut off, and the cut takes the
-- keys first. So the keys live behind `<C-h>` instead, in an overlay built from
-- the very table that is mapped, which is what keeps the help from naming a key
-- the picker does not answer to.
local help = { win = nil, buf = nil }

local function close_help()
  if help.win and vim.api.nvim_win_is_valid(help.win) then
    pcall(vim.api.nvim_win_close, help.win, true)
  end
  if help.buf and vim.api.nvim_buf_is_valid(help.buf) then
    pcall(vim.api.nvim_buf_delete, help.buf, { force = true })
  end
  help.win, help.buf = nil, nil
end

-- One line per key, `<CR>` first because choosing a row is what the list is for.
-- `spec.select_desc` says what choosing does; an action without a `desc` is one
-- the reader is not being told about.
local function help_lines(spec, keys)
  local rows = { { '<CR>', spec.select_desc or 'choose this row' } }
  for _, action in ipairs(keys) do
    if action.desc then table.insert(rows, { action.key, action.desc }) end
  end
  local key_width = 0
  for _, row in ipairs(rows) do key_width = math.max(key_width, #row[1]) end
  local lines = {}
  for _, row in ipairs(rows) do
    table.insert(lines, (' %s  %s '):format(row[1] .. (' '):rep(key_width - #row[1]), row[2]))
  end
  return lines
end

-- Shown over the picker rather than beside it: telescope owns the whole layout,
-- so there is no room to take. `focusable = false` leaves the prompt with the
-- cursor -- the overlay is read, never entered -- and the `zindex` puts it above
-- telescope's own floats, which sit at 50.
local function toggle_help(lines)
  if help.win and vim.api.nvim_win_is_valid(help.win) then
    close_help()
    return
  end
  local width = 0
  for _, line in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(line)) end
  help.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(help.buf, 0, -1, false, lines)
  vim.bo[help.buf].modifiable = false
  help.win = vim.api.nvim_open_win(help.buf, false, {
    relative = 'editor',
    width = width,
    height = #lines,
    row = math.max(0, vim.o.lines - #lines - 4),
    col = math.max(0, vim.o.columns - width - 3),
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    zindex = 250,
    noautocmd = true,
  })
  vim.wo[help.win].winhighlight = 'NormalFloat:TelescopeNormal,FloatBorder:TelescopeBorder'
end

-- The keys a list is mapped with: its own, plus the one that lists them. Added
-- here and not to each spec so no picker can carry keys with no way to see them.
-- The lines are built on the press, so `<C-h>` describes itself.
local function keys_of(spec)
  local keys = vim.list_extend({}, spec.actions or {})
  if #keys == 0 then return keys end
  table.insert(keys, {
    key = '<C-h>',
    desc = 'hide this help',
    fn = function() toggle_help(help_lines(spec, keys)) end,
  })
  return keys
end

local function pick_with_telescope(items, spec, on_choose)
  local ok, pickers = pcall(require, 'telescope.pickers')
  if not ok then return false end
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entry_display = require('telescope.pickers.entry_display')
  local previewers = require('telescope.previewers')

  local displayer = entry_display.create({ separator = '  ', items = spec.widths })
  local keys = keys_of(spec)

  local ordinal = spec.ordinal or function(c)
    return table.concat({ c.hash, c.date, c.subject }, ' ')
  end
  -- Plain `git show`, not telescope's own git_commits previewer/actions: those
  -- check the commit out, which is the last thing a review wants.
  local previewer = spec.previewer and spec.previewer(previewers)
    or previewers.new_termopen_previewer({
      get_command = function(entry)
        local hash = entry.value.hash
        -- The Uncommitted Tip is no object git can be asked to show, so it is
        -- previewed as what it is: the working tree against HEAD.
        if require('review.state').is_uncommitted(hash) then
          return { 'git', '--no-pager', 'diff', '--stat', '-p', 'HEAD' }
        end
        return { 'git', '--no-pager', 'show', '--stat', '-p', hash }
      end,
    })

  -- Rebuilt rather than reused: a row's cells are drawn from state an action may
  -- have just changed, and re-running the finder is what asks for them again.
  local function make_finder()
    return finders.new_table({
      results = items,
      entry_maker = function(c)
        return {
          value = c,
          ordinal = ordinal(c),
          display = function(entry)
            return displayer(spec.columns(entry.value))
          end,
        }
      end,
    })
  end

  -- Where the list opens. A review's lists are opened to ask "where am I", so
  -- they open on the row the reader is already on rather than on whichever row
  -- sorts first. `closest` is what keeps that to the opening: telescope honours
  -- the index while the prompt is empty and goes back to the best match once
  -- the reader types.
  local default_index = spec.default_index
  if type(default_index) == 'function' then default_index = default_index() end

  pickers.new({
    initial_mode = spec.initial_mode,
    default_selection_index = default_index,
    selection_strategy = default_index and 'closest' or nil,
  }, {
    prompt_title = title_of(spec),
    finder = make_finder(),
    sorter = conf.generic_sorter({}),
    previewer = previewer,
    attach_mappings = function(prompt_bufnr, map)
      -- Whether this list ended in a choice, which is what tells a caller that
      -- put the reader here that they are going somewhere else instead of coming
      -- back: `spec.on_dismiss` runs on every other way out.
      local chose = false
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        chose = entry ~= nil
        actions.close(prompt_bufnr)
        if entry then on_choose(entry.value) end
      end)
      for _, action in ipairs(keys) do
        map({ 'i', 'n' }, action.key, function()
          local entry = action_state.get_selected_entry()
          action.fn(entry and entry.value, {
            refresh = function(step)
              local picker = action_state.get_current_picker(prompt_bufnr)
              if not picker then return end
              local row = picker:get_selection_row()
              picker:refresh(make_finder(), { reset_prompt = false })
              -- A count in the title is part of what the rows say, so it is
              -- redrawn with them. Telescope has no public setter for it, hence
              -- the guarded reach at the border itself.
              if type(spec.title) == 'function' then
                local title = title_of(spec)
                picker.prompt_title = title
                pcall(function() picker.layout.prompt.border:change_title(title) end)
              end
              -- The refresh runs the finder again on the loop, so the cursor can
              -- only be put back once the rows it is counting are there. The
              -- step is telescope's own move, so it goes where `<C-n>` goes
              -- whichever way the list is sorted.
              vim.schedule(function()
                picker:set_selection(row)
                if step and step ~= 0 then picker:move_selection(step) end
              end)
            end,
            close = function() actions.close(prompt_bufnr) end,
          })
        end)
      end
      -- Scheduled because telescope's defaults are not down yet: they are bound
      -- after this function returns, and it is those that would shadow ours.
      vim.schedule(function() drop_ambiguous_maps(prompt_bufnr, keys) end)
      -- The overlay outlives nothing: the list it describes is gone the moment
      -- its prompt buffer is, so the float goes with it however the list closed.
      vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufDelete' }, {
        buffer = prompt_bufnr,
        once = true,
        callback = function()
          close_help()
          -- Scheduled: telescope is still taking its own windows down, and what
          -- a dismissal opens is usually another list.
          if not chose and spec.on_dismiss then vim.schedule(spec.on_dismiss) end
        end,
      })
      return true
    end,
  }):find()
  return true
end

-- The fallback when telescope is not there. `vim.ui.select` asks one question
-- and takes one answer, so `spec.actions` cannot exist here: a list picked this
-- way is choose-one-row only, and the switcher's marking keys are simply absent.
local function pick_with_ui_select(items, spec, on_choose)
  vim.ui.select(items, {
    prompt = title_of(spec),
    format_item = function(c)
      local cells = {}
      for _, cell in ipairs(spec.columns(c)) do
        table.insert(cells, type(cell) == 'table' and cell[1] or cell)
      end
      return table.concat(cells, '  ')
    end,
  }, function(choice)
    if choice then
      on_choose(choice)
    elseif spec.on_dismiss then
      spec.on_dismiss()
    end
  end)
end

local function pick(items, spec, on_choose)
  if not pick_with_telescope(items, spec, on_choose) then
    pick_with_ui_select(items, spec, on_choose)
  end
end

-- What a commit's row says about the comments on it: pending first because that
-- is what is left to send, resolved only when there are any.
local function comment_cell(hash)
  local pending, resolved = require('review.state').counts_for_commit(hash)
  if pending == 0 and resolved == 0 then return '' end
  local cell = ('󰆉 %d'):format(pending)
  if resolved > 0 then cell = cell .. ('  󰄬 %d'):format(resolved) end
  return cell
end

-- What a comment's own row says about its status, in the glyphs the buffers and
-- the switcher already use.
local function status_cell(c)
  return (c.status == 'resolved') and '󰄬' or '󰆉'
end

-- Whether a rewrite carried this comment onto HEAD, in a cell of its own rather
-- than folded into the status one: resolved and rebound are orthogonal, so a
-- comment that is both has to say both.
local function rebound_cell(c)
  return c.rebound and require('review.render').rebound_mark or ' '
end

-- The marks a reader lays down in the switcher to say which run of commits to
-- read next. One mark is a span of one; a second mark closes the span, and every
-- row between the two belongs to it. Marks are made per list, so they live
-- exactly as long as the switcher they were made in.
function M.new_marks()
  local hashes = {}
  local marks = {}

  function marks.has(hash)
    return vim.tbl_contains(hashes, hash)
  end

  -- Mark `hash`, or drop the mark if it is already there. True when this mark
  -- closed a span -- the reader has now named both of its ends.
  function marks.toggle(hash)
    for i, h in ipairs(hashes) do
      if h == hash then
        table.remove(hashes, i)
        return false
      end
    end
    table.insert(hashes, hash)
    return #hashes >= 2
  end

  function marks.clear()
    hashes = {}
  end

  -- The ends of the marked span, oldest first, whichever order they were marked
  -- in: a span is a run of the range, not a pair of clicks. Nil when nothing is
  -- marked.
  function marks.ends()
    local state = require('review.state')
    local positions = {}
    for _, h in ipairs(hashes) do
      local i = state.index_of(h)
      if i then table.insert(positions, i) end
    end
    if #positions == 0 then return nil end
    table.sort(positions)
    return state.range[positions[1]].hash, state.range[positions[#positions]].hash
  end

  -- Whether a row belongs to the span the marks imply, which is what lets the
  -- run light up in the list instead of just its two ends.
  function marks.covers(hash)
    local oldest, newest = marks.ends()
    if not oldest then return false end
    local state = require('review.state')
    local i, from, to = state.index_of(hash), state.index_of(oldest), state.index_of(newest)
    return i ~= nil and from ~= nil and to ~= nil and i >= from and i <= to
  end

  return marks
end

-- What pressing the toggle key on a row does, as a value rather than as an
-- effect, so the move can be read and asserted without a list on screen:
-- 'advance' means the mark opened a span and the reader steps down a row to
-- find its other end, 'span' means the mark closed one and comes with its ends.
function M.toggle_row(marks, hash)
  if marks.toggle(hash) then
    local oldest, newest = marks.ends()
    return 'span', oldest, newest
  end
  return 'advance'
end

-- Whether the span being read is the whole range, which is a review's resting
-- state rather than a choice made in this list -- so it is drawn as nothing at
-- all, and a reset leaves a clean list. A span whose ends have left the range
-- counts as the whole of it too: there is no sub-span to point at.
local function whole_range_targeted(state)
  local span = state.targeted()
  if #span == 0 or #state.range == 0 then return true end
  -- The whole range ends at its newest commit, not at the Uncommitted Tip: the
  -- tip is a row the reader targets on purpose, so a review sitting at rest with
  -- a dirty tree still draws a clean list, and targeting the tip shows.
  local session = require('review.session')
  local newest = session.newest_commit() or state.range[#state.range]
  return span[1].hash == state.range[1].hash and span[#span].hash == newest.hash
end

-- What the second column says: the span the review is reading now, drawn on
-- every row of it -- heavy bar down the run, triangle on the commit whose
-- content is on screen -- so the target reads as the run it is and not as one
-- commit. Blank on every row when the whole range is the target.
local function targeted_marker(state, hash)
  if whole_range_targeted(state) then return ' ' end
  if hash == state.current then return '▶' end
  for _, c in ipairs(state.targeted()) do
    if c.hash == hash then return '┃' end
  end
  return ' '
end

-- What the leading columns say about a row: first the marks the reader has laid
-- down in this list, then the span the review is targeting. Two columns and two
-- sets of glyphs, because they answer different questions -- what I am about to
-- choose, and what I am reading now.
local function row_marker(marks, hash)
  local state = require('review.state')
  local mark = marks.has(hash) and '◆' or (marks.covers(hash) and '│' or ' ')
  return mark .. targeted_marker(state, hash)
end

-- Whether a comment group covers one member of the range: its own span of one,
-- or a wider span the member sits inside -- so a comment filed under `abc..def`
-- is reachable from either end's row and from every row between them.
local function group_holds(g, hash)
  if g.from == hash or g.hash == hash then return true end
  local state = require('review.state')
  local i, from, to = state.index_of(hash), state.index_of(g.from), state.index_of(g.hash)
  return i ~= nil and from ~= nil and to ~= nil and i >= from and i <= to
end

-- Everything said about one member of the range, in the rows the comment picker
-- draws. `session` comments are about the review rather than about any part of
-- it, so a narrowed list never holds them -- the full picker stays the one list
-- that reaches every comment.
local function member_comment_rows(hash)
  local state = require('review.state')
  local rows = {}
  for _, g in ipairs(state.comment_groups()) do
    if group_holds(g, hash) then
      for _, c in ipairs(state.for_span(g.from, g.hash)) do
        table.insert(rows, { comment = c, group = g })
      end
    end
  end
  return rows
end

-- The switcher's own keys, built against one list's marks. A table rather than
-- mappings so the moves can be driven -- and asserted -- without a list on
-- screen.
function M.switch_actions(marks, handlers)
  return {
    {
      key = '<Tab>',
      desc = 'mark an end of a span',
      fn = function(commit, ctx)
        if not commit then return end
        local outcome, oldest, newest = M.toggle_row(marks, commit.hash)
        if outcome == 'span' then
          -- Drawn once with the whole run lit before the list goes away, so what
          -- was targeted is the last thing the reader saw.
          ctx.refresh(0)
          vim.schedule(function()
            ctx.close()
            handlers.span(oldest, newest)
          end)
        else
          -- A mark with no partner yet: step down a row, which is where its
          -- partner is looked for.
          ctx.refresh(1)
        end
      end,
    },
    {
      key = '<C-l>',
      desc = 'the comments on this row',
      fn = function(commit, ctx)
        if not commit then return end
        -- Asked before the switcher goes away: a list that does not hold what
        -- was asked for is worse than no list, so a member with nothing said
        -- about it leaves the reader here, on the row they pressed on.
        if #member_comment_rows(commit.hash) == 0 then
          vim.notify(('Review: nothing said about %s'):format(commit.hash), vim.log.levels.INFO)
          return
        end
        ctx.close()
        -- The switcher draws the target, and choosing a comment moves it -- so
        -- the switcher goes first and only comes back, rebuilt from what state
        -- says then, if the reader chose nothing.
        vim.schedule(function()
          require('review.comments').pick({
            member = commit.hash,
            on_dismiss = function() M.switch_commit(handlers, commit.hash) end,
          })
        end)
      end,
    },
    {
      key = '<C-r>',
      desc = 'read the whole range again',
      fn = function(_, ctx)
        marks.clear()
        ctx.close()
        handlers.reset()
      end,
    },
  }
end

-- Choose what to read next from the running session's range -- its commits, and
-- the working tree while there is anything uncommitted. Only the range, and only
-- with a session: switching is a move within a review, never a start.
--
-- The range is listed oldest first, so a row's position down the list is the
-- position the title counts -- read the other way round they disagree, and the
-- reader is told they are at 3/7 while sitting on the fifth row. Telescope draws
-- the first entry against the prompt and counts upwards from there, so oldest
-- first puts the oldest member on the bottom row and the newest at the top:
-- the stack stands the way `git log` prints it, and its foot is where the
-- cursor can reach without moving.
--
-- `handlers.choose(commit)` is one commit on its own, `handlers.span(oldest,
-- newest)` a marked run of them, `handlers.reset()` the whole range back.
--
-- It opens in normal mode. The range of a branch is short enough to reach by
-- moving, and moving is what the reader came to do -- marking a span is two
-- rows to land on, not a name to type. `i` still gets the prompt for a range
-- long enough to want filtering.
function M.switch_commit(handlers, opening_hash)
  local state = require('review.state')
  if not state.active then
    vim.notify('Review: no session — start one first', vim.log.levels.WARN)
    return false
  end
  if #state.range == 0 then
    vim.notify('Review: this session has nothing left to switch between', vim.log.levels.WARN)
    return false
  end
  local total = state.pending_count()
  local marks = M.new_marks()
  -- Where the cursor opens. A review at rest is reading the whole range, which
  -- is no one member, so there is no "where am I" to answer -- the cursor goes
  -- to the oldest member instead, the bottom row, which is the end of the stack
  -- a reader starts from. Once a narrower span is being read the list goes back
  -- to answering where that span is.
  -- `opening_hash` is a list coming back rather than being opened: the row the
  -- reader left from is where they are put back, however the rows were rebuilt.
  local opening_row = opening_hash and state.index_of(opening_hash)
    or (whole_range_targeted(state) and 1 or state.current_index())
  pick(state.range, {
    initial_mode = 'normal',
    default_index = opening_row,
    title = ('Switch commit (%d/%d, 󰆉 %d in session)'):format(
      state.current_index() or 0, #state.range, total),
    select_desc = 'read this commit on its own',
    widths = { { width = 14 }, { width = 12 }, { width = 10 }, { remaining = true } },
    columns = function(c)
      return {
        { row_marker(marks, c.hash) .. ' ' .. c.hash, 'TelescopeResultsIdentifier' },
        { comment_cell(c.hash), 'TelescopeResultsNumber' },
        { c.date, 'TelescopeResultsComment' },
        c.subject,
      }
    end,
    actions = M.switch_actions(marks, handlers),
  }, handlers.choose)
  return true
end

-- Everything said in the review, in one list. The comment walk stays inside one
-- commit and the export preview is a document to read, so neither answers "where
-- was that thing I said" -- this does, and it is the only place the `commit` and
-- `session` comments, which no buffer of the review shows in its lines, can be
-- chosen from.

-- One row per comment, each carrying the group it is filed under so the row can
-- say so and the jump knows what to target first. The groups are the session's
-- own -- `state.comment_groups()`, the same shape the export heads its sections
-- with -- so every comment of every span is here, including the spans that are
-- not the one being read. A `session` comment belongs to no span, so it is added
-- once, after every group, which is also the only time it appears.
local function comment_rows()
  local state = require('review.state')
  local rows = {}
  for _, g in ipairs(state.comment_groups()) do
    for _, c in ipairs(state.for_span(g.from, g.hash)) do
      table.insert(rows, { comment = c, group = g })
    end
  end
  for _, c in ipairs(state.for_session()) do
    table.insert(rows, { comment = c, group = { subject = 'whole review' } })
  end
  return rows
end

-- The first line of a comment, which is what a row has room for. The rest is the
-- previewer's job.
local function first_line(text)
  local line = vim.split(text, '\n', { plain = true })[1] or ''
  return vim.trim(line)
end

-- What the commit column says: the span the comment was written against, which
-- for the usual span of one is just the commit -- or `uncommitted`, for one
-- written against the working tree. A `session` comment is about the review
-- rather than any part of it.
local function commit_cell(row)
  if row.comment.scope == 'session' then return 'session' end
  local g = row.group
  if not g.hash then return 'worktree' end
  if g.from == g.hash then return g.hash end
  return ('%s..%s'):format(g.from, g.hash)
end

-- What the row says about the group beyond its hashes: a commit has a subject,
-- a span has a count of commits instead.
local function group_subject(row)
  local g = row.group
  if g.subject then return g.subject end
  return g.commits and ('%d commits read as one diff'):format(g.commits) or nil
end

-- The first row of the span being read, which is where the list opens: the
-- comments of the rest of the review are there to be scrolled to, not to be
-- landed in. Nil when nothing was said against the span, and the list opens at
-- the top.
local function first_row_of_targeted(rows)
  local state = require('review.state')
  for i, row in ipairs(rows) do
    if row.group.from == state.targeted_from and row.group.hash == state.current then
      return i
    end
  end
  return nil
end

-- Choose any comment of the session and go to it. `on_choose` gets the comment
-- itself; moving the review to its commit first is the caller's business.
function M.comment(on_choose, opts)
  local state = require('review.state')
  opts = opts or {}
  -- `opts.member` narrows the list to one member of the range, which is what the
  -- switcher opens it as: the same list, the same keys, fewer rows.
  local rebuild = opts.member
    and function() return member_comment_rows(opts.member) end
    or comment_rows
  local rows = rebuild()
  if #rows == 0 then
    vim.notify(opts.member and ('Review: nothing said about %s'):format(opts.member)
      or 'Review: no comments yet', vim.log.levels.WARN)
    return false
  end
  pick(rows, {
    default_index = first_row_of_targeted(rows),
    title = function()
      if opts.member then
        local pending = state.counts_for_commit(opts.member)
        return ('Comments on %s (%d, 󰆉 %d pending)'):format(opts.member, #rows, pending)
      end
      return ('Review comments (%d, 󰆉 %d pending)'):format(#rows, state.pending_count())
    end,
    on_dismiss = opts.on_dismiss,
    select_desc = 'go to this comment',
    -- Deleting from the list: the one place every comment of the review can be
    -- reached is also the one place a `commit` or `session` comment -- which
    -- sits on no line, so no buffer's delete key can find it -- can be taken
    -- back. The list closes when the last comment goes: an empty picker says
    -- nothing.
    actions = {
      {
        key = '<C-x>',
        desc = 'delete this comment',
        fn = function(row, ctx)
          if not row then return end
          state.remove(row.comment)
          state.save()
          require('review.render').all()
          -- Refilled rather than replaced: the finder reads this very table, and
          -- a new one would leave the picker drawing the rows it was built with.
          local fresh = rebuild()
          for i = #rows, 1, -1 do rows[i] = nil end
          vim.list_extend(rows, fresh)
          if #rows == 0 then
            ctx.close()
            vim.notify('Review: that was the last comment', vim.log.levels.INFO)
            return
          end
          ctx.refresh(0)
        end,
      },
      -- Resolving from the list: the export preview is a document to read, and
      -- working through a run of comments belongs on the surface that reaches
      -- every one of them. The cursor stays on the row it was pressed on, so a
      -- reader can go down the list one comment at a time.
      {
        key = '<C-t>',
        desc = 'toggle resolved',
        fn = function(row, ctx)
          if not row then return end
          local c = row.comment
          c.status = (c.status == 'resolved') and 'unresolved' or 'resolved'
          state.save() -- the reader's progress; it survives a quit too
          require('review.render').all()
          ctx.refresh(0)
        end,
      },
    },
    -- Wide enough for `abc1234..def5678`: a span is what the column now says.
    widths = { { width = 1 }, { width = 1 }, { width = 18 }, { width = 8 }, { width = 40 }, { remaining = true } },
    ordinal = function(row)
      local c = row.comment
      return table.concat(
        { commit_cell(row), group_subject(row) or '', c.scope, state.label(c),
          c.rebound and 'rebound' or '', c.text }, ' ')
    end,
    columns = function(row)
      local c = row.comment
      return {
        -- The same two glyphs the buffers and the switcher use, so a press of
        -- `<C-t>` says so on the surface it was made on.
        { status_cell(c), 'TelescopeResultsComment' },
        { rebound_cell(c), 'ReviewRebound' },
        { commit_cell(row), 'TelescopeResultsIdentifier' },
        { c.scope, 'TelescopeResultsNumber' },
        { state.label(c), 'TelescopeResultsComment' },
        first_line(c.text),
      }
    end,
    -- The comment's own text, not `git show`: the question the list answers is
    -- "which of the things I said is this", and the text is the answer.
    previewer = function(previewers)
      return previewers.new_buffer_previewer({
        title = 'Comment',
        define_preview = function(self, entry)
          local c = entry.value.comment
          local lines = { ('**%s** · `%s`'):format(c.scope, state.label(c)) }
          local subject = group_subject(entry.value)
          if subject then
            table.insert(lines, ('_%s %s_'):format(commit_cell(entry.value), subject))
          end
          if c.status == 'resolved' then table.insert(lines, '_resolved_') end
          -- Said in words here, because the row has room for a glyph only: the
          -- line numbers above were written against a commit a rewrite removed.
          if c.rebound then
            table.insert(lines, '_rebound onto HEAD by a rewrite - its lines are the old ones_')
          end
          table.insert(lines, '')
          vim.list_extend(lines, vim.split(c.text, '\n', { plain = true }))
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.bo[self.state.bufnr].filetype = 'markdown'
        end,
      })
    end,
  }, function(row) on_choose(row.comment) end)
  return true
end


return M
