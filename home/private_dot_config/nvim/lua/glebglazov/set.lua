vim.g.mapleader = ' '

vim.opt.swapfile = false

vim.opt.expandtab=true
vim.opt.tabstop=2
vim.opt.softtabstop=2
vim.opt.shiftwidth=2

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.hidden = true

vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

vim.o.background = 'dark'
vim.cmd([[colorscheme gruvbox]])

vim.opt.iskeyword:remove('_')
