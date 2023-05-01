return {
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000
  },

  { 'MunifTanjim/nui.nvim' },

  { 'nvim-tree/nvim-tree.lua' },

  { 'tpope/vim-fugitive' },

  { 'tpope/vim-unimpaired' },
  { 'theprimeagen/harpoon' },
  { 'mbbill/undotree' },
  {
    'rgroli/other.nvim',
    init = function()
      require('other-nvim').setup({
        mappings = {
          'rails'
        }
      })
    end
  },

  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    tag = '0.1.1'
  },

  {
    'folke/trouble.nvim',
    init = function ()
      require('trouble').setup({
        icons = false
      })
    end
  },
  {
    'VonHeikemen/lsp-zero.nvim',
    dependencies = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'saadparwaiz1/cmp_luasnip'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-nvim-lua'},

      -- Snippets
      {'L3MON4D3/LuaSnip'},
      {'rafamadriz/friendly-snippets'},
    }
  },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
  { 'nvim-treesitter/playground' },

  {
    'zbirenbaum/copilot.lua',
    cmd = "Copilot",
    event = "VimEnter",
    init = function()
      vim.defer_fn(function()
        require("copilot").setup({
          suggestion = { enabled = false },
          panel = { enabled = false },
        })
      end, 100)
    end,
  },
  {
    'zbirenbaum/copilot-cmp',
    init = function ()
      require("copilot_cmp").setup()
    end
  },

  {
    'kylechui/nvim-surround',
    tag = "*",
    init = function()
      require('nvim-surround').setup({ })
    end
  },
  {
    'numToStr/Comment.nvim',
    init = function()
      require('Comment').setup({ })
    end
  },
  {
    'windwp/nvim-autopairs',
    init = function()
      require('nvim-autopairs').setup({ })
    end
  },
  { 'windwp/nvim-ts-autotag' },
  { 'RRethy/nvim-treesitter-endwise' },
  { 'tpope/vim-rails' },

  {
    'declancm/windex.nvim',
    init = function() require('windex').setup() end
  },
}
