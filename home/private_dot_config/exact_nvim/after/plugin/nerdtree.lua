local nnoremap  = require('glebglazov.functions.remap').nnoremap

vim.cmd([[
let NERDTreeShowHidden=1

function! MyNERDTreeOpenHere()
  if exists("g:NERDTree") && g:NERDTree.IsOpen()
    execute "NERDTreeToggle"
    execute "NERDTreeToggle %"
  else
    execute "NERDTreeToggle %"
  endif
endfunction
]])

nnoremap('<LEADER>fl', '<CMD>call MyNERDTreeOpenHere()<CR>', { silent = true })
nnoremap('<LEADER>ff', '<CMD>NERDTreeFocus<CR>', { silent = true })
nnoremap('<LEADER>fc', '<CMD>NERDTreeClose<CR>', { silent = true })
