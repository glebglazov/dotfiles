require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'ruby',
    'terraform',
    'hcl',
    'lua',
    'vimdoc',
    'vim',
    'markdown',
    'markdown_inline',
    'clojure',
    'javascript',
  },

  highlight = {
    enable = true,

    disable = function(_, buf)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))

      if ok and stats and stats.size > max_filesize then
        return true
      end
    end,

    additional_vim_regex_highlighting = false,
  },

  indent = {
    enable = true,

    disable = { 'ruby' }
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
  },
})
