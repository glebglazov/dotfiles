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

local function run_in_new_tmux_window_fn(command, opts)
  return function ()
    opts = opts or { with_pause = true }

    local full_command = command
    local postfix = ''
    postfix = postfix .. (opts.with_pause and '; read -n 1' or '')
    local execute = true

    opts.prompt = opts.prompt or false
    if opts.prompt then
      vim.ui.input({ prompt = command }, function(input)
        if input then
          full_command = command .. " " .. input
        else
          execute = false
        end
      end)
    end

    if execute then
      vim.print("Executing: " .. full_command)
      vim.fn.system(string.format('tmux new-window "%s %s"', full_command, postfix))
    end
  end
end

-------------------------------------------------
-- Options
-------------------------------------------------
-- mapleader and maplocalleader here so that all <LEADER> keybindings will work
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw
vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

-- Enable 24-bit colour because why not
vim.opt.termguicolors = true

-- Save undo history to a file
vim.opt.undofile = true
vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir'

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- Highlight search results while typing search pattern
vim.opt.incsearch = true
-- Highlight search results after 'Enter'
vim.opt.hlsearch = true

-- Enable line numbers display
vim.opt.number = true
-- Swap absolute line numbers to relative ones
vim.opt.relativenumber = true

-- Hide buffer when it's abandoned instead of unloading it
vim.opt.hidden = true

-- Ensure that there are at least 8 lines above and below the cursor when scrolling buffer
vim.opt.scrolloff = 8

-- Sets how neovim will display certain whitespace in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Do not highlight horizontal and vertical lines of a cursor by default
vim.opt.cursorline = false
vim.opt.cursorcolumn = false

-- Decrease update time
vim.opt.updatetime = 250

-- For not, dark background only
vim.opt.background = 'dark'

-- Comment these two for now: I remember those causing some issues, but let's try again
-- vim.o.swapfile = false
-- vim.o.backup = false

vim.opt.iskeyword:remove('_')

