local nnoremap  = require('glebglazov.functions.remap').nnoremap
local vnoremap  = require('glebglazov.functions.remap').vnoremap
local xnoremap  = require('glebglazov.functions.remap').xnoremap

-------------------------------------------------
-- General
-------------------------------------------------
nnoremap('<ESC>', ':noh<CR>', { silent = true })
vnoremap('#', 'y/<C-R>"<CR>')
nnoremap('<LEADER><tab>', '<CMD>b#<CR>')

-------------------------------------------------
-- Copy to clipboard
-------------------------------------------------
vnoremap('<LEADER>y', '"+y')
nnoremap('<LEADER>Y', '"+yg_')
nnoremap('<LEADER>y', '"+y')
nnoremap('<LEADER>yy', '"+yy')

-------------------------------------------------
-- Navigation
-------------------------------------------------
nnoremap('H', '^', { silent = true })
vnoremap('H', '^', { silent = true })
nnoremap('L', '$', { silent = true })
vnoremap('L', '$', { silent = true })

nnoremap('J', '<C-D>zz', { silent = true })
vnoremap('J', '<C-D>zz', { silent = true })
nnoremap('K', '<C-U>zz', { silent = true })
vnoremap('K', '<C-U>zz', { silent = true })

nnoremap('n', 'nzzzv')
nnoremap('N', 'Nzzzv')

-------------------------------------------------
-- Paste without messing with register
-------------------------------------------------
xnoremap('<leader>p', "\"_dP")

-------------------------------------------------
-- Restoring merging of lines
-------------------------------------------------
nnoremap('tm', 'J', { silent = true })
vnoremap('tm', 'J', { silent = true })

-------------------------------------------------
-- Window
-------------------------------------------------
nnoremap('<LEADER>w', '<CMD>hide<CR>', { silent = true })
nnoremap('<LEADER>d', '<CMD>vsp <BAR> :wincmd l<CR>', { silent = true })
nnoremap('<LEADER>D', '<CMD>sp <BAR> :wincmd j<CR>', { silent = true })

-------------------------------------------------
-- Files / Projects
-------------------------------------------------
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

vim.cmd([[
  command AC :execute "e " . eval('rails#buffer().alternate()')
]])

nnoremap('<LEADER>fs', '<CMD>up<CR>', { silent = true })
nnoremap('<LEADER>fl', '<CMD>call MyNERDTreeOpenHere()<CR>', { silent = true })
nnoremap('<LEADER>ff', '<CMD>NERDTreeFocus<CR>', { silent = true })
nnoremap('<LEADER>fc', '<CMD>NERDTreeClose<CR>', { silent = true })

nnoremap('<LEADER>pp', ':tcd ~/Dev/')
