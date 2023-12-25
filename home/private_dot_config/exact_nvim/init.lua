-------------------------------------------------
-- Support functions
-------------------------------------------------
local function bind(op, outer_opts)
    outer_opts = outer_opts or {noremap = true}
    return function(lhs, rhs, opts)
        opts = vim.tbl_extend("force",
            outer_opts,
            opts or {}
        )
        vim.keymap.set(op, lhs, rhs, opts)
    end
end

local nnoremap = bind('n')
local vnoremap = bind('v')
local xnoremap = bind('x')

local function get_buffer_content()
  return table.concat(
    vim.api.nvim_buf_get_lines(0, 0, -1, false),
    "\n"
  )
end

local function get_visual_selection()
  -- Yank current visual selection into the 'v' register
  --
  -- Note that this makes no effort to preserve this register
  vim.cmd('noau normal! "vy"')

  return vim.fn.getreg('v')
end

-------------------------------------------------
-- Options
-------------------------------------------------
vim.g.mapleader = ' ' -- mapleader here so that all <LEADER> keybindings will work

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.opt.undofile = true

vim.opt.expandtab=true
vim.opt.tabstop=2
vim.opt.softtabstop=2
vim.opt.shiftwidth=2

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.hidden = true

vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.scrolloff = 8

vim.o.background = 'dark'

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
-- Plugins setup
-------------------------------------------------
require('lazy').setup({
  -------------------------------------------------
  -- LSP / Autocompletion
  -------------------------------------------------
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
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = "InsertEnter",
    config = true
  },
  { 'zbirenbaum/copilot-cmp', config = true },

  -------------------------------------------------
  -- Editor improvements
  -------------------------------------------------
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = true
  },
  { 'numToStr/Comment.nvim', config = true },
  { 'stevearc/qf_helper.nvim', config = true }, -- QuickFix window improvements
  {
    'folke/trouble.nvim', -- Better QuickFix window
    opts = { icons = false }
  },

  -------------------------------------------------
  -- Git integration
  -------------------------------------------------
  { 'lewis6991/gitsigns.nvim', config = true },
  {
    'tpope/vim-fugitive',
    lazy = false,
    keys = {
      { '<LEADER>gg', vim.cmd.G },
      { '<LEADER>gfo', ':G fetch origin<CR>' },
      { '<LEADER>gbl', ':G blame -C -C -C<CR>' },
      { '<LEADER>glg', ':Gclog<CR>' },
      { '<LEADER>gcp', ':G cherry-pick<SPACE>' },
      { '<LEADER>gbr', ':G branch --sort=-committerdate<CR>' },
      { '<LEADER>gcm', function ()
        local output = vim.fn.system('git branch -l')

        if string.find(output, 'master') then
          vim.cmd('G checkout master')
        else
          vim.cmd('G checkout main')
        end
      end
      },
      { '<LEADER>grb', ':G rebase<SPACE>' },
      { '<LEADER>gri', ':G rebase --interactive<SPACE>' },
      { '<LEADER>gra', ':G rebase --abort<CR>' },
      { '<LEADER>grc', ':G rebase --continue<CR>' },
      { '<LEADER>grs', ':G reset --soft<SPACE>' },
      { '<LEADER>grh', ':G reset --hard<SPACE>' },
      { '<LEADER>grv', ':G revert<SPACE>' },
      { '<LEADER>gco', ':G checkout<SPACE>' },
      { '<LEADER>gcb', ':G checkout -b<SPACE>' },
      { '<LEADER>gce', ':G commit --allow-empty -m \'\'<LEFT>' },
      { '<LEADER>gpl', ':G pull --rebase<CR>' },
      { '<LEADER>gpo', ':G push<CR>' },
      { '<LEADER>gpf', ':G push --force origin HEAD<CR>' },
      { '<LEADER>gpp', ':G push origin HEAD:' },
      { '<LEADER>gap', ':G commit --amend --no-edit | G push --force origin HEAD<CR>' },
      { '<LEADER>gf', ':G fetch<CR>' }
    }
  },
  {
    'kdheepak/lazygit.nvim',
    -- optional for floating window border decoration
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim'
    },
  },

  -------------------------------------------------
  -- Appearance
  -------------------------------------------------
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    -- freeze it here, cause it seems that in new version big rework is ongoing
    -- TODO: retry to upgrade sometime in future
    version = '1.1.0',
    config = function ()
      vim.cmd([[colorscheme gruvbox]])
    end
  },

  -------------------------------------------------
  -- Navigation
  -------------------------------------------------
  {
    'theprimeagen/harpoon',
    keys = {
      { '<LEADER>a', function() require('harpoon.mark').add_file() end },
      { '<LEADER>m', function() require('harpoon.ui').toggle_quick_menu() end },
      { '<LEADER>1', function() require('harpoon.ui').nav_file(1) end },
      { '<LEADER>2', function() require('harpoon.ui').nav_file(2) end },
      { '<LEADER>3', function() require('harpoon.ui').nav_file(3) end },
      { '<LEADER>4', function() require('harpoon.ui').nav_file(4) end },
      { '<LEADER>5', function() require('harpoon.ui').nav_file(5) end },
    }
  },
  { 'declancm/windex.nvim', config = true },
  { 'tpope/vim-unimpaired' },
  -- Open alternative files for the current buffer.
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

  -- Files manager
  {
    'nvim-tree/nvim-tree.lua',
    keys = {
      { '<LEADER>fl', ':NvimTreeOpen<CR>' },
      { '<LEADER>ff', ':NvimTreeFocus<CR>' },
      { '<LEADER>fc', ':NvimTreeClose<CR>' },
    },
    config = function ()
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
        }}
      )
    end
  },

  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('telescope').setup({
      })
      require('telescope').load_extension('fzf')
      require('telescope').load_extension('lazygit')
    end,
  },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function ()
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

        textobjects = {
          select = {
            enable = true,

            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,

            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              -- You can optionally set descriptions to the mappings (used in the desc parameter of
              -- nvim_buf_set_keymap) which plugins like which-key display
              ['ic'] = { query = '@class.inner', desc = 'Select inner part of a class region' },
              -- You can also use captures from other query groups like `locals.scm`
              ['as'] = { query = '@scope', query_group = 'locals', desc = 'Select language scope' },
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            selection_modes = {
              ['@parameter.outer'] = 'v', -- charwise
              ['@function.outer'] = 'V', -- linewise
              ['@class.outer'] = '<c-v>', -- blockwise
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true of false
            include_surrounding_whitespace = true,
          },

          swap = {
            enable = true,
            swap_next = {
              ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>A'] = '@parameter.inner',
            },
          },

          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']m'] = '@function.outer',
              [']]'] = { query = '@class.outer', desc = 'Next class start' },
              --
              -- You can use regex matching (i.e. lua pattern) and/or pass a list in a 'query' key to group multiple queires.
              [']o'] = '@loop.*',
              -- [']o'] = { query = { '@loop.inner', '@loop.outer' } }
              --
              -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
              -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
              [']s'] = { query = '@scope', query_group = 'locals', desc = 'Next scope' },
              [']z'] = { query = '@fold', query_group = 'folds', desc = 'Next fold' },
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
            },
            goto_previous_start = {
              ['[m'] = '@function.outer',
              ['[['] = '@class.outer',
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[]'] = '@class.outer',
            },
            -- Below will go to either the start or the end, whichever is closer.
            -- Use if you want more granular movements
            -- Make it even more gradual by adding multiple queries and regex.
            goto_next = {
              [']d'] = '@conditional.outer',
            },
            goto_previous = {
              ['[d'] = '@conditional.outer',
            }
          },
        },
      })
    end
  },
  { 'nvim-treesitter/nvim-treesitter-textobjects' },
  { 'nvim-treesitter/playground' },
  { 'RRethy/nvim-treesitter-endwise' },
  { 'windwp/nvim-ts-autotag' },

  -- Undotree
  {
    'mbbill/undotree',
    keys = {
      { '<LEADER>u', vim.cmd.UndotreeToggle }
    }
  }
})

