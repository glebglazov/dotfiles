local nnoremap = require('glebglazov.functions.remap').nnoremap
local vnoremap = require('glebglazov.functions.remap').vnoremap
local get_visual_selection = require('glebglazov.functions.get_visual_selection')
local get_buffer_content = require('glebglazov.functions.get_buffer_content')

local lua_base_script = [[
lua <<EOF
  %s
EOF
]]

local execute_lua_snippet_fn = function(opts)
  local content_fn = opts.content_fn

  return function()
    local content = content_fn()
    local command = string.format(lua_base_script, content)

    vim.cmd(command)
  end
end

nnoremap(
  '<LEADER>fe',
  execute_lua_snippet_fn({
    content_fn = get_buffer_content
  })
)

vnoremap(
  '<LEADER>fe',
  execute_lua_snippet_fn({
    content_fn = get_visual_selection
  })
)
