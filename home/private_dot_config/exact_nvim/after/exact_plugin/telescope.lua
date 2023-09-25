local actions = require('telescope.actions')
local telescope = require('telescope.builtin')

local tab_mappings = {
  ['<TAB>'] = actions.add_selection + actions.move_selection_next,
  ['<S-TAB>'] = actions.remove_selection + actions.move_selection_previous,
}

require('telescope').setup({
  defaults = {
    mapping = {
      i = tab_mappings,
      n = tab_mappings
    }
  }
})
require('telescope').load_extension('fzf')
require('telescope').load_extension('lazygit')

local get_visual_selection = require('glebglazov.functions.get_visual_selection')
local nnoremap = require('glebglazov.functions.remap').nnoremap
local vnoremap = require('glebglazov.functions.remap').vnoremap

local search_and_replace_mappings_fn = function(_, map)
  map({ 'n', 'i' }, '<CR>', actions.send_to_qflist + actions.open_qflist)

  return true
end

nnoremap('<LEADER>/', telescope.live_grep)
nnoremap('<LEADER>?', telescope.resume)
vnoremap('<LEADER>/',
  function()
    telescope.grep_string({
      search = get_visual_selection()
    })
  end,
  { silent = true }
)

nnoremap('<LEADER>pr',
  function()
    telescope.grep_string({
      attach_mappings = search_and_replace_mappings_fn
    })
  end,
  { silent = true }
)

vnoremap('<LEADER>pr',
  function()
    telescope.grep_string({
      search = get_visual_selection(),
      attach_mappings = search_and_replace_mappings_fn
    })
  end,
  { silent = true }
)

nnoremap('<LEADER>fb', telescope.buffers)
nnoremap('<LEADER>fh', telescope.help_tags)

nnoremap('<LEADER>pf', function()
  telescope.find_files({
    hidden = true,
    file_ignore_patterns = { "^.git/", "^node_modules/" },
  })
end)