-------------------------------------------------
-- telescope setup
-------------------------------------------------
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

local search_and_replace_mappings_fn = function(_, map)
  map({ 'n', 'i' }, '<CR>', actions.send_to_qflist + actions.open_qflist)

  return true
end

nnoremap('<LEADER>/', builtin.live_grep)
nnoremap('<LEADER>?', builtin.resume)
vnoremap(
  '<LEADER>/',
  function()
    require('telescope.builtin').grep_string({
      search = get_visual_selection()
    })
  end
)

nnoremap(
  '<LEADER>fr',
  function()
    require('telescope.builtin').grep_string({
      attach_mappings = search_and_replace_mappings_fn
    })
  end
)

vnoremap('<LEADER>fr',
  function()
    require('telescope.builtin').grep_string({
      search = get_visual_selection(),
      attach_mappings = search_and_replace_mappings_fn
    })
  end
)

nnoremap('<LEADER>fb', require('telescope.builtin').buffers)
nnoremap('<LEADER>fh', require('telescope.builtin').help_tags)
nnoremap(
  '<LEADER>fp',
  function()
    require('telescope.builtin').find_files({
      hidden = true,
      file_ignore_patterns = { "^.git/", "^node_modules/" },
    })
  end
)

-------------------------------------------------
-- LSP / Autocompletion
-------------------------------------------------
local lsp = require('lsp-zero')
local cmp = require('cmp')
local configure = require('lspconfig')

