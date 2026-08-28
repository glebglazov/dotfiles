-- What the review's keys do, said out loud. The rows are handed over by
-- `review.setup` as it binds them -- one row per mapping it actually made -- so
-- the overlay can never name a key the review does not answer to, and a key
-- left out of `setup{ keys = ... }` is left out of the help with it.
local M = {}

-- { { lhs, mode, desc, scoped }, ... }, in whatever order the actions table was
-- walked in; `lines()` puts them in reading order.
M.keys = {}

function M.record(keys)
  M.keys = keys or {}
end

-- A key's own description, without the prefix every one of them carries: the
-- overlay is already titled "Review".
local function said(desc)
  return (desc or ''):gsub('^Review:%s*', '')
end

-- Two sections, because the review has two kinds of key: the short ones that
-- answer only where the review is being read, and the leader keys that answer
-- anywhere. Within a section, ordered by the key itself -- the one order that
-- follows from the bindings rather than from a second list to keep in step.
local function sections()
  local scoped, anywhere = {}, {}
  for _, key in ipairs(M.keys) do
    table.insert(key.scoped and scoped or anywhere, key)
  end
  local function by_key(a, b)
    if a.lhs ~= b.lhs then return a.lhs < b.lhs end
    return (a.mode or '') < (b.mode or '')
  end
  table.sort(scoped, by_key)
  table.sort(anywhere, by_key)
  return {
    { title = 'While reading the review', rows = scoped },
    { title = 'Anywhere', rows = anywhere },
  }
end

-- The overlay's text. Three columns -- key, mode, what it does -- because an
-- action bound in both normal and visual mode does two different things, and
-- the key alone cannot say which is which.
function M.lines()
  local groups = sections()
  local key_width, mode_width = 0, 1
  for _, group in ipairs(groups) do
    for _, row in ipairs(group.rows) do
      key_width = math.max(key_width, vim.fn.strdisplaywidth(row.lhs))
      mode_width = math.max(mode_width, vim.fn.strdisplaywidth(row.mode or ''))
    end
  end
  local function pad(text, width)
    return text .. (' '):rep(math.max(0, width - vim.fn.strdisplaywidth(text)))
  end
  local lines = {}
  for _, group in ipairs(groups) do
    if #group.rows > 0 then
      if #lines > 0 then table.insert(lines, '') end
      table.insert(lines, ' ' .. group.title)
      for _, row in ipairs(group.rows) do
        table.insert(lines, ('  %s  %s  %s'):format(
          pad(row.lhs, key_width), pad(row.mode or '', mode_width), said(row.desc)))
      end
    end
  end
  if #lines == 0 then
    lines = { ' No review keys are bound.' }
  end
  return lines
end

local overlay = { win = nil, buf = nil, from = nil }

function M.close()
  local back = overlay.from
  if overlay.win and vim.api.nvim_win_is_valid(overlay.win) then
    pcall(vim.api.nvim_win_close, overlay.win, true)
  end
  if overlay.buf and vim.api.nvim_buf_is_valid(overlay.buf) then
    pcall(vim.api.nvim_buf_delete, overlay.buf, { force = true })
  end
  overlay.win, overlay.buf, overlay.from = nil, nil, nil
  -- Back where the reader was -- the comment form, most of the time, which they
  -- are in the middle of writing in.
  if back and vim.api.nvim_win_is_valid(back) then
    pcall(vim.api.nvim_set_current_win, back)
  end
end

function M.is_open()
  return overlay.win ~= nil and vim.api.nvim_win_is_valid(overlay.win)
end

-- Centred and entered, unlike the pickers' own help: it opens over the comment
-- form, which owns `<Esc>`, so the overlay has to hold the cursor for `<Esc>` to
-- mean "close this" rather than "throw the comment away". The `zindex` puts it
-- above the form and above telescope's floats, which sit at 50.
function M.open()
  if M.is_open() then return end
  local lines = M.lines()
  local width = 0
  for _, line in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(line)) end
  width = math.min(width + 1, math.max(20, vim.o.columns - 4))
  local height = math.min(#lines, math.max(3, vim.o.lines - 6))

  overlay.from = vim.api.nvim_get_current_win()
  overlay.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(overlay.buf, 0, -1, false, lines)
  vim.bo[overlay.buf].modifiable = false
  vim.bo[overlay.buf].bufhidden = 'wipe'
  overlay.win = vim.api.nvim_open_win(overlay.buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 2),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = 'minimal',
    border = 'rounded',
    title = ' Review keys ',
    title_pos = 'center',
    footer = ' <Esc> close ',
    footer_pos = 'right',
    zindex = 250,
  })
  vim.wo[overlay.win].cursorline = false
  for _, lhs in ipairs({ '<Esc>', 'q' }) do
    vim.keymap.set('n', lhs, M.close, { buffer = overlay.buf, nowait = true, silent = true })
  end
  -- Clicking or jumping elsewhere leaves nothing behind: the overlay is read,
  -- never worked in.
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = overlay.buf,
    once = true,
    callback = function() vim.schedule(M.close) end,
  })
end

function M.toggle()
  if M.is_open() then M.close() else M.open() end
end

return M
