-- Where an arrival sits on the screen. Every jump the review makes -- the hunk
-- walk, the file stride, first/last, the comment jump, the return from a file
-- read, the export jump -- ends here, so the reader always meets the line they
-- were sent to at the same height, with the rest of the hunk below it rather
-- than under the window's bottom edge.
local M = {}

-- How far down the window an arrival lands, as a share of the window's height.
-- `review.setup{ landing_fraction = ... }` overrides it.
M.fraction = 0.25

-- The window row an arrival aims for. Rows are 1-based and the last row is as
-- far down as a cursor can be, so the share is clamped into that span -- and
-- then into the span 'scrolloff' leaves free, because a row nearer an edge than
-- that is one the editor answers by dragging the cursor off the line the jump
-- was about.
local function target_row(height)
  local fraction = M.fraction
  if type(fraction) ~= 'number' or fraction < 0 or fraction > 1 then fraction = 0.25 end
  local row = math.max(1, math.min(height, math.floor(height * fraction)))
  local margin = math.min(vim.o.scrolloff, math.floor((height - 1) / 2))
  return math.max(margin + 1, math.min(height - margin, row))
end

-- Scroll the view until the cursor sits on `row`, without moving the cursor off
-- the line it was sent to. `winline()` is the true screen row -- it counts the
-- virtual lines a hunk's deletions and inline comments draw above it, which
-- topline arithmetic in buffer lines cannot see -- so the walk re-measures after
-- every step and stops when the view will not move any further: at the top of a
-- file there is nothing left to scroll up into, and that is as close as the
-- arrival can get.
local function scroll_to(row, height)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local want
  for _ = 1, height do
    local at = vim.fn.winline()
    if at == row then return end
    local up = at < row
    -- One step past the mark is as good as the mark: a virtual line is worth
    -- several screen rows to scroll over, so insisting on the exact row would
    -- step back and forth over it for ever.
    if want ~= nil and want ~= up then return end
    want = up
    -- CTRL-Y pulls the view up, which pushes the cursor's row down; CTRL-E the
    -- other way.
    vim.cmd(up and 'normal! \25' or 'normal! \5')
    -- The view would not move, or moved the cursor with it. Either way the
    -- arrival is as close to the mark as it can get while still being the line
    -- the reader was sent to, which matters more than the height.
    if vim.fn.winline() == at then return end
    if vim.api.nvim_win_get_cursor(0)[1] ~= cursor[1] then
      pcall(vim.api.nvim_win_set_cursor, 0, cursor)
      return
    end
  end
end

-- Put the cursor's line about `fraction` down the window. `zt` first so a hunk
-- reached from below is pulled off the bottom edge in one move, and so the
-- scroll that follows always has room above it to work with.
function M.land()
  local win = vim.api.nvim_get_current_win()
  local height = vim.api.nvim_win_get_height(win)
  if height <= 0 then return end
  local row = target_row(height)
  vim.cmd('normal! zt')
  scroll_to(row, height)

  -- A hunk's removed lines are drawn when the buffer is shown, which for a file
  -- this jump has just opened can be after this call returns. The second pass
  -- lands against what is finally on the screen -- unless the reader has already
  -- moved, in which case their position is theirs.
  local cursor = vim.api.nvim_win_get_cursor(win)
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_get_current_win() ~= win then return end
    local now = vim.api.nvim_win_get_cursor(win)
    if now[1] ~= cursor[1] then return end
    local h = vim.api.nvim_win_get_height(win)
    scroll_to(target_row(h), h)
  end)
end

return M
