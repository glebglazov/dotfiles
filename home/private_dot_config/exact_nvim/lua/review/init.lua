-- Local code review: annotate the changed files of a diff, then hand the notes
-- to an AI agent as one Markdown block. `setup{}` is the whole wiring surface —
-- it takes the keys to bind and the editor's default-base lookup, so the
-- modules below never reach back into the config that loads them.
local buffers = require('review.buffers')
local comments = require('review.comments')
local export = require('review.export')
local hunks = require('review.hunks')
local persist = require('review.persist')
local render = require('review.render')
local session = require('review.session')
local state = require('review.state')

local M = {}

-- Lua API: a session can be driven from here without a keymap or the command.
-- `spec` is { base, head, uncommitted } — see session.resolve.
function M.start(spec)
  return session.start(spec)
end

-- The same start, with the base taken from a highlighted commit.
M.start_from_selection = session.start_from_selection

function M.finish()
  session.finish()
end

-- The changeset alone, no session: quickfix list of files changed against base.
-- A session owns the quickfix list -- it is the hunk walk's position -- so this
-- refuses rather than wiping the walk out from under the reader.
function M.files(spec)
  if state.active then
    vim.notify('Review: session in progress — finish it before listing changed files', vim.log.levels.WARN)
    return false
  end
  return hunks.files(session.resolve(spec))
end

-- The changeset window back, without rebuilding the list behind it.
M.changeset = hunks.reopen

-- Staleness: re-check the range against git (`refresh`), and drop a session
-- whose commits are gone without exporting it (`discard`).
M.check = persist.check
M.discard = persist.discard

-- Move the review to another commit of the current range: a targeted range of
-- one.
function M.set_current(hash)
  return session.set_current(hash)
end

-- The wider move: read a contiguous span of the range as one diff.
M.target = session.target

-- The same move, made from the switcher instead of a known hash -- where a run
-- of commits can be marked instead of one chosen.
M.switch = session.switch_from_picker

-- A file as it stood at a commit, opened read-only in the current window.
M.next_hunk = hunks.next_hunk
M.prev_hunk = hunks.prev_hunk
M.first_hunk = hunks.first_hunk
M.last_hunk = hunks.last_hunk
M.next_file = hunks.next_file
M.prev_file = hunks.prev_file
M.next_comment = comments.next_comment
M.prev_comment = comments.prev_comment
M.pick_comment = comments.pick

M.open = buffers.open
M.investigate = buffers.investigate
M.export = export.export
M.preview = export.preview
M.send = export.send_preview
M.clear = state.clear

