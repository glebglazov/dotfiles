local mark = require('harpoon.mark')
local ui = require('harpoon.ui')

local nnoremap  = require('glebglazov.functions.remap').nnoremap

nnoremap('<LEADER>a', mark.add_file)
nnoremap('<LEADER>m', ui.toggle_quick_menu)

nnoremap('<LEADER>1', function() ui.nav_file(1) end)
nnoremap('<LEADER>2', function() ui.nav_file(2) end)
nnoremap('<LEADER>3', function() ui.nav_file(3) end)
nnoremap('<LEADER>4', function() ui.nav_file(4) end)
nnoremap('<LEADER>5', function() ui.nav_file(5) end)
