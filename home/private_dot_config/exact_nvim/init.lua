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
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-nvim-lua'},

      -- Snippets
      {'L3MON4D3/LuaSnip'},
      {'saadparwaiz1/cmp_luasnip'},
      {'rafamadriz/friendly-snippets'},
    },
    branch = 'v3.x'
  },
  {
    'zbirenbaum/copilot.lua', -- credentials are stored in ~/.config/github-copilot/hosts.json
    cmd = 'Copilot',
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    }
  },
  { 'zbirenbaum/copilot-cmp', config = true },

  -------------------------------------------------
  -- Editor improvements
  -------------------------------------------------
  {
    'kylechui/nvim-surround',
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
      { '<LEADER>gpf', ':G push --force-with-lease origin HEAD<CR>' },
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
    branch = 'harpoon2',
    keys = {
      { '<LEADER>a', function() require('harpoon'):list():append() end },
      { '<LEADER>m', function() require('harpoon').ui:toggle_quick_menu(require('harpoon'):list()) end },
      { '<LEADER>1', function() require('harpoon'):list():select(1) end },
      { '<LEADER>2', function() require('harpoon'):list():select(2) end },
      { '<LEADER>3', function() require('harpoon'):list():select(3) end },
      { '<LEADER>4', function() require('harpoon'):list():select(4) end },
      { '<LEADER>5', function() require('harpoon'):list():select(5) end },
    },
    opts = {
      settings = {
        save_on_toggle = true,
      }
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
          -- ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          -- ['<leader>A'] = '@parameter.inner',
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
local lsp_zero = require('lsp-zero')

-- lsp.set_sign_icons({
-- })

-- Disabling semantic highlights for all servers
-- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/lsp.md#disable-semantic-highlights
lsp_zero.set_server_config({
  on_init = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
})

lsp_zero.on_attach(function(_, buffnr)
  lsp_zero.default_keymaps({buffer = buffnr})

  vim.keymap.set('n', 'gr', builtin.lsp_references, { buffer = buffnr, remap = false })
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'ruby_ls',
    'lua_ls',
    'tsserver',
    'gopls',
    'yamlls'
  },
  handlers = {
    lsp_zero.default_setup,
    lua_ls = function()
      require('lspconfig').lua_ls.setup({
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' }
            },
          }
        }
      })
    end,
    yamlls = function()
      require('lspconfig').yamlls.setup({
        settings = {
          yaml = {
            keyOrdering = false,
          }
        }
      })
    end
  }
})

local cmp = require('cmp')
local cmp_action = lsp_zero.cmp_action()

-- this is the function that loads the extra snippets
-- from rafamadriz/friendly-snippets
require('luasnip.loaders.from_vscode').lazy_load()
local luasnip = require('luasnip')

local cmp_has_words_before = function()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

cmp.setup({
  -- if you don't know what is a "source" in nvim-cmp read this:
  -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/autocomplete.md#adding-a-source
  sources = {
    { name = 'path' },
    { name = 'copilot' },
    { name = 'nvim_lsp' },
    { name = 'luasnip', keyword_length = 2 },
    { name = 'buffer', keyword_length = 3 },
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  -- default keybindings for nvim-cmp are here:
  -- https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/README.md#keybindings-1
  mapping = cmp.mapping.preset.insert({
    -- confirm completion item
    ['<CR>'] = cmp.mapping({
      i = function(fallback)
        if cmp.visible() and cmp.get_active_entry() then
          cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
        else
          fallback()
        end
      end,
      s = cmp.mapping.confirm({ select = true }),
      c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
    }),

    -- scroll up and down the documentation window
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),

    -- navigate between snippet placeholders
    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
    ['<C-b>'] = cmp_action.luasnip_jump_backward(),

    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        if #cmp.get_entries() == 1 then
          cmp.confirm({ select = true })
        else
          cmp.select_next_item()
        end
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif cmp_has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  -- note: if you are going to use lsp-kind (another plugin)
  -- replace the line below with the function from lsp-kind
  formatting = lsp_zero.cmp_format(),
})

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
