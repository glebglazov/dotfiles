local nnoremap  = require('glebglazov.functions.remap').nnoremap

require('nvim-tree').setup({
  git = {
    ignore = false
  },
  update_focused_file = {
    enable = true,
    update_root = true,
  },
  renderer = {
    icons = {
      show = {
        git = false,
        folder = false,
        file = false,
        folder_arrow = false,
        modified = false,
      }
    }
  },
  filters = {
    custom = {
      '^\\.git$'
    }
  }
})

nnoremap('<LEADER>fl', '<CMD>NvimTreeOpen<CR>', { silent = true })
nnoremap('<LEADER>ff', '<CMD>NvimTreeFocus<CR>', { silent = true })
nnoremap('<LEADER>fc', '<CMD>NvimTreeClose<CR>', { silent = true })
