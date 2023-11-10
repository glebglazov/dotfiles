return {
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    -- freeze it here, cause it seems that in new version big rework is ongoing
    -- TODO: retry to upgrade sometime in future
    version = '1.1.0'
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
      -- Config function here is explicit cause Lazy.nvim cannot find that module
      require('other-nvim').setup({
        mappings = {
          'rails'
        }
      })
    end
  },
  {
    'stevearc/qf_helper.nvim',
    config = true
  },

  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' }
  },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },

  {
    'folke/trouble.nvim',
    opts = { icons = false }
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
    event = "InsertEnter",
    config = true
  },
  {
    'zbirenbaum/copilot-cmp',
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
