local nnoremap = require('glebglazov.keymaps').nnoremap
local vnoremap = require('glebglazov.keymaps').vnoremap

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
-- H => ^, L => $
-------------------------------------------------
nnoremap('H', '^', { silent = true })
vnoremap('H', '^', { silent = true })
nnoremap('L', '$', { silent = true })
vnoremap('L', '$', { silent = true })

-------------------------------------------------
-- Half-page down/up to J/K
-------------------------------------------------
nnoremap('J', '<C-D>', { silent = true })
vnoremap('J', '<C-D>', { silent = true })
nnoremap('K', '<C-U>', { silent = true })
vnoremap('K', '<C-U>', { silent = true })

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
local neogit = require('neogit')
nnoremap('<LEADER>gg', function ()
    neogit.open()
end)
nnoremap('<LEADER>ga', '<CMD>!git fetch --all<CR>')
nnoremap('<leader>gfo', ':!git fetch origin<CR>')
nnoremap('<leader>gcp', ':!git cherry-pick<SPACE>')
nnoremap('<leader>grb', ':!git rebase<SPACE>')
nnoremap('<leader>gri', ':!git rebase --interactive<SPACE>')
nnoremap('<leader>gra', ':!git rebase --abort<CR>')
nnoremap('<leader>grc', ':!git rebase --continue<CR>')
nnoremap('<leader>grs', ':!git reset --soft<SPACE>')
nnoremap('<leader>grh', ':!git reset --hard<SPACE>')
nnoremap('<leader>gco', ':!git checkout<SPACE>')
nnoremap('<leader>gcb', ':!git checkout -b<SPACE>')
nnoremap('<leader>gpl', ':!git pull<CR>')
nnoremap('<leader>gpo', ':!git push origin HEAD<CR>')
nnoremap('<leader>gpf', ':!git push --force origin HEAD<CR>')
nnoremap('<leader>gpp', ':!git push origin HEAD:')

-------------------------------------------------
-- Files
-------------------------------------------------
nnoremap('<LEADER>fs', '<CMD>up<CR>', { silent = true })
nnoremap('<LEADER>fl', '<CMD>NvimTreeFocus<CR>')
nnoremap('<LEADER>fc', '<CMD>NvimTreeClose<CR>')
nnoremap('<LEADER>/', "<CMD>lua require('telescope.builtin').live_grep()<CR>", { silent = true })
vnoremap('<LEADER>/', "<CMD>'<,'>lua require('telescope.builtin').grep_string()<CR>")

-------------------------------------------------
-- Project
-------------------------------------------------
nnoremap('<LEADER>pp', ':tcd ~/Dev/')
nnoremap('<LEADER>pf', function()
    require('telescope.builtin').find_files()
end)
