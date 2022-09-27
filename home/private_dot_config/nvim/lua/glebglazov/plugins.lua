return require('packer').startup(function(use)
  use { 'wbthomason/packer.nvim' }

  use {
    'kylechui/nvim-surround',
    tag = "*",
    config = function()
      require('nvim-surround').setup({ })
    end
  }
  use {
    'terrortylor/nvim-comment',
    config = function()
      require('nvim_comment').setup({ })
    end
  }

  use { 'MunifTanjim/nui.nvim' }
  use { 'nvim-lua/plenary.nvim' }

  use { 'preservim/nerdtree' }

  use { 'tpope/vim-fugitive' }

  use {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.0',
    config = function() require('telescope').setup({ }) end,
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  use { 'w0rp/ale' }
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = 'all',

        highlight = {
          enable = true,
        },
      })
    end
  }

  use { 'gruvbox-community/gruvbox' }

  use {
    'declancm/windex.nvim',
    config = function() require('windex').setup() end
  }
end)
