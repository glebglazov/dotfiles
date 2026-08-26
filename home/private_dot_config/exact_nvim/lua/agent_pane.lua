-- Sending text to a Pop agent pane: pick the pane through the Pop dashboard,
-- then paste the text into it over tmux. Shared by the plain agent message
-- popup and the review send-preview float.
local M = {}

local function message_lines(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  while #lines > 0 and vim.trim(lines[1]) == '' do
    table.remove(lines, 1)
  end
  while #lines > 0 and vim.trim(lines[#lines]) == '' do
    table.remove(lines, #lines)
  end
  return lines
end

-- Run `pop monitor dashboard --pick` in a terminal float; the picked pane id is
-- the last `%<n>` line the dashboard leaves in the buffer.
local function pick_pane(on_pick, on_cancel)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'

  local width = math.min(140, math.floor(vim.o.columns * 0.9))
  local max_height = math.floor(vim.o.lines * 0.9)
  local height = math.max(math.min(30, max_height), math.min(10, max_height))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = 'rounded',
    title = ' Pick agent pane ',
    title_pos = 'center',
    style = 'minimal',
  })

  local job_id = vim.fn.jobstart({ 'pop', 'monitor', 'dashboard', '--pick' }, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        local pane_id = nil
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        for i = #lines, 1, -1 do
          local line = vim.trim(lines[i])
          if line:match('^%%%d+$') then
            pane_id = line
            break
          end
        end

        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end

        if code ~= 0 or not pane_id then
          vim.notify('No agent pane selected', vim.log.levels.WARN)
          if on_cancel then on_cancel() end
          return
        end

        on_pick(pane_id)
      end)
    end,
  })

  if job_id <= 0 then
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.notify('Failed to open Pop dashboard picker', vim.log.levels.ERROR)
    if on_cancel then on_cancel() end
    return
  end

  vim.cmd('startinsert')
end

local function send_to_pane(pane_id, message, press_enter)
  local args = {
    'pop',
    'pane',
    'send',
    '--pane-id',
    pane_id,
    message,
  }
  if press_enter then
    table.insert(args, 'Enter')
  end

  local result = vim.system(args, { text = true }):wait()

  if result.code ~= 0 then
    local stderr = vim.trim(result.stderr or '')
    if stderr ~= '' then
      return stderr
    end
    return 'Failed to send message'
  end

  return nil
end

local function paste_to_pane(pane_id, text, press_enter)
  local load = vim.system({ 'tmux', 'load-buffer', '-' }, { text = true, stdin = text }):wait()
  if load.code ~= 0 then
    local stderr = vim.trim(load.stderr or '')
    if stderr ~= '' then
      return stderr
    end
    return 'Failed to load tmux paste buffer'
  end

  local paste = vim.system({ 'tmux', 'paste-buffer', '-p', '-d', '-t', pane_id }, { text = true }):wait()
  if paste.code ~= 0 then
    local stderr = vim.trim(paste.stderr or '')
    if stderr ~= '' then
      return stderr
    end
    return 'Failed to paste text into pane'
  end

  if press_enter then
    return send_to_pane(pane_id, 'Enter', false)
  end

  return nil
end

-- Scratch markdown float the caller fills with the text to send; returns the
-- buffer, its window and a close function.
function M.text_float(title, width, height)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'
  vim.b[buf].completion = false -- blink.cmp honours this: no autocomplete popup in agent/review send boxes

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = 'rounded',
    title = title,
    title_pos = 'center',
    style = 'minimal',
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set('n', 'q', close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true, silent = true })

  return buf, win, close
end

-- <CR> types the float's text into a picked pane, <S-CR> types and submits it.
function M.map_text_send(buf, close, empty_message, success_message)
  local pending = false
  local function submit(press_enter)
    if pending then
      return
    end

    local lines = message_lines(buf)
    if #lines == 0 then
      vim.notify(empty_message, vim.log.levels.WARN)
      return
    end
    local text = table.concat(lines, '\n')
    if text == '' then
      vim.notify(empty_message, vim.log.levels.WARN)
      return
    end

    -- On a type (no Enter) leave the cursor on a fresh line so a follow-up
    -- type lands below instead of being glued onto this one.
    local paste_text = press_enter and text or (text .. '\n')

    pending = true
    pick_pane(function(pane_id)
      pending = false
      local send_err = paste_to_pane(pane_id, paste_text, press_enter)
      if send_err then
        vim.notify(send_err, vim.log.levels.ERROR)
        return
      end

      close()
      vim.notify(success_message:format(pane_id), vim.log.levels.INFO)
    end, function()
      pending = false
    end)
  end

  vim.keymap.set('n', '<CR>', function() submit(false) end, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set('n', '<S-CR>', function() submit(true) end, { buffer = buf, nowait = true, silent = true })
end

function M.message_popup()
  local width = math.min(100, math.floor(vim.o.columns * 0.8))
  local max_height = math.floor(vim.o.lines * 0.5)
  local height = math.max(math.min(10, max_height), 3)
  local buf, _, close = M.text_float(' Agent message  (Enter type · Shift+Enter send · q close) ', width, height)

  M.map_text_send(buf, close, 'No agent message to send', 'Sent message to %s')

  vim.cmd('startinsert')
end

return M
