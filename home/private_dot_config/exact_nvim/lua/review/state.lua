-- The comments a review session collects. State lives here, NOT in the
-- quickfix list, so it never collides with the changeset list a session
-- populates — and every other review module reads its comments from here.
local buffers = require('review.buffers')

-- A comment is about a range of lines, a whole file, a whole commit or the
-- whole session. Kept in widening order: the form cycles through it, and the
-- export lists a commit's comments widest first.
local SCOPES = { 'range', 'file', 'commit', 'session' }
local SCOPE_ORDER = { commit = 1, file = 2, range = 3 }

local M = {
  -- One flat list rather than a table per file: a comment carries the span of
  -- commits it was written against, so the same file read as part of two
  -- different spans keeps two sets of comments and the export can group by span
  -- instead of by path.
  -- { scope, commit_from, commit, path, lnum, end_line, text, status, rebound }
  --   scope  — 'range' | 'file' | 'commit' | 'session'
  --   commit_from, commit — the ends of the targeted range it was written
  --            against, oldest and newest. The same hash for a range of one,
  --            which is the identity a comment on a single commit has always
  --            had; both nil for session scope. Either end may be the
  --            Uncommitted Tip. Reassignable, once: a rewrite refiles the
  --            comment onto HEAD (docs/adr/0006).
  --   rebound — set by that refile, because the lines below it then describe
  --            lines that have moved; nil for a comment still filed where it
  --            was written.
  --   path   — repository-relative path, so the same file at the same span is
  --            one thing however it was opened; nil for commit and session scope
  --   lnum, end_line — range scope only
  comments = {},
  active = false, -- whether a review session is in progress (drives statusline)
  -- What a session covers, held as two pieces rather than one: the range is
  -- resolved when the session starts, while the span of it being read moves
  -- through it as the review goes on.
  range = {}, -- members under review, oldest first: { { hash, date, subject }, ... }
  -- The targeted range: the contiguous span of `range` the changeset is built
  -- from, read as one diff against the commit before it. Its newest commit is
  -- the current commit -- the one whose content the revision buffers show -- so
  -- `current` is that end of the span and `targeted_from` is the other.
  current = nil, -- hash of the newest member of the targeted range
  targeted_from = nil, -- hash of its oldest; the same hash for a span of one
  spec = nil, -- what the range was resolved from: { base, head } — the export's summary
  -- How the reader wants the session to behave. Off by default because most
  -- hunks are ones there is nothing to say about, so a form on every arrival
  -- would be in the way more often than not.
  auto_form = false, -- open the comment form on arriving at a hunk
  show_resolved = true, -- keep resolved comments visible in the buffers
}

M.SCOPES = SCOPES

-- The Uncommitted Tip: the working tree as a member of the range, sitting past
-- HEAD under this identity. It is a member only while there is something
-- uncommitted, so it comes and goes as the reader works (docs/adr/0004) -- and
-- a comment made against it is refiled onto HEAD when it goes, like every other
-- comment filed under something the range no longer holds (docs/adr/0006).
M.UNCOMMITTED = 'uncommitted'

function M.is_uncommitted(hash)
  return hash == M.UNCOMMITTED
end

-- The tip as a range entry, in the shape every other member has -- the switcher
-- lists it, the walk targets it and the export heads a section with it, none of
-- them knowing it is not a commit.
function M.uncommitted_entry()
  return { hash = M.UNCOMMITTED, date = os.date('%Y-%m-%d'), subject = 'uncommitted changes' }
end

-- Every change to the store passes through here, so the session on disk is
-- never older than the session on screen. Required lazily: review.persist reads
-- this module.
function M.save()
  require('review.persist').save()
end

-- Flip a toggle and say what it now is: these are keys pressed mid-read, so the
-- answer has to arrive without leaving the hunk.
function M.toggle(name, label)
  M[name] = not M[name]
  M.save()
  vim.notify(('Review: %s %s'):format(label, M[name] and 'on' or 'off'), vim.log.levels.INFO)
  return M[name]
end

function M.toggle_auto_form()
  M.toggle('auto_form', 'comment form on arrival')
end

function M.toggle_resolved()
  M.toggle('show_resolved', 'resolved comments')
  require('review.render').all()
end

