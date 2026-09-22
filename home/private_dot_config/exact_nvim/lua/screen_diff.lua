-- Finds which layer holds a screen leftover, such as a completion menu that
-- stays on the screen after it closed. It compares the screen Neovim composes
-- now with the copy of this pane that tmux holds, and lists the floats that are
-- still open. Each of the three possible faults gives a different result.
local M = {}

local function trim_right(line)
  return (line:gsub('%s+$', ''))
end

-- screenstring() reads the grids through the compositor, so a row contains every
-- float that is open now and nothing that Neovim already closed. The right half
-- of a wide character is an empty string, the same as in tmux's capture.
local function neovim_rows()
  local rows = {}
  for row = 1, vim.o.lines - vim.o.cmdheight do
    local cells = {}
    for col = 1, vim.o.columns do
      cells[col] = vim.fn.screenstring(row, col)
    end
    rows[row] = trim_right(table.concat(cells))
  end
  return rows
end

local function open_floats()
  local floats = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= '' then
      local buf = vim.api.nvim_win_get_buf(win)
      local row = vim.api.nvim_win_get_position(win)[1] + 1
      table.insert(floats, ('  win %d  rows %d-%d  filetype=%s%s'):format(
        win, row, row + vim.api.nvim_win_get_height(win) - 1,
        vim.bo[buf].filetype, config.hide and '  (hidden)' or ''))
    end
  end
  return floats
end

function M.report()
  local pane = vim.env.TMUX_PANE
  if not pane then
    vim.notify('ScreenDiff: Neovim does not run in tmux', vim.log.levels.WARN)
    return
  end

  -- Read both screens before anything is drawn: the report window repaints the
  -- cells under test.
  local tmux_rows = vim.fn.systemlist({ 'tmux', 'capture-pane', '-p', '-t', pane })
  if vim.v.shell_error ~= 0 then
    vim.notify('ScreenDiff: tmux capture-pane failed: ' .. table.concat(tmux_rows, ' '), vim.log.levels.ERROR)
    return
  end
  local rows = neovim_rows()
  local floats = open_floats()

  local diff = {}
  for row, neovim_line in ipairs(rows) do
    local tmux_line = trim_right(tmux_rows[row] or '')
    if neovim_line ~= tmux_line then
      vim.list_extend(diff, {
        ('row %d'):format(row),
        '  neovim │' .. neovim_line,
        '  tmux   │' .. tmux_line,
      })
    end
  end

  local lines = {
    ('ScreenDiff %s, tmux pane %s'):format(os.date('%F %T'), pane),
    '',
    #diff > 0 and 'Result: rows differ (case A)' or 'Result: same text (case B or C)',
    '',
    'How to use',
    '  1. When a leftover shows, press <Space>sd before you do anything else.',
    '     Do not type :ScreenDiff. The noice cmdline float can repaint the leftover.',
    '  2. Find your case:',
    '     A. Rows differ: tmux holds cells that Neovim does not show. Neovim did not',
    '        send the repaint, or tmux lost it. To find which, use :set notermsync',
    '        until the next leftover.',
    '     B. Same text, and the leftover is in an open float: that window did not close.',
    '     C. Same text, and the leftover is in no float: tmux holds the correct cells',
    '        and Ghostty shows old ones. tmux refresh-client clears them.',
    '  3. Do :redraw! to clear the leftover.',
    '  This check compares only text, not colour. A leftover that is only',
    '  background colour on empty cells shows no difference.',
  }
  vim.list_extend(lines, { '', 'Open floats:' })
  vim.list_extend(lines, #floats > 0 and floats or { '  none' })
  if #diff > 0 then
    vim.list_extend(lines, { '', 'Rows that differ:' })
    vim.list_extend(lines, diff)
  end

  vim.cmd.tabnew()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

return M
