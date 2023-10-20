vim.g.mapleader = ' ' -- mapleader here so that all <LEADER> keybindings will work

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = require('glebglazov.plugins')
require('lazy').setup(plugins)

require 'glebglazov.set'
require 'glebglazov.augroups'
require 'glebglazov.keybindings'