require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'ruby',
    'lua',
    'vimdoc',
    'vim',
    'markdown',
    'markdown_inline',
  },

  highlight = {
    enable = true,
  },

  indent = {
    enable = true,
  },

  autotag = {
    enable = true,
  },

  autopairs = {
    enable = true,
  },

  endwise = {
    enable = true,
  },

  playground = {
    enable = true
  }
})