local cmp_sources = lsp.defaults.cmp_sources()
table.insert(cmp_sources, { name = 'copilot' })

lsp.preset('recommended')
lsp.set_preferences({
  sign_icons = {}
})

lsp.setup_nvim_cmp({
  sources = cmp_sources,
  mapping = lsp.defaults.cmp_mappings({
    ['<CR>'] = cmp.mapping.confirm({ select = false })
  })
})

-- Disabling semantic highlights for all servers
-- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/lsp.md#disable-semantic-highlights
lsp.set_server_config({
  on_init = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
})

configure.yamlls.setup({
  settings = {
    yaml = {
      keyOrdering = false,
    }
  }
})

-- textDocument/diagnostic support until Neovim 0.10.0 is released
local _timers = {}
local function setup_diagnostics(client, buffer)
  if require("vim.lsp.diagnostic")._enable then
    return
  end

  local diagnostic_handler = function()
    local params = vim.lsp.util.make_text_document_params(buffer)
    client.request("textDocument/diagnostic", { textDocument = params }, function(err, result)
      if err then
        local err_msg = string.format("diagnostics error - %s", vim.inspect(err))
        vim.lsp.log.error(err_msg)
      end
      local diagnostic_items = {}
      if result then
        diagnostic_items = result.items
      end
      vim.lsp.diagnostic.on_publish_diagnostics(
        nil,
        vim.tbl_extend("keep", params, { diagnostics = diagnostic_items }),
        { client_id = client.id }
      )
    end)
  end

  diagnostic_handler() -- to request diagnostics on buffer when first attaching

  vim.api.nvim_buf_attach(buffer, false, {
    on_lines = function()
      if _timers[buffer] then
        vim.fn.timer_stop(_timers[buffer])
      end
      _timers[buffer] = vim.fn.timer_start(200, diagnostic_handler)
    end,
    on_detach = function()
      if _timers[buffer] then
        vim.fn.timer_stop(_timers[buffer])
      end
    end,
  })
end

configure.ruby_ls.setup({
  on_attach = function(client, buffer)
    setup_diagnostics(client, buffer)
  end
})

configure.lua_ls.setup({
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      },
    }
  }
})

lsp.on_attach(function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }

  nnoremap('gr', builtin.lsp_references, opts)
end)

lsp.setup()

-------------------------------------------------
-- Autogroups — All files
-------------------------------------------------
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local remove_end_of_line_spaces = augroup('remove_end_of_line_spaces', { })
autocmd({ 'BufWritePre' }, {
	group = remove_end_of_line_spaces,
	pattern = '*',
	command = '%s/\\s\\+$//e',
})