-- Every keymap the plugin owns, keyed by the name `setup{ keys = ... }` uses.
-- One action can bind several modes — an added comment takes its range from the
-- visual selection — so each mapping carries its own description.
local actions = {
  -- One key for every scope: the form itself cycles range → file → commit →
  -- session, so there is nothing separate to bind for a note about the whole
  -- file, the whole commit or the whole review.
  add_comment = {
    { mode = 'n', fn = state.add_normal, desc = 'Review: add comment (<Tab> cycles scope)' },
    { mode = 'v', fn = state.add_visual, desc = 'Review: add comment (range, <Tab> cycles scope)' },
  },
  delete_comment = {
    { mode = 'n', fn = state.delete_at_cursor, desc = 'Review: delete comment at cursor (or this file\'s)' },
  },
  export = {
    { mode = 'n', fn = export.export, desc = 'Review: export comments to clipboard' },
  },
  -- One key for "show me the list": inside a session it is the changeset put
  -- back on screen where the reader left it, and outside one -- where there is
  -- no changeset -- it is the changed files of the default base, which is the
  -- nearest thing to a list there is.
  files = {
    { mode = 'n', fn = function()
        if state.active then return hunks.reopen() end
        return M.files()
      end, desc = 'Review: reopen the changeset (no session: changed files)' },
  },
  -- Out to the Investigation Tab and back again, on the one key: the working
  -- tree copy of this file opens in a tab of its own, and pressing it there
  -- returns to the review, which was never disturbed.
  investigate = {
    { mode = 'n', fn = buffers.investigate, desc = 'Review: investigate this file in its own tab (and back)' },
  },
  -- The whole branch, on one keypress: no chooser, nothing to land on by
  -- mistake. Another base is a typed `:Review start <ref>` -- or, on the same
  -- key, a highlighted commit: the range then starts at that commit instead of
  -- at the branch point, which is how a stack is read from partway up.
  start = {
    { mode = 'n', fn = function() M.start() end, desc = 'Review: start session (whole branch → HEAD)' },
    { mode = 'v', fn = session.start_from_selection,
      desc = 'Review: start session (highlighted commit → HEAD)' },
  },
  -- Its own key, not a mode of `start`: `start` asks nothing, this one lists the
  -- range -- and a switch must never be able to run without a session.
  switch = {
    { mode = 'n', fn = session.switch_from_picker, desc = 'Review: target a commit or a marked span of the range' },
  },
  start_uncommitted = {
    { mode = 'n', fn = function() M.start({ uncommitted = true }) end, desc = 'Review: start session (uncommitted)' },
  },
  clear = {
    { mode = 'n', fn = state.clear, desc = 'Review: clear all comments' },
  },
  finish = {
    { mode = 'n', fn = session.finish, desc = 'Review: finish (export + clear + signs off)' },
  },
  preview = {
    { mode = 'n', fn = export.preview, desc = 'Review: preview in float' },
  },
  -- Everything said in the review, listed in one place and jumped to from there,
  -- whichever span of the range it was said about -- jumping to one targets its
  -- span first. Not a mode of `preview`: the preview is a document to read, this
  -- is a way to move -- and it is the only place a `session` comment can be
  -- reached.
  pick_comment = {
    { mode = 'n', fn = comments.pick, desc = 'Review: list all comments (jump to one)' },
  },
  send = {
    { mode = 'n', fn = export.send_preview, desc = 'Review: send comments to Pop pane' },
  },
  -- The walk through the current commit's hunks. Both directions wrap, so the
  -- reader meets the commit's first hunk again instead of stopping or sliding
  -- into another commit.
  --
  -- These carry `scoped`: they are bound on the review's own surfaces and
  -- nowhere else (see buffers.attach). That is what makes short keys that
  -- shadow editor defaults -- `]f`, `<Tab>` -- acceptable, and it is why none of
  -- them has a "no session" branch: off the review they are not bound at all.
  next_hunk = {
    scoped = true,
    { mode = 'n', fn = hunks.next_hunk, desc = 'Review: next hunk' },
  },
  prev_hunk = {
    scoped = true,
    { mode = 'n', fn = hunks.prev_hunk, desc = 'Review: previous hunk' },
  },
  first_hunk = {
    scoped = true,
    { mode = 'n', fn = hunks.first_hunk, desc = "Review: commit's first hunk" },
  },
  last_hunk = {
    scoped = true,
    { mode = 'n', fn = hunks.last_hunk, desc = "Review: commit's last hunk" },
  },
  -- The same walk taken a file at a time, over the same changeset. Both
  -- directions land on the file's first hunk, so the reader arrives where the
  -- file starts however far into the last one they had read.
  next_file = {
    scoped = true,
    { mode = 'n', fn = hunks.next_file, desc = "Review: next file's first hunk" },
  },
  prev_file = {
    scoped = true,
    { mode = 'n', fn = hunks.prev_file, desc = "Review: previous file's first hunk" },
  },
  -- The walk through what the reader has already said about the span they are
  -- reading, taken in reading order and wrapping like the hunk walk. Arriving
  -- only moves -- the comment's text is already on screen, and editing it is
  -- `comment_hunk` on its own line.
  next_comment = {
    scoped = true,
    { mode = 'n', fn = comments.next_comment, desc = "Review: next comment on this range" },
  },
  prev_comment = {
    scoped = true,
    { mode = 'n', fn = comments.prev_comment, desc = "Review: previous comment on this range" },
  },
  -- A comment on the hunk in front of the reader, one key away. The form's own
  -- `<Tab>` widens the scope, so `<Tab><Tab>` is "comment, one scope wider".
  -- `add_comment` stays for the surfaces these local keys do not reach.
  comment_hunk = {
    scoped = true,
    { mode = 'n', fn = state.add_normal, desc = 'Review: comment on this hunk (<Tab> cycles scope)' },
    { mode = 'v', fn = state.add_visual, desc = 'Review: comment on this range (<Tab> cycles scope)' },
  },
  -- The session's own toggles, kept under one prefix of their own: <leader>t*
  -- already answers to gitsigns, neotest and rubocop.
  toggle_auto_form = {
    { mode = 'n', fn = state.toggle_auto_form, desc = 'Review: toggle comment form on hunk arrival' },
  },
  toggle_signs = {
    { mode = 'n', fn = function() session.with_gitsigns(function(gs) gs.toggle_signs() end) end,
      desc = 'Review: toggle git signs' },
  },
  toggle_deleted = {
    { mode = 'n', fn = function() session.with_gitsigns(function(gs) gs.toggle_deleted() end) end,
      desc = 'Review: toggle deleted lines inline' },
  },
  toggle_resolved = {
    { mode = 'n', fn = state.toggle_resolved, desc = 'Review: toggle resolved comments' },
  },
}

