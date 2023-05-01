local nnoremap  = require('glebglazov.functions.remap').nnoremap

require('nvim-tree').setup({})

nnoremap('<LEADER>fl', '<CMD>NvimTreeOpen<CR>', { silent = true })
nnoremap('<LEADER>ff', '<CMD>NvimTreeFocus<CR>', { silent = true })
nnoremap('<LEADER>fc', '<CMD>NvimTreeClose<CR>', { silent = true })
