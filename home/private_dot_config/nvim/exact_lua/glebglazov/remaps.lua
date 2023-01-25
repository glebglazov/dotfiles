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
nnoremap('<LEADER>ws', '<CMD>sp<CR>', { silent = true })
nnoremap('<LEADER>wd', '<CMD>hide<CR>', { silent = true })
nnoremap('<LEADER>wS', '<CMD>sp <BAR> :wincmd j<CR>', { silent = true })
nnoremap('<LEADER>wv', '<CMD>vsp<CR>', { silent = true })
nnoremap('<LEADER>wV', '<CMD>vsp <BAR> :wincmd l<CR>', { silent = true })
nnoremap('<LEADER>wh', '<CMD>wincmd h<CR>', { silent = true })
nnoremap('<LEADER>wj', '<CMD>wincmd j<CR>', { silent = true })
nnoremap('<LEADER>wk', '<CMD>wincmd k<CR>', { silent = true })
nnoremap('<LEADER>wl', '<CMD>wincmd l<CR>', { silent = true })

-------------------------------------------------
-- Git
-------------------------------------------------
nnoremap('<LEADER>gg', function ()
  vim.cmd('G')
end)
nnoremap('<LEADER>gfo', ':G fetch origin<CR>')
nnoremap('<LEADER>gbl', ':G blame<CR>')
nnoremap('<LEADER>glg', ':Gclog<CR>')
nnoremap('<LEADER>gcp', ':G cherry-pick<SPACE>')
nnoremap('<LEADER>gcm', function ()
  local output = vim.fn.system('git branch -l')

  if string.find(output, 'master') then
    vim.cmd('G checkout master')
  else
    vim.cmd('G checkout main')
  end
end)
nnoremap('<LEADER>grb', ':G rebase<SPACE>')
nnoremap('<LEADER>gri', ':G rebase --interactive<SPACE>')
nnoremap('<LEADER>gra', ':G rebase --abort<CR>')
nnoremap('<LEADER>grc', ':G rebase --continue<CR>')
nnoremap('<LEADER>grs', ':G reset --soft<SPACE>')
nnoremap('<LEADER>grh', ':G reset --hard<SPACE>')
nnoremap('<LEADER>grv', ':G revert<SPACE>')
nnoremap('<LEADER>gco', ':G checkout<SPACE>')
nnoremap('<LEADER>gcb', ':G checkout -b<SPACE>')
nnoremap('<LEADER>gpl', ':G pull<CR>')
nnoremap('<LEADER>gpr', ':G pull --rebase<CR>')
nnoremap('<LEADER>gpo', ':G push origin HEAD<CR>')
nnoremap('<LEADER>gpf', ':G push --force origin HEAD<CR>')
nnoremap('<LEADER>gpp', ':G push origin HEAD:')
nnoremap('<LEADER>gap', ':G commit --amend --no-edit | G push --force origin HEAD<CR>')

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
