local nnoremap  = require('glebglazov.functions.remap').nnoremap

nnoremap('<LEADER>ll', function() vim.cmd('!rubocop -A %') end)