-- Adopt `members` (oldest first) as the range under review, with the whole of
-- it targeted: the first thing the reader sees is the branch as one diff, the
-- way they would read a pull request.
function M.set_range(members, spec)
  M.range = members or {}
  local oldest, newest = M.range[1], M.range[#M.range]
  M.set_targeted(oldest and oldest.hash or nil, newest and newest.hash or nil)
  M.spec = spec
  M.save()
end

-- The range dropped along with everything else the session held. The end of a
-- session is the only place this belongs: a running review never loses its
-- range, because losing it would leave every comment attached to something the
-- session no longer holds.
function M.clear_range()
  M.range = {}
  M.current = nil
  M.targeted_from = nil
  M.spec = nil
end

-- Where `hash` sits in the range, 1-based; nil for a member outside it.
function M.index_of(hash)
  for i, c in ipairs(M.range) do
    if c.hash == hash then return i end
  end
  return nil
end

-- Target the span `oldest`..`newest` of the range, both ends included. Refuses
-- -- and changes nothing -- when an end is outside the range or the pair runs
-- backwards: `git diff` has no way to express that span, so there would be no
-- changeset to show.
function M.set_targeted(oldest, newest)
  local from, to = M.index_of(oldest), M.index_of(newest)
  if not from or not to or from > to then return false end
  M.targeted_from, M.current = oldest, newest
  return true
end

-- The members of the targeted range, oldest first -- the span the changeset is
-- built from. Empty for a span whose ends have fallen out of the range.
function M.targeted()
  local from, to = M.index_of(M.targeted_from), M.index_of(M.current)
  if not from or not to or from > to then return {} end
  local span = {}
  for i = from, to do table.insert(span, M.range[i]) end
  return span
end

-- How many members the span `from`..`to` covers, or nil when the range no
-- longer holds both of its ends. A span of one is one member whether or not the
-- range still has it: that is what a comment on a rewritten commit -- or on the
-- tip, once its work is committed -- still knows about itself.
function M.span_length(from, to)
  if from == to then return from and 1 or nil end
  local a, b = M.index_of(from), M.index_of(to)
  if not a or not b or a > b then return nil end
  return b - a + 1
end

-- The { hash, date, subject } entry `current` points at, if any.
function M.current_commit()
  local i = M.index_of(M.current)
  return i and M.range[i] or nil
end

-- How far through the range the current member is, 1-based; nil when the
-- current member fell out of the range.
function M.current_index()
  return M.index_of(M.current)
end

-- How a commit reads in an export heading. Range entries already carry the
-- subject; a hash from outside the range (one a refile has yet to reach) is
-- asked for. The
-- tip is asked for too once its work is committed and it has left the range --
-- and git has no such object, so it answers for itself.
function M.subject(hash)
  for _, c in ipairs(M.range) do
    if c.hash == hash then return c.subject end
  end
  if M.is_uncommitted(hash) then return 'uncommitted changes' end
  local out = vim.fn.systemlist({ 'git', '--no-pager', 'log', '-1', '--format=%s', hash })
  return (vim.v.shell_error == 0 and out[1]) or ''
end

-- Asked once per working directory: every render pass resolves each loaded
-- buffer against the root, and a git process per buffer per redraw is not
-- affordable.
local roots = {}
function M.repo_root()
  local cwd = vim.fn.getcwd()
  if roots[cwd] == nil then
    local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
    roots[cwd] = (vim.v.shell_error == 0 and root and root ~= '') and root or false
  end
  return roots[cwd] or nil
end

-- Everything said about one file while one span of commits was targeted: the
-- range comments that draw at their own lines and the file comment that draws
-- above the top. Span plus path is what a comment is identified by, so a buffer
-- holding the file finds the same list whether it was opened as commit content
-- or off disk -- and a comment written against another span is not drawn here,
-- because the diff it was about is not the diff on screen.
function M.for_location(from, commit, rel)
  local list = {}
  for _, c in ipairs(M.comments) do
    if (c.scope == 'range' or c.scope == 'file')
      and c.commit == commit and c.commit_from == from and c.path == rel then
      table.insert(list, c)
    end
  end
  return list
end

-- Where a comment sits, as the export and the preview print it. A commit
-- comment says only 'commit' because the heading it lives under carries the
-- hash already.
function M.label(c)
  if c.scope == 'session' then return 'session' end
  if c.scope == 'commit' then return 'commit' end
  if c.scope == 'file' then return c.path end
  return (c.end_line and c.end_line ~= c.lnum)
    and ('%s:%d-%d'):format(c.path, c.lnum, c.end_line)
    or ('%s:%d'):format(c.path, c.lnum)
end

-- Whether `c` was written against the span the session is targeting right now.
-- One question, asked by everything that shows a comment where the reader is:
-- the buffers draw it, the walk stops at it, the changeset title carries it.
function M.targets(c)
  return c.scope ~= 'session' and c.commit == M.current and c.commit_from == M.targeted_from
end

-- The comments of one span, widest scope first and then by path and line, so a
-- span's section reads from "about all of this" down to single lines.
function M.for_span(from, to)
  local list = {}
  for _, c in ipairs(M.comments) do
    if c.scope ~= 'session' and c.commit == to and c.commit_from == from then
      table.insert(list, c)
    end
  end
  table.sort(list, function(a, b)
    if a.scope ~= b.scope then return SCOPE_ORDER[a.scope] < SCOPE_ORDER[b.scope] end
    local ap, bp = a.path or '', b.path or ''
    if ap ~= bp then return ap < bp end
    return (a.lnum or 0) < (b.lnum or 0)
  end)
  return list
end

function M.for_session()
  local list = {}
  for _, c in ipairs(M.comments) do
    if c.scope == 'session' then table.insert(list, c) end
  end
  return list
end

-- Whether the span `c` was written against holds `hash`. A comment about three
-- commits is about each of them, so it is counted on every row of the run --
-- and a span whose ends have left the range is only ever itself.
local function span_holds(c, hash)
  if c.commit == hash or c.commit_from == hash then return true end
  local i, from, to = M.index_of(hash), M.index_of(c.commit_from), M.index_of(c.commit)
  return i ~= nil and from ~= nil and to ~= nil and i >= from and i <= to
end

-- What a commit carries, split the way the switcher reads it: pending is what a
-- finish would still send, resolved is what has been dealt with but kept. A
-- comment written against a span counts on every commit of that span.
function M.counts_for_commit(hash)
  local pending, resolved = 0, 0
  for _, c in ipairs(M.comments) do
    if c.scope ~= 'session' and span_holds(c, hash) then
      if c.status == 'resolved' then resolved = resolved + 1 else pending = pending + 1 end
    end
  end
  return pending, resolved
end

-- One key per span, for the group builder below. The separator is a byte no
-- hash holds, so two spans can never collide into one group.
local function group_key(from, to)
  return (from or '') .. '\0' .. (to or '')
end

-- The spans a session's comments are filed under, in the order a reader meets
-- them: every member of the range as a span of one -- the working tree among
-- them while it is a member -- then the wider spans that collected comments, and
-- then anything said against members the range no longer holds, which is where a
-- comment on the tip goes once its work is committed.
--
-- One shape, two readers -- the export heads a section with each group and the
-- comment picker groups its rows by them -- so the two can never disagree about
-- what a review is made of. Neither heading text lives here: each caller writes
-- its own from the fields.
--
-- A group is { from, hash, subject, commits }: `from`..`hash` is the span,
-- `commits` how many commits it covers (nil once the range has lost an end),
-- and `subject` the commit's own subject, which only a span of one has.
function M.comment_groups()
  local out, seen = {}, {}
  local function add(g)
    local key = group_key(g.from, g.hash)
    if seen[key] then return end
    seen[key] = true
    table.insert(out, g)
  end
  -- Every member of the range gets a group whether or not it collected
  -- comments: a reader of the export has to be able to tell "read and fine"
  -- from "not read".
  for _, c in ipairs(M.range) do
    add({ from = c.hash, hash = c.hash, subject = c.subject, commits = 1 })
  end
  -- Sessions from before the tip was a member of the range filed their comments
  -- under no commit at all. Nothing writes those any more -- persist converts
  -- them on read -- but one met here still gets a group, rather than dropping
  -- out of the export.
  local unfiled = false
  local extra, wider = {}, {}
  for _, c in ipairs(M.comments) do
    if c.scope ~= 'session' then
      if c.commit == nil then
        unfiled = true
      else
        local key = group_key(c.commit_from, c.commit)
        if not seen[key] and not extra[key] then
          extra[key] = true
          table.insert(wider, { from = c.commit_from, hash = c.commit })
        end
      end
    end
  end
  -- Sorted by where the span begins and then by where it ends, so a wider span
  -- sits with the commits it covers; the ones the range has lost sort last, and
  -- by hash, so the order never depends on the order the comments were made in.
  table.sort(wider, function(a, b)
    local ai, bi = M.index_of(a.from) or math.huge, M.index_of(b.from) or math.huge
    if ai ~= bi then return ai < bi end
    local aj, bj = M.index_of(a.hash) or math.huge, M.index_of(b.hash) or math.huge
    if aj ~= bj then return aj < bj end
    return (a.from or '') .. (a.hash or '') < (b.from or '') .. (b.hash or '')
  end)
  for _, g in ipairs(wider) do
    add({
      from = g.from,
      hash = g.hash,
      subject = (g.from == g.hash) and M.subject(g.hash) or nil,
      commits = M.span_length(g.from, g.hash),
    })
  end
  if unfiled then add({ from = nil, hash = nil, subject = 'working tree' }) end
  return out
end

-- Pending comments across every scope — the same set the export builds, so the
-- statusline badge matches what a finish would send.
function M.pending_count()
  local n = 0
  for _, c in ipairs(M.comments) do
    if c.status ~= 'resolved' then n = n + 1 end
  end
  return n
end

function M.remove(comment)
  for i = #M.comments, 1, -1 do
    if M.comments[i] == comment then table.remove(M.comments, i) end
  end
end

-- The comment a save at `target` would land on, if there already is one. The
-- widened scopes hold at most one comment each, so they match on scope alone;
-- a range matches by span — a single-line request (cursor, no visual range)
-- edits whatever comment covers that line, an explicit range only a comment
-- with the exact same span.
function M.find(target)
  for _, c in ipairs(M.comments) do
    if c.scope == target.scope and c.commit == target.commit
      and c.commit_from == target.commit_from then
      if target.scope == 'session' or target.scope == 'commit' then
        return c
      elseif c.path == target.path then
        if target.scope == 'file' then
          return c
        else
          local cs, ce = c.lnum, (c.end_line or c.lnum)
          if target.single and target.lnum >= cs and target.lnum <= ce then return c end
          if not target.single and cs == target.lnum and ce == target.end_line then return c end
        end
      end
    end
  end
  return nil
end

-- The scopes the form can cycle, for the place the form was opened from. A
-- buffer the review cannot place -- no name, or a file outside the repository
-- -- leaves only the session itself. Lines are the one thing that does not
-- carry across: a file on disk read while commits are targeted shows HEAD, so
-- line 42 there is not line 42 of the commit being read, and `range` is
-- withheld rather than recorded against the wrong lines. A span ending at the
-- tip *is* the files on disk, so there its lines are the true ones.
local function scopes_here(loc, commit)
  local lines_true = loc ~= nil and (loc.revision or M.is_uncommitted(commit))
  local usable = {}
  for _, scope in ipairs(SCOPES) do
    local ok = true
    if scope == 'range' and not lines_true then ok = false end
    if scope == 'file' and not loc then ok = false end
    if scope == 'commit' and not commit then ok = false end
    if ok then table.insert(usable, scope) end
  end
  return usable
end

-- Where the comment form goes, given the last line of what is being commented
-- on. Below that line while the whole form still fits in the window there, and
-- pinned to the window's bottom when it does not: a hunk taller than the window
-- leaves the cursor somewhere in the middle of it, and a cursor-relative row
-- past the last window row is clamped back up over the very lines the comment is
-- about. The bottom is the one place that can never cover them.
local function form_position(cur_line, below, height)
  local rows = height + 2 -- the border counts: it is what would sit on the code
  local win_height = vim.api.nvim_win_get_height(0)
  -- Clamped to the buffer: a hunk end recorded against a longer version of the
  -- file would otherwise put the form below anything that exists.
  below = math.min(below, vim.api.nvim_buf_line_count(0))
  local offset = math.max(1, below - cur_line + 1)
  -- `winline()` is the window row the cursor sits on, so this is the row the
  -- form's bottom border would take. Counted in buffer lines, like the offset it
  -- is added to; a wrapped line makes it an underestimate, and all that costs is
  -- a form placed below the hunk where it could have gone to the bottom.
  if vim.fn.winline() + offset + rows - 1 <= win_height then
    return { relative = 'cursor', row = offset, col = 0 }
  end
  return { relative = 'win', win = 0, row = math.max(0, win_height - rows), col = 0 }
end

-- The comment form. One float for every scope: `<Tab>` widens (range → file →
-- commit → session → range) and `<S-Tab>` narrows the same ring back, so no
-- scope is ever three presses away; the title says which scope the text will
-- land at, and the text carries over, so widening a half-typed comment is one
-- keypress.
function M.add(start_line, end_line)
  -- What the buffer is about, rather than what it is called: a comment belongs
  -- to a commit and a path, so one made here is found again from any other
  -- buffer holding the same file at the same commit.
  local loc = buffers.locate(0)
  local path = loc and loc.rel or nil
  local commit = loc and loc.commit or M.current
  local commit_from = loc and loc.from or M.targeted_from
  local scopes = scopes_here(loc, commit)
  local index = 1

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'
  vim.b[buf].completion = false -- blink.cmp honours this: no autocomplete popup in the comment box
  local width = math.min(80, math.floor(vim.o.columns * 0.6))
  -- The cursor is left alone wherever the form lands -- moving it would move
  -- where the walk resumes and where an unselected comment anchors -- so only
  -- the float is placed.
  local cur_line = vim.fn.line('.')
  -- Remembered before the float takes the cursor: everything below asks the
  -- changeset about the buffer the comment is about, not about the form.
  local src_buf = vim.api.nvim_get_current_buf()
  local hunk_end = require('review.hunks').current_hunk_end(src_buf, cur_line)
  local below = math.max(end_line or cur_line, hunk_end or 0, cur_line)
  local height = 8
  local win = vim.api.nvim_open_win(buf, true, vim.tbl_extend('force', {
    width = width,
    height = height,
    border = 'rounded',
    title = ' Review comment ',
    title_pos = 'center',
    style = 'minimal',
  }, form_position(cur_line, below, height)))

  -- What the form is aiming at right now, and the text it put in the buffer for
  -- it. The loaded text is remembered so cycling can tell a comment the reader
  -- has started changing (leave it alone, carry it over) from one they have only
  -- been shown (replace it with the new scope's own text).
  local target, existing, loaded
  -- The comment the form opened on, if any: widening carries it to the new
  -- scope instead of leaving a copy behind at the old one.
  local origin
  local function retarget()
    local scope = scopes[index]
    target = {
      scope = scope,
      -- A session comment belongs to no commit; every other scope to the span
      -- being read. (Spelled out, not `and nil or`, which never yields nil.)
      commit = scope ~= 'session' and commit or nil,
      commit_from = scope ~= 'session' and commit_from or nil,
      path = (scope == 'range' or scope == 'file') and path or nil,
      lnum = (scope == 'range') and start_line or nil,
      end_line = (scope == 'range') and end_line or nil,
      single = start_line == end_line,
    }
    existing = M.find(target)
  end

  local function set_text(text)
    local lines = vim.split(text, '\n', { plain = true })
    table.insert(lines, '') -- fresh trailing line so the cursor lands ready to keep typing
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    loaded = text
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_set_cursor, win, { vim.api.nvim_buf_line_count(buf), 0 })
    end
  end

  local function buffer_text()
    return vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'))
  end

  -- What the footer says the text is about. Wider than `M.label`, which prints
  -- locations for an export that has a commit heading over them already.
  local function aim()
    if target.scope == 'session' then return 'whole review' end
    if target.scope == 'commit' then
      local span = M.targeted()
      if #span > 1 then
        return ('%s..%s'):format(span[1].hash, span[#span].hash)
      end
      local c = M.current_commit()
      return c and c.hash or 'this commit'
    end
    return M.label(target)
  end

  -- Whether the lines being commented on are exactly a hunk's. A form opened on
  -- a hunk's first line is about that hunk -- that is what `<Tab>` on the review
  -- means -- and so is a selection that runs to the hunk's end; anything else is
  -- lines the reader picked out themselves, and only line numbers can say which.
  local function on_whole_hunk()
    if target.scope ~= 'range' or not target.lnum then return false end
    local hunk_last = require('review.hunks').current_hunk_end(src_buf, target.lnum)
    if not hunk_last then return false end
    local last = target.end_line or target.lnum
    return last == target.lnum or last == hunk_last
  end

  -- Where the text will land, said the way the reader thinks of it: the hunk in
  -- front of them, the lines they highlighted, the file, the span, the review.
  local function scope_text()
    if target.scope == 'range' then
      if on_whole_hunk() then return ('this hunk · %s'):format(target.path) end
      local last = target.end_line or target.lnum
      return (last ~= target.lnum)
        and ('lines %d-%d · %s'):format(target.lnum, last, target.path)
        or ('line %d · %s'):format(target.lnum, target.path)
    end
    if target.scope == 'file' then return ('whole file · %s'):format(target.path) end
    return aim()
  end

  -- The scope on the left, the way to the help on the right. A float takes one
  -- footer with one `footer_pos`, so the gap between them is padded by hand
  -- against the width the form was opened at. A long path loses its head rather
  -- than pushing the hint off the border.
  local function footer()
    local hint = '? help'
    local left = scope_text()
    local room = width - 2 - #hint - 1
    if vim.fn.strdisplaywidth(left) > room then
      left = '…' .. vim.fn.strcharpart(left, vim.fn.strchars(left) - room + 1)
    end
    local gap = width - 2 - vim.fn.strdisplaywidth(left) - #hint
    return (' %s%s%s '):format(left, (' '):rep(math.max(1, gap)), hint)
  end

  local function dress()
    vim.api.nvim_win_set_config(win, {
      title = (' %s '):format(existing and 'Edit review comment' or 'Review comment'),
      title_pos = 'center',
      footer = footer(),
      footer_pos = 'left',
    })
  end

  retarget()
  origin = existing
  if existing then set_text(existing.text) else loaded = '' end
  dress()

  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
      vim.cmd('startinsert!')
    end
  end)

  local function cycle(step)
    local untouched = buffer_text() == vim.trim(loaded or '')
    local moving = existing
    index = (index - 1 + step) % #scopes + 1
    retarget()
    -- Text the reader typed follows them to the wider scope; text that was only
    -- shown to them is replaced by whatever already stands at the new scope.
    if untouched and moving ~= existing then
      set_text(existing and existing.text or '')
    end
    dress()
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  local function confirm()
    local text = buffer_text()
    local from = existing
    close()
    if text == '' then
      -- Emptied: drop the comment at this scope. A comment the form opened on
      -- at another scope is left as it was.
      if from then M.remove(from) end
    else
      -- A widened comment moves rather than doubling: the one the form opened
      -- on is dropped and its text lands at the new scope.
      if origin and origin ~= from then M.remove(origin) end
      if from then
        from.text = text
        -- Editing a rebound comment is the reader taking ownership of what it
        -- now says, lines and all, so the warning about its lines comes off.
        from.rebound = nil
      else
        table.insert(M.comments, {
          scope = target.scope,
          commit_from = target.commit_from,
          commit = target.commit,
          path = target.path,
          lnum = target.lnum,
          end_line = target.end_line,
          text = text,
          status = 'unresolved',
        })
      end
    end
    M.save()
    require('review.render').all()
  end
  vim.keymap.set({ 'n', 'i' }, '<Tab>', function() cycle(1) end, { buffer = buf, nowait = true })
  vim.keymap.set({ 'n', 'i' }, '<S-Tab>', function() cycle(-1) end, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<CR>', confirm, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true })
  -- The same help the review's own surfaces open, reachable from inside the
  -- form: what the footer's hint points at. Normal mode only -- `?` typed while
  -- writing is a question mark.
  vim.keymap.set('n', '?', function() require('review.help').toggle() end,
    { buffer = buf, nowait = true })
end

function M.add_normal()
  local lnum = vim.fn.line('.')
  M.add(lnum, lnum)
end

function M.add_visual()
  local s = vim.fn.getpos('v')[2]
  local e = vim.fn.getpos('.')[2]
  -- leave visual mode synchronously BEFORE opening the float; a queued nvim_input('<ESC>')
  -- would otherwise land after startinsert and kick us back to normal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'nx', false)
  M.add(math.min(s, e), math.max(s, e))
end

-- Delete what the cursor stands in: the range comments covering this line, or
-- the file comment on this buffer when no range comment is under the cursor.
function M.delete_at_cursor()
  local loc = buffers.locate(0)
  if not loc then return end
  local cur = vim.fn.line('.')
  local function drop(matches)
    local hit = false
    for i = #M.comments, 1, -1 do
      local c = M.comments[i]
      if c.commit == loc.commit and c.commit_from == loc.from
        and c.path == loc.rel and matches(c) then
        table.remove(M.comments, i)
        hit = true
      end
    end
    return hit
  end
  local hit = drop(function(c)
    return c.scope == 'range' and cur >= c.lnum and cur <= (c.end_line or c.lnum)
  end)
  if not hit then drop(function(c) return c.scope == 'file' end) end
  M.save()
  require('review.render').all()
end

function M.clear()
  M.comments = {}
  M.save()
  require('review.render').all()
  vim.notify('Review comments cleared', vim.log.levels.INFO)
end

return M