vim.opt.clipboard = 'unnamed,unnamedplus'

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
  -- UI
  -------------------------------------------------
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      messages = {
        -- TODO: Disabled currently because of the https://github.com/rcarriga/nvim-notify/issues/63
        -- Check periodically to see if it's fixed
        enabled = false,
      },
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = false, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    }
  },
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
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      debug = true, -- Enable debugging
      -- See Configuration section for rest
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
  { 'zbirenbaum/copilot-cmp', config = true },
  { 'tpope/vim-sleuth' }, -- Heuristic tabstop / softtabstop / etc.

  -------------------------------------------------
  -- Coding
  -------------------------------------------------

  {
    'echasnovski/mini.pairs',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'echasnovski/mini.surround',
    opts = {
      mappings = {
        add = 'sa', -- Add surrounding in Normal and Visual modes
        delete = 'sd', -- Delete surrounding
        find = 'sn', -- Find surrounding (to the right)
        find_left = 'sF', -- Find surrounding (to the left)
        highlight = 'sh', -- Highlight surrounding
        replace = 'sr', -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`
      },
    },
  },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
  {
    'echasnovski/mini.comment',
    event = 'VeryLazy',
    opts = {
      options = {
        custom_commentstring = function()
          return require('ts_context_commentstring.internal').calculate_commentstring() or vim.bo.commentstring
        end,
      },
    }
  },
  {
    'echasnovski/mini.ai',
    event = 'VeryLazy',
    opts = function()
      local ai = require('mini.ai')
      return {
        n_lines = 500,
        custom_textobjects = {
          r = ai.gen_spec.treesitter({ a = '@block.outer', i = '@block.inner' }, {}),
          o = ai.gen_spec.treesitter({
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          }, {}),
          f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
          c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }, {}),
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
        },
      }
    end,
  },

  -------------------------------------------------
  -- Editor improvements
  -------------------------------------------------
  { 'stevearc/qf_helper.nvim', config = true }, -- QuickFix window improvements
  {
    'folke/trouble.nvim', -- Better QuickFix window
    opts = {}
  },
  {
    'vim-test/vim-test',
    config = function ()
      vim.g['test#strategy'] = 'neovim'
      vim.g['test#neovim#start_normal'] = '1'
    end,
  },

  -------------------------------------------------
  -- Language plugins
  -------------------------------------------------
  {
    'fatih/vim-go',
    config = function ()
      -- copied from https://raw.githubusercontent.com/fatih/dotfiles/main/init.lua
      vim.g['go_gopls_enabled'] = 0
      vim.g['go_code_completion_enabled'] = 0
      vim.g['go_fmt_autosave'] = 0
      vim.g['go_imports_autosave'] = 0
      vim.g['go_mod_fmt_autosave'] = 0
      vim.g['go_doc_keywordprg_enabled'] = 0
      vim.g['go_def_mapping_enabled'] = 0
      vim.g['go_textobj_enabled'] = 0
      vim.g['go_list_type'] = 'quickfix'
    end,
  },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && yarn install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    ft = { 'markdown' },
  },

  -------------------------------------------------
  -- Git integration
  -------------------------------------------------
  {
    'lewis6991/gitsigns.nvim',
    config = true
  },
  {
    'tpope/vim-fugitive',
    lazy = false,
    keys = {
      { '<LEADER>gg', vim.cmd.G },
      { '<LEADER>gfo', ':G fetch origin<CR>' },
      { '<LEADER>gbl', ':G blame -C -C -C<CR>' },
      { '<LEADER>glg', ':Gclog --oneline<CR>' },
      { '<LEADER>gcp', ':G cherry-pick<SPACE>' },
      { '<LEADER>gbc', ':G branch --sort=-committerdate<CR>' },
      { '<LEADER>gcm', function ()
        local output = vim.fn.system('git branch -l')

        if string.find(output, 'master') then
          vim.cmd('G checkout master')
        else
          vim.cmd('G checkout main')
        end
      end
      },
      { '<LEADER>gw', ':Gwrite' },
      { '<LEADER>gW', ':Gwrite!' },
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
      { '<LEADER>gst', ':G stash<CR>' },
      { '<LEADER>gsa', ':G stash apply<CR>' },
      { '<LEADER>gsb', ':G stash pop<CR>' },
      { '<LEADER>gsu', ':G branch --set-upstream-to=origin/' },
      {
        '<LEADER>gpc',
        function()
          local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")

          if handle then
            local branch = handle:read("*a"):gsub("%s+", "")

            vim.cmd('G push origin HEAD:' .. branch)
          end
        end
      },
      { '<LEADER>gap', ':G commit --amend --no-edit | G push --force origin HEAD<CR>' },
      { '<LEADER>gf', ':G fetch<CR>' }
    },
  },
  {
    'pwntester/octo.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      -- OR 'ibhagwan/fzf-lua',
      'nvim-tree/nvim-web-devicons',
    },
    config = function ()
      require"octo".setup()
    end
  },
  {
    'tpope/vim-rhubarb',
    config = function ()
      vim.keymap.set('n', '<LEADER>gbr', vim.cmd.GBrowse)
      vim.keymap.set('v', '<LEADER>gbr', function()
        vim.cmd([[ execute "normal! \<ESC>" ]])
        vim.cmd("'<'>GBrowse")
      end)
    end
  },

  -------------------------------------------------
  -- Appearance
  -------------------------------------------------
  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    version = '2.0.0',
    config = function ()
      local gruvbox = require('gruvbox')

      gruvbox.setup({
        overrides = {
          DiffAdd = { fg = "#b8bb26", bg = "NONE" },
          DiffDelete = { fg = "#fb4934", bg = "NONE" },
        },
      })

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
      { '<LEADER>a', function() require('harpoon'):list():add() end },
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
    'stevearc/oil.nvim',
    opts = {
      view_options = {
        show_hidden = true,
      }
    },
    keys = {
      { '<LEADER>fl', vim.cmd.Oil }
    },
    dependencies = { { "echasnovski/mini.icons", opts = {} } },  -- use if prefer mini.icons
  },

  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      { 'nvim-telescope/telescope-ui-select.nvim' },
    },
    config = function()
      require('telescope').setup({
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
        pickers = {
          find_files = {
            mappings = {
              i = {
                ['<C-y>'] = function()
                  local entry = require("telescope.actions.state").get_selected_entry()
                  local cb_opts = vim.opt.clipboard:get()
                  if vim.tbl_contains(cb_opts, "unnamed") then vim.fn.setreg("*", entry.path) end
                  if vim.tbl_contains(cb_opts, "unnamedplus") then
                    vim.fn.setreg("+", entry.path)
                  end
                  vim.fn.setreg("", entry.path)
                end,
              }
            }
          }
        }
      })
      require('telescope').load_extension('fzf')
      require('telescope').load_extension('ui-select')
    end,
  },


  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    version = false,
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
    auto_install = true,
    highlight = {
      enable = true,

      disable = function(_, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))

        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,

      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = {
      enable = true,
      disable = { 'ruby' }
    },
    autotag = {
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

vim.keymap.set('n', '<LEADER>cf', function()
  vim.cmd('edit ~/.local/share/chezmoi/home/private_dot_config/exact_nvim/init.lua', { silent = true })
end)

vim.keymap.set('n', '<LEADER>cs', function()
  vim.cmd('!chezmoi apply ~/.config/nvim/init.lua', { silent = true })
  vim.cmd('source ' .. vim.fn.stdpath('config') .. '/init.lua')
end)

vim.keymap.set('n', '<LEADER>bb',builtin.buffers)
vim.keymap.set('n', '<LEADER>/', builtin.live_grep)
vim.keymap.set('n', '<LEADER>?', builtin.resume)
vim.keymap.set('v', '<LEADER>/',
  function()
    require('telescope.builtin').grep_string({
      search = get_visual_selection()
    })
  end
)

vim.keymap.set('n', '<LEADER>fd',
  function()
    require('telescope.builtin').find_files({
      cwd = require('telescope.utils').buffer_dir()
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

local telescope_find_files = function()
  require('telescope.builtin').find_files({
    hidden = true,
    file_ignore_patterns = { "^.git/", "^node_modules/" },
  })
end

vim.keymap.set('n', '<LEADER>fb', require('telescope.builtin').buffers)
vim.keymap.set('n', '<LEADER>fh', require('telescope.builtin').help_tags)
vim.keymap.set('n', '<LEADER>fp', telescope_find_files)

-------------------------------------------------
-- Setup LSP / Autocompletion
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
  vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', {buffer = buffnr})
  vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', {buffer = buffnr})
  vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', {buffer = buffnr})
  vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', {buffer = buffnr})
  vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', {buffer = buffnr})
  vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', {buffer = buffnr})
  vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', {buffer = buffnr})
  vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', {buffer = buffnr})
  vim.keymap.set('n', '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', {buffer = buffnr})
  vim.keymap.set('x', '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', {buffer = buffnr})
  vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', {buffer = buffnr})

  if vim.lsp.buf.range_code_action then
    vim.keymap.set('x', '<F4>', '<cmd>lua vim.lsp.buf.range_code_action()<cr>', {buffer = buffnr})
  else
    vim.keymap.set('x', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', {buffer = buffnr})
  end

  vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', {buffer = buffnr})
  vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>', {buffer = buffnr})
  vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>', {buffer = buffnr})
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'lua_ls',
    'ts_ls',
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
    end,
    gopls = function()
      require('lspconfig').gopls.setup({
        flags = { debounce_text_changes = 200 },
        settings = {
          gopls = {
            usePlaceholders = true,
            gofumpt = true,
            analyses = {
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            codelenses = {
              gc_details = false,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
            experimentalPostfixCompletions = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { "-.git", "-node_modules" },
            semanticTokens = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
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
-- Autogroups - General
-------------------------------------------------
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd({ 'VimResized' }, {
  group = augroup('glebglazov-resize', {clear = true}),
  callback = function()
    vim.cmd('wincmd =')
  end
})

-------------------------------------------------
-- Autogroups — All files
-------------------------------------------------

autocmd({ 'BufWritePre' }, {
  group = augroup('glebglazov-remove-end-of-line-spaces', {clear = true}),
  pattern = '*',
  command = '%s/\\s\\+$//e',
})

autocmd({ 'BufWritePre' }, {
  group = augroup('glebglazov-remove-end-of-file-empty-lines', {clear = true}),
  pattern = '*',
  command = '%s#\\($\\n\\s*\\)\\+\\%$##e',
})

autocmd({ 'VimEnter' }, {
  group = augroup('glebglazov-open-file-browser-at-startup', {clear = true}),
  callback = function()
    local is_headless = false

    local startup_args = vim.v.argv
    for _, arg in ipairs(startup_args) do
      if arg == '--headless' then
        is_headless = true
        break
      end
    end

    if not is_headless then
      telescope_find_files()
    end
  end
})

-------------------------------------------------
-- Autogroups — Fugitive
-------------------------------------------------
autocmd({ 'FileType' }, {
  group = augroup('glebglazov-fugitive-settings', {clear = true}),
  pattern = 'fugitive',
  callback = function ()
    vim.keymap.set('n', '<TAB>', '=', { remap = true, silent = true, buffer = true }) -- TIL: in vim.keymap.set only "remap" option works
    vim.keymap.set('n', 'ce', ':G commit --allow-empty<CR>', { silent = true, buffer = true })
  end
})

-------------------------------------------------
-- Autogroups — Lua
-------------------------------------------------
autocmd({ 'FileType' }, {
  group = augroup('glebglazov-lua-settings', {clear = true}),
  pattern = 'lua',
  callback = function ()
    local execute_lua_snippet_fn = function(opts)
      local content_fn = opts.content_fn

      return function()
        local file_path = vim.fn.tempname()
        local file = io.open(file_path, "w")

        if file then
          local content = content_fn()

          file:write(content)
          file:close()

          vim.cmd(string.format("luafile %s", file_path))
        else
          print("Failed to open file for writing")
        end
      end
    end

    vim.keymap.set('n', '<LEADER>fe',
      execute_lua_snippet_fn({
        content_fn = get_buffer_content
      }),
      { buffer = true }
    )

    vim.keymap.set('v', '<LEADER>fe',
      execute_lua_snippet_fn({
        content_fn = get_visual_selection
      }),
      { buffer = true }
    )
  end
})

-------------------------------------------------
-- Autogroups — Ruby
-------------------------------------------------
autocmd({ 'FileType' }, {
  group = augroup('glebglazov-ruby-settings', {clear = true}),
  pattern = 'ruby',
  callback = function ()
    vim.keymap.set('n', '<LEADER>tl', function() vim.cmd('!rubocop -A %') end, { buffer = true })

    local pairs = require('mini.pairs')
    pairs.map_buf(0, 'i', '|', { action = 'closeopen', pair = '||' })
  end
})

-------------------------------------------------
-- Autogroups — Golang
-------------------------------------------------
autocmd({ 'FileType' }, {
  group = augroup('glebglazov-golang-settings', {clear = true}),
  pattern = 'go',
  callback = function ()
    local full_path = vim.fn.expand("%")
    vim.keymap.set('n', '<LEADER>ef', run_in_new_tmux_window_fn("go run " .. full_path), { buffer = true })
  end
})

-------------------------------------------------
-- Autogroups — Markdown
-------------------------------------------------
autocmd({ 'FileType' }, {
  group = augroup('glebglazov-markdown-settings', {clear = true}),
  pattern = 'markdown',
  callback = function ()
    vim.keymap.set('n', '<LEADER>vf', function() vim.cmd('MarkdownPreview') end, { buffer = true })
  end
})

-- Run gofmt/gofmpt, import packages automatically on save
autocmd({ 'BufWritePre' }, {
  group = augroup('setGoFormatting', {clear = true}),
  pattern = '*.go',
  callback = function()
    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 2000)
    for _, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit, "utf-16")
        else
          vim.lsp.buf.execute_command(r.command)
        end
      end
    end

    vim.lsp.buf.format()
  end
})

-------------------------------------------------
-- Autogroups — QuickFix
-------------------------------------------------
autocmd({ 'FileType' }, {
  group = augroup('glebglazov-quickfix-settings', {clear = true}),
  pattern = 'qf',
  callback = function ()
    vim.api.nvim_buf_set_keymap(0, '', 'dd', ':.Reject<cr>', { silent = true })
  end
})

-------------------------------------------------
-- Keybindings
-------------------------------------------------

-- General
vim.keymap.set('n', '<ESC>', ':noh<CR>', { silent = true })
vim.keymap.set('v', '#', 'y/<C-R>"<CR>', { silent = true })
vim.keymap.set('n', '<LEADER><tab>', ':b#<CR>', { silent = true })

vim.keymap.set({'n', 'v'}, '<LEADER>th', function()
  if vim.opt.cursorline:get() or vim.opt.cursorcolumn:get() then
    vim.opt.cursorline = false
    vim.opt.cursorcolumn = false
  else
    vim.opt.cursorline = true
    vim.opt.cursorcolumn = true
  end
end)

-- cd to current files' directory
vim.keymap.set('n', '<LEADER>cdc', ':cd %:p:h<CR>', { silent = true })

-- on search, center the screen
vim.keymap.set(
  'c', '<CR>',
  function() return vim.fn.getcmdtype() == '/' and '<CR>zzzv' or '<CR>' end,
  { expr = true }
)
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- Copy to clipboard
vim.keymap.set('v', '<LEADER>y', '"+y')
vim.keymap.set('n', '<LEADER>Y', '"+yg_')
vim.keymap.set('n', '<LEADER>y', '"+y')
vim.keymap.set('n', '<LEADER>yy', '"+yy')

local function yank_file_path_fn(opts)
  return function()
    opts = opts or {}
    local path_manipulation_fn = opts.path_manipulation_fn or function(path) return path end

    local path = path_manipulation_fn(vim.fn.expand('%:p'))
    vim.fn.setreg('+', path)
    print("Copied to clipboard: " .. path)
  end
end

vim.keymap.set('n', '<LEADER>fy', yank_file_path_fn({
  path_manipulation_fn = function(path)
    local line_num = vim.api.nvim_win_get_cursor(0)[1]

    return path .. ':' .. line_num
  end
}))
vim.keymap.set('n', '<LEADER>fY', yank_file_path_fn())

-- Navigation
vim.keymap.set('n', '<C-D>', '<C-D>zz')
vim.keymap.set('n', '<C-U>', '<C-U>zz')
vim.keymap.set('v', '<C-D>', '<C-D>zz')
vim.keymap.set('v', '<C-U>', '<C-U>zz')

vim.keymap.set('n', 'H', '^')
vim.keymap.set('n', 'L', '$')
vim.keymap.set('v', 'H', '^')
vim.keymap.set('v', 'L', '$')

-- Paste without messing with register
vim.keymap.set('x', '<leader>p', "\"_dP")

-- Tests
vim.keymap.set('n', '<LEADER>tt', ':TestNearest<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>tf', ':TestFile<CR>', { silent = true })

-- Window
vim.keymap.set('n', '<LEADER>w', ':hide<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>bd', ':bd<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>Bd', ':%bdelete | edit # | normal `', { silent = true })
vim.keymap.set('n', '<LEADER>d', ':vsp | :wincmd l<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>D', ':sp | :wincmd j<CR>', { silent = true })

-- git-pile (EXPERIMENTAL)
vim.keymap.set('n', '<LEADER>gsp', run_in_new_tmux_window_fn('git submitpr', { with_pause = false }))
vim.keymap.set('n', '<LEADER>gso', run_in_new_tmux_window_fn('git submitpr --onto', { prompt = true }))
vim.keymap.set('n', '<LEADER>gup', run_in_new_tmux_window_fn('git updatepr', { prompt = true }))
vim.keymap.set('n', '<LEADER>ghp', run_in_new_tmux_window_fn('git headpr'))
vim.keymap.set('n', '<LEADER>grp', run_in_new_tmux_window_fn('git replacepr', { prompt = true }))
vim.keymap.set('n', '<LEADER>grP', run_in_new_tmux_window_fn('git rebasepr', { prompt = true }))

-- Files / Projects
vim.keymap.set('n', '<LEADER>fs', ':up<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>fS', ':wq<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>pp', ':tcd ~/Dev/')