local remove_end_of_file_empty_lines = augroup('remove_end_of_file_empty_lines', { })
autocmd({ 'BufWritePre' }, {
	group = remove_end_of_file_empty_lines,
	pattern = '*',
	command = '%s#\\($\\n\\s*\\)\\+\\%$##e',
})

local open_nvim_tree_at_startup = augroup('open_nvim_tree_at_startup', { })
autocmd({ 'VimEnter' }, {
  group = open_nvim_tree_at_startup,
  callback = require('nvim-tree.api').tree.open
})

-------------------------------------------------
-- Autogroups — Fugitive
-------------------------------------------------
local fugitive_remap_equals_to_tab = augroup('fugitive_remap_equals_to_tab', {})
autocmd({ 'FileType' }, {
	group = fugitive_remap_equals_to_tab,
	pattern = 'fugitive',
	command = 'nmap <buffer> <tab> =',
})

-------------------------------------------------
-- Autogroups — Lua
-------------------------------------------------
local lua_base_script = [[
lua <<EOF
  %s
EOF
]]

local execute_lua_snippet_fn = function(opts)
  local content_fn = opts.content_fn

  return function()
    local content = content_fn()
    local command = string.format(lua_base_script, content)

    vim.cmd(command)
  end
end

local lua_keybindings = augroup('lua_keybindings', {})
autocmd({ 'FileType' }, {
	group = lua_keybindings,
	pattern = 'lua',
	callback = function ()
    nnoremap(
      '<LEADER>fe',
      execute_lua_snippet_fn({
        content_fn = get_buffer_content
      })
    )

    vnoremap(
      '<LEADER>fe',
      execute_lua_snippet_fn({
        content_fn = get_visual_selection
      })
    )
	end
})

-------------------------------------------------
-- Autogroups — Ruby
-------------------------------------------------

local ruby_keybindings = augroup('ruby_keybindings', {})
autocmd({ 'FileType' }, {
	group = ruby_keybindings,
	pattern = 'ruby',
	callback = function ()
    nnoremap('<LEADER>ll', function() vim.cmd('!rubocop -A %') end)
	end
})

-------------------------------------------------
-- Autogroups — QuickFix
-------------------------------------------------

local qf_keybindings = augroup('qf_keybindings', {})
autocmd({ 'FileType' }, {
	group = qf_keybindings,
	pattern = 'qf',
	callback = function ()
    vim.api.nvim_buf_set_keymap(0, '', 'dd', ':.Reject<cr>', { noremap = true, silent = true })
	end
})

-------------------------------------------------
-- Autogroups — Sh
-------------------------------------------------

local sh_keybindings = augroup('sh_keybindings', {})
autocmd({ 'FileType' }, {
	group = sh_keybindings,
	pattern = 'sh',
	callback = function ()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end
})

-------------------------------------------------
-- Keybindings
-------------------------------------------------

-- General
nnoremap('<ESC>', ':noh<CR>', { silent = true })
vnoremap('#', 'y/<C-R>"<CR>', { silent = true })
nnoremap('<LEADER><tab>', ':b#<CR>', { silent = true })

-- Copy to clipboard
vnoremap('<LEADER>y', '"+y')
nnoremap('<LEADER>Y', '"+yg_')
nnoremap('<LEADER>y', '"+y')
nnoremap('<LEADER>yy', '"+yy')

-- Navigation
nnoremap('<C-D>', '<C-D>zz')
nnoremap('<C-U>', '<C-U>zz')
vnoremap('<C-D>', '<C-D>zz')
vnoremap('<C-U>', '<C-U>zz')

nnoremap('H', '^')
nnoremap('L', '$')
vnoremap('H', '^')
vnoremap('L', '$')

-- Paste without messing with register
xnoremap('<leader>p', "\"_dP")

-- Window
nnoremap('<LEADER>w', ':hide<CR>', { silent = true })
nnoremap('<LEADER>d', ':vsp <BAR> :wincmd l<CR>', { silent = true })
nnoremap('<LEADER>D', ':sp <BAR> :wincmd j<CR>', { silent = true })

-- Files / Projects
nnoremap('<LEADER>fs', ':up<CR>', { silent = true })
nnoremap('<LEADER>pp', ':tcd ~/Dev/')
