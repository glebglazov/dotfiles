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
nnoremap('<C-D>', '<C-D>zz', { silent = true })
vnoremap('<C-D>', '<C-D>zz', { silent = true })
nnoremap('<C-U>', '<C-U>zz', { silent = true })
vnoremap('<C-U>', '<C-U>zz', { silent = true })

nnoremap('H', '^')
nnoremap('L', '$')

nnoremap('j', 'jzz')
vnoremap('j', 'jzz')
nnoremap('k', 'kzz')
vnoremap('k', 'kzz')

nnoremap('n', 'nzzzv')
nnoremap('N', 'Nzzzv')

-------------------------------------------------
-- Paste without messing with register
-------------------------------------------------
xnoremap('<leader>p', "\"_dP")

-------------------------------------------------
-- Window
-------------------------------------------------
nnoremap('<LEADER>w', '<CMD>hide<CR>', { silent = true })
nnoremap('<LEADER>d', '<CMD>vsp <BAR> :wincmd l<CR>', { silent = true })
nnoremap('<LEADER>D', '<CMD>sp <BAR> :wincmd j<CR>', { silent = true })

-------------------------------------------------
-- Files / Projects
-------------------------------------------------

nnoremap('<LEADER>fs', '<CMD>up<CR>', { silent = true })
nnoremap('<LEADER>pp', ':tcd ~/Dev/')
