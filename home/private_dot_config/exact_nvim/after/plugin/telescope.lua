require('telescope').setup({ })

local telescope = require('telescope.builtin')

local get_visual_selection = require('glebglazov.functions.get_visual_selection')
local nnoremap  = require('glebglazov.functions.remap').nnoremap
local vnoremap  = require('glebglazov.functions.remap').vnoremap

nnoremap('<LEADER>bb', telescope.buffers)
nnoremap('<LEADER>/', telescope.live_grep)
nnoremap('<LEADER>?', telescope.resume)
vnoremap('<LEADER>/', function() telescope.grep_string({ search = get_visual_selection() }) end, { silent = true })

nnoremap('<LEADER>pf', function()
  telescope.find_files({
    hidden = true,
    file_ignore_patterns = { "^./.git/", "^node_modules/" },
  })
end)