function M.setup(opts)
  opts = opts or {}
  if opts.default_base then session.default_base = opts.default_base end
  buffers.setup()

  -- Two halves: the keys that answer anywhere are set here and for good, and
  -- the review-local ones are handed to `buffers`, which puts them on a
  -- session's buffers and the changeset window as they are met.
  local scoped = {}
  for name, lhs in pairs(opts.keys or {}) do
    local action = actions[name]
    if not action then
      vim.notify('review.setup: unknown key action ' .. name, vim.log.levels.WARN)
    else
      for _, map in ipairs(action) do
        if action.scoped then
          table.insert(scoped, { mode = map.mode, lhs = lhs, fn = map.fn, desc = map.desc })
        else
          vim.keymap.set(map.mode, lhs, map.fn, { silent = true, desc = map.desc })
        end
      end
    end
  end
  buffers.set_local_keys(scoped)

  -- :Review [start [<ref>] | finish | check | discard]
  --   start   — begin a session against <ref> (default remote branch if omitted)
  --   finish  — export + clear + signs off
  --   check   — re-test the range against git and report a rewritten stack
  --   discard — drop the session (and its saved state) without exporting
  vim.api.nvim_create_user_command('Review', function(cmd)
    local sub = cmd.fargs[1] or 'start'
    if sub == 'finish' then
      M.finish()
    elseif sub == 'start' then
      M.start({ base = cmd.fargs[2] })
    elseif sub == 'check' then
      if not persist.check() then
        vim.notify('Review: every commit under review still exists', vim.log.levels.INFO)
      end
    elseif sub == 'discard' then
      persist.discard()
    else
      vim.notify('Review: unknown subcommand ' .. sub, vim.log.levels.WARN)
    end
  end, { nargs = '*', desc = 'Local code review session (start/finish)' })

  vim.api.nvim_create_user_command('ReviewClear', state.clear, { desc = 'Review: clear all comments' })

  -- Re-render inline comments when a buffer is shown (e.g. after jumping via quickfix).
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = vim.api.nvim_create_augroup('glebglazov-review-render', { clear = true }),
    callback = function(args)
      render.buffer(args.buf)
    end,
  })

  -- The session of this repository, if there is one, picked up where it was left.
  -- Scheduled so it runs after the rest of startup: it notifies, touches
  -- gitsigns and repopulates the quickfix list.
  vim.schedule(function() persist.restore() end)
end

return M
