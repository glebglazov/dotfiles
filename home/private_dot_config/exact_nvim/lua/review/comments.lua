-- The walk through everything the reader has said. A second stride over the same
-- review: the hunk walk moves through what the targeted range changed, this one
-- through what has been said about the whole of it. It is not confined to the
-- span on screen -- stepping onto a comment of another span targets that span
-- first, the way the comment picker's jump does -- so the walk is the whole
-- review in one order and nothing said in it can be walked past. It wraps at
-- both ends, the way the hunk walk does.
local buffers = require('review.buffers')
local landing = require('review.landing')
local hunks = require('review.hunks')
local state = require('review.state')

local M = {}

-- Within one file, what is about the file comes before what is about its lines.
local KIND = { file = 0, range = 1 }

-- The reading order, as a comparable key. The commit comment sorts before every
-- file because it is about everything that follows; a file's rank is its place
-- in the changeset, so the walk reads the files in the order the reader meets
-- them rather than the order their paths sort in.
local function key(rank, kind, lnum)
  return { rank, kind, lnum }
end

local function lt(a, b)
  for i = 1, 3 do
    if a[i] ~= b[i] then return a[i] < b[i] end
  end
  return false
end

-- Where each changed file sits in the changeset, by repository-relative path.
-- The changeset is one entry per hunk, so a file's rank is where its first hunk
-- is -- exactly the position the file stride lands on.
local function file_ranks()
  local ranks, n = {}, 0
  for _, item in ipairs(vim.fn.getqflist({ items = 0 }).items or {}) do
    local file = hunks.entry_file(item)
    if file ~= '' and ranks[file] == nil then
      n = n + 1
      ranks[file] = n
    end
  end
  return ranks, n
end

-- A resolved comment the reader has hidden is not on screen, so walking onto it
-- would move the cursor to nothing they can see.
local function visible(c)
  return c.status ~= 'resolved' or state.show_resolved
end

-- Whether a group is the span on screen. Only that span's comments have a place
-- relative to the cursor: every other one is about a diff that is not being
-- shown -- including a group filed under no member at all, which can only come
-- from a session saved before the working tree was one.
local function on_screen(group)
  if group.hash == nil then return false end
  return group.from == state.targeted_from and group.hash == state.current
end

-- The files of one span's comments, ranked. The span on screen has a changeset to
-- take its order from -- the files as the reader meets them -- and any other span
-- has none, so its files fall back to sorting by path. A file commented on and
-- since dropped from the changeset is ranked after the ones still in it, rather
-- than left unreachable.
local function ranks_for(group, ranks, files)
  local out, n = {}, 0
  if on_screen(group) then
    out, n = vim.deepcopy(ranks), files
  end
  local missing = {}
  for _, c in ipairs(state.for_span(group.from, group.hash)) do
    if c.path and out[c.path] == nil then missing[c.path] = true end
  end
  local paths = vim.tbl_keys(missing)
  table.sort(paths)
  for _, path in ipairs(paths) do
    n = n + 1
    out[path] = n
  end
  return out
end

-- Every stop of the walk, in reading order: what was said about the whole review
-- first, then span by span up the range -- the order the export's sections are
-- in -- and inside a span the comment about the span before its files. Each stop
-- carries the ranks its span was ordered by, which is what a cursor position is
-- compared against later.
local function stops(ranks, files)
  local list = {}
  -- A session comment is about the review rather than any part of it, so it is
  -- met once, at the top, instead of once per span.
  for _, c in ipairs(state.for_session()) do
    if visible(c) then table.insert(list, { comment = c }) end
  end
  for _, group in ipairs(state.comment_groups()) do
    local group_ranks = ranks_for(group, ranks, files)
    local span_stop, rest = nil, {}
    for _, c in ipairs(state.for_span(group.from, group.hash)) do
      if visible(c) then
        if c.scope == 'commit' then span_stop = c else table.insert(rest, c) end
      end
    end
    table.sort(rest, function(a, b)
      return lt(
        key(group_ranks[a.path], KIND[a.scope], a.lnum or 0),
        key(group_ranks[b.path], KIND[b.scope], b.lnum or 0))
    end)
    if span_stop then
      table.insert(list, { comment = span_stop, group = group, ranks = group_ranks })
    end
    for _, c in ipairs(rest) do
      table.insert(list, { comment = c, group = group, ranks = group_ranks })
    end
  end
  return list
end

local function stop_key(c, ranks)
  -- -1 on both axes: the comment about the span is its first stop, whatever the
  -- changeset holds.
  if c.scope == 'commit' then return key(-1, -1, 0) end
  return key(ranks[c.path] or math.huge, KIND[c.scope], c.lnum or 0)
end

-- The stop the last walk landed on, and where the cursor was left. A comment
-- about a span moves nothing, so without this the next press would find the
-- cursor exactly where the last one did and show the same comment again forever;
-- and a file comment is met at line 1, which as a cursor position sits *after*
-- it. The anchor holds only while the reader has not moved: the moment they do,
-- their own position is the truth again.
local anchor = nil

local function remember(c)
  anchor = { stop = c, buf = vim.api.nvim_get_current_buf(), lnum = vim.fn.line('.') }
end

-- Where the anchor sits in the list, while it still holds.
local function anchored(list)
  if not anchor then return nil end
  if anchor.buf ~= vim.api.nvim_get_current_buf() or anchor.lnum ~= vim.fn.line('.') then
    return nil
  end
  for i, stop in ipairs(list) do
    if stop.comment == anchor.stop then return i end
  end
  return nil
end

