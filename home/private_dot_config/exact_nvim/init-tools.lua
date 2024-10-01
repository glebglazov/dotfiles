vim.opt.number = true
vim.opt.updatetime = 250
vim.opt.background = 'dark'
vim.opt.iskeyword:remove('_')

-------------------------------------------------
-- Initialise lazy.nvim
-------------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-------------------------------------------------
-- Save and exit
-------------------------------------------------
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set('n', '<LEADER>fs', ':wq<CR>', { silent = true })

-------------------------------------------------
-- Plugins setup
-------------------------------------------------
require('lazy').setup({
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    version = '2.0.0',
    config = function ()
      local gruvbox = require('gruvbox')

      gruvbox.setup({
        overrides = {
          DiffAdd = { fg = "#b8bb26", bg = "NONE" },
          DiffDelete = { fg = "#fb4934", bg = "NONE" },
        },
      })

      vim.cmd([[colorscheme gruvbox]])
    end
  }
})
