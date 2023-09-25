return {
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000
  },

  { 'nvim-tree/nvim-tree.lua' },

  { 'tpope/vim-fugitive' },
  {
    'kdheepak/lazygit.nvim',
    -- optional for floating window border decoration
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim'
    },
  },

  { 'tpope/vim-unimpaired' },
  { 'theprimeagen/harpoon' },
  { 'mbbill/undotree' },
  {
    'rgroli/other.nvim',
    config = function()
      require('other-nvim').setup({
        mappings = {
          'rails'
        }
      })
    end
  },
  {
    'stevearc/qf_helper.nvim',
    config = function()
      require('qf_helper').setup()
    end
  },

  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    tag = '0.1.1'
  },
  {'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },

  {
    'folke/trouble.nvim',
    config = function ()
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
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },
  { 'nvim-treesitter/playground' },
  { 'vim-ruby/vim-ruby' },

  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'VimEnter',
    config = function()
      vim.defer_fn(function()
        require('copilot').setup({
          suggestion = { enabled = false },
          panel = { enabled = false },
        })
      end, 100)
    end,
  },
  {
    'zbirenbaum/copilot-cmp',
    branch = 'formatting-fixes', -- TODO: remove when merged into master
    config = true
  },

  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = true
  },
  {
    'numToStr/Comment.nvim',
    config = true
  },
  {
    'windwp/nvim-autopairs',
    config = true
  },
  { 'windwp/nvim-ts-autotag' },
  { 'RRethy/nvim-treesitter-endwise' },

  {
    'declancm/windex.nvim',
    config = true
  },
}