-- Where the reader stands, in the same order the stops are in, so a walk moves
-- from where they are rather than from wherever the last one ended. Nil when the
-- place they stand is not in the order at all -- another commit's buffer, a
-- float -- and then the walk starts at whichever end it is heading away from.
local function cursor_key(ranks)
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype == 'quickfix' then
    local qf = vim.fn.getqflist({ idx = 0, items = 0 })
    local item = (qf.items or {})[qf.idx or 0]
    local rank = item and ranks[hunks.entry_file(item)]
    -- Before the file's own comment: from the changeset window the next stop is
    -- everything this file has to say, starting with what is about the file.
    return rank and key(rank, KIND.file - 1, 0) or nil
  end
  local loc = buffers.locate(buf)
  if not loc or loc.commit ~= state.current or loc.from ~= state.targeted_from then return nil end
  return key(ranks[loc.rel] or math.huge, KIND.range, vim.fn.line('.'))
end

-- The reader's place in the list, as the index a step is taken from. Zero means
-- they are nowhere in it, so a step forward starts at the first stop and a step
-- back at the last. Otherwise it is the last stop of the span on screen that the
-- cursor has already passed: the stops of every other span have no position of
-- their own and are only ever reached by stepping.
local function position(list)
  local at = anchored(list)
  if at then return at end
  local first, last
  for i, stop in ipairs(list) do
    if stop.group and on_screen(stop.group) then
      first = first or i
      last = i
    end
  end
  if not first then return 0 end
  local pos = cursor_key(list[first].ranks)
  if not pos then return 0 end
  local at_index = first - 1
  for i = first, last do
    if lt(pos, stop_key(list[i].comment, list[i].ranks)) then break end
    at_index = i
  end
  return at_index
end

-- Put the reader on `rel` at `lnum`. The changeset is the way in: jumping
-- through its entry opens the file in the same buffer the hunk walk would,
-- which for a commit under review is its revision buffer and never the working
-- tree's copy. A file no longer in the list is opened directly.
local function goto_location(rel, lnum)
  local landed = false
  for i, item in ipairs(vim.fn.getqflist({ items = 0 }).items or {}) do
    if hunks.entry_file(item) == rel then
      vim.cmd(('%dcc'):format(i))
      landed = true
      break
    end
  end
  if not landed then
    -- Off the list: a span of commits opens its own content again, while a span
    -- ending at the Uncommitted Tip is the file on disk -- no revision buffer
    -- can hold what was never committed.
    if state.current and not state.is_uncommitted(state.current) then
      landed = buffers.open(state.current, rel, state.repo_root()) ~= nil
    else
      local root = state.repo_root()
      local path = root and (root .. '/' .. rel) or rel
      if vim.fn.filereadable(path) == 1 then
        vim.cmd('edit ' .. vim.fn.fnameescape(path))
        landed = true
      end
    end
  end
  if not landed then
    vim.notify(('Review: cannot open %s'):format(rel), vim.log.levels.WARN)
    return false
  end
  pcall(vim.api.nvim_win_set_cursor, 0,
    { math.max(1, math.min(lnum, vim.api.nvim_buf_line_count(0))), 0 })
  landing.land()
  return true
end

-- Arriving only moves. The comment's text is already drawn where it belongs, and
-- changing it is the comment key on its own line -- so, unlike a hunk arrival,
-- this never opens the form.
function M.arrive(c)
  local render = require('review.render')
  -- Whatever the last arrival put on the screen comes down first, so one press
  -- shows one comment.
  render.hide_commit_comment()
  if c.scope == 'commit' then
    -- A commit comment is about the whole changeset and has no line to move to,
    -- so arriving at one shows it instead of moving the cursor.
    render.show_commit_comment(c)
    remember(c)
    return true
  end
  -- A file comment draws above the first line, which is where the reader has to
  -- be to see it.
  if not goto_location(c.path, (c.scope == 'file') and 1 or c.lnum) then return false end
  remember(c)
  return true
end

local function walk(step)
  local ranks, files = file_ranks()
  local list = stops(ranks, files)
  if #list == 0 then
    vim.notify('Review: nothing said in this review yet', vim.log.levels.INFO)
    return false
  end
  local at = position(list)
  -- The wrap is how the reader learns they have been round everything they said.
  local target = (at == 0) and ((step > 0) and list[1] or list[#list])
    or list[((at - 1 + step) % #list) + 1]
  -- Through goto_comment, not arrive: a stop of another span has nowhere to land
  -- until that span is targeted.
  return M.goto_comment(target.comment)
end

function M.next_comment() return walk(1) end
function M.prev_comment() return walk(-1) end

-- Go to any comment of the session, wherever it lives: the walk's arrival with
-- the span change in front of it. A comment of another span targets that span
-- first, so the reader lands on it with the changeset around it that it was made
-- against -- which for a comment about three commits is those three commits read
-- as one diff again. Both the walk and the picker arrive through here.
function M.goto_comment(c)
  local render = require('review.render')
  render.hide_commit_comment()
  -- A session comment is about the whole review, so there is nowhere to move to
  -- -- it is shown where the reader stands, the way a commit comment is.
  if c.scope == 'session' then
    render.show_commit_comment(c)
    remember(c)
    return true
  end
  if c.commit and not state.targets(c) then
    if not require('review.session').target(c.commit_from, c.commit) then
      vim.notify(('Review: %s is no longer in the range'):format(
        (c.commit_from == c.commit) and c.commit
          or ('%s..%s'):format(c.commit_from, c.commit)), vim.log.levels.WARN)
      return false
    end
  end
  return M.arrive(c)
end

-- The comment picker: the list of what was said, and a jump to any of it. With
-- no `opts` it is everything in the review; the switcher passes `opts.member` to
-- narrow it to one member of the range, and `opts.on_dismiss` to be handed the
-- reader back when they chose nothing.
function M.pick(opts)
  return require('review.pickers').comment(function(c) M.goto_comment(c) end, opts)
end

return M
