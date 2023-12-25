-------------------------------------------------
-- Support functions
-------------------------------------------------
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
-- mapleader and maplocalleader here so that all <LEADER> keybindings will work
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

vim.o.swapfile = false
vim.o.backup = false
vim.o.undodir = os.getenv('HOME') .. '/.vim/undodir'
vim.o.undofile = true

vim.o.expandtab=true
vim.o.tabstop=2
vim.o.softtabstop=2
vim.o.shiftwidth=2

vim.o.hlsearch = true
vim.o.incsearch = true

vim.o.number = true
vim.o.relativenumber = true

vim.o.hidden = true

vim.o.scrolloff = 8

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
    'zbirenbaum/copilot.lua', -- credentials are stored in ~/.config/github-copilot/hosts.json
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
    keys = {
      { '<LEADER>gg', vim.cmd.G },
      { '<LEADER>gfo', ':G fetch origin<CR>' },
      { '<LEADER>gbl', ':G blame -C -C -C<CR>' },
      { '<LEADER>glg', ':Gclog --oneline<CR>' },
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
    },
    config = true
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
    build = ':TSUpdate'
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
-- Configure Treesitter
-------------------------------------------------
vim.defer_fn(function() -- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
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
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<M-space>',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
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
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        }
      }
    }
  })
end, 0)

-------------------------------------------------
-- Configure Telescope
-------------------------------------------------
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

local search_and_replace_mappings_fn = function(_, map)
  map({ 'n', 'i' }, '<CR>', actions.send_to_qflist + actions.open_qflist)

  return true
end

vim.keymap.set('n', '<LEADER>/', builtin.live_grep)
vim.keymap.set('n', '<LEADER>?', builtin.resume)
vim.keymap.set('v', '<LEADER>/',
  function()
    require('telescope.builtin').grep_string({
      search = get_visual_selection()
    })
  end
)

vim.keymap.set('n', '<LEADER>fr',
  function()
    require('telescope.builtin').grep_string({
      attach_mappings = search_and_replace_mappings_fn
    })
  end
)

vim.keymap.set('v', '<LEADER>fr',
  function()
    require('telescope.builtin').grep_string({
      search = get_visual_selection(),
      attach_mappings = search_and_replace_mappings_fn
    })
  end
)

vim.keymap.set('n', '<LEADER>fb', require('telescope.builtin').buffers)
vim.keymap.set('n', '<LEADER>fh', require('telescope.builtin').help_tags)
vim.keymap.set('n', '<LEADER>fp',
  function()
    require('telescope.builtin').find_files({
      hidden = true,
      file_ignore_patterns = { "^.git/", "^node_modules/" },
    })
  end
)

-------------------------------------------------
-- Configure LSP / Autocompletion
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

lsp.on_attach(function(_, buffer)
  local opts = { buffer = buffer, remap = false }

  vim.keymap.set('n', 'gr', builtin.lsp_references, opts)
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
local lua_keybindings = augroup('lua_keybindings', {})
autocmd({ 'FileType' }, {
	group = lua_keybindings,
	pattern = 'lua',
	callback = function (event)
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

    vim.keymap.set('n', '<LEADER>fe',
      execute_lua_snippet_fn({
        content_fn = get_buffer_content
      }),
      { buffer = event.buf }
    )

    vim.keymap.set('v', '<LEADER>fe',
      execute_lua_snippet_fn({
        content_fn = get_visual_selection
      }),
      { buffer = event.buf }
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
	callback = function (event)
    vim.keymap.set('n', '<LEADER>tl', function() vim.cmd('!rubocop -A %') end, { buffer = event.buf })
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
vim.keymap.set('n', '<ESC>', ':noh<CR>', { silent = true })
vim.keymap.set('v', '#', 'y/<C-R>"<CR>', { silent = true })
vim.keymap.set('n', '<LEADER><tab>', ':b#<CR>', { silent = true })

-- Copy to clipboard
vim.keymap.set('v', '<LEADER>y', '"+y')
vim.keymap.set('n', '<LEADER>Y', '"+yg_')
vim.keymap.set('n', '<LEADER>y', '"+y')
vim.keymap.set('n', '<LEADER>yy', '"+yy')

-- Navigation
vim.keymap.set('n', '<C-D>', '<C-D>zz', { noremap = true })
vim.keymap.set('n', '<C-U>', '<C-U>zz', { noremap = true })
vim.keymap.set('v', '<C-D>', '<C-D>zz', { noremap = true })
vim.keymap.set('v', '<C-U>', '<C-U>zz', { noremap = true })

vim.keymap.set('n', 'H', '^', { noremap = true })
vim.keymap.set('n', 'L', '$', { noremap = true })
vim.keymap.set('v', 'H', '^', { noremap = true })
vim.keymap.set('v', 'L', '$', { noremap = true })

-- Paste without messing with register
vim.keymap.set('x', '<leader>p', "\"_dP")

-- Window
vim.keymap.set('n', '<LEADER>w', ':hide<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>d', ':vsp | :wincmd l<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>D', ':sp | :wincmd j<CR>', { silent = true })

-- Files / Projects
vim.keymap.set('n', '<LEADER>fs', ':up<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>pp', ':tcd ~/Dev/')
