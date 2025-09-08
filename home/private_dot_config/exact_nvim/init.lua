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

local function run_in_tmux_fn(command, opts)
  return function ()
    local tmux_cmd = opts.tmux_cmd or "new-window"
    local with_pause = opts.with_pause or true

    local full_command = type(command) == "function" and command() or command

    local postfix = with_pause and '; read -n 1' or ''
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
      full_command = string.format("tmux %s \"$SHELL -i -c '%s %s'\"", tmux_cmd, full_command, postfix)
      vim.print("Executing: " .. full_command)
      vim.fn.system(full_command)
    end
  end
end

local function run_or_prompt_fn(main_command, opts)
  opts = opts or {}
  local is_shell_command = opts.is_shell_command or false
  local is_quick_execute = opts.quick_execute or false
  local move_result_to_new_tab = opts.move_result_to_new_tab or false
  local postfix = opts.postfix or ""

  local base_command =
    (is_shell_command and "!:" or ":") ..
    main_command ..
    " "

  return function()
    if (is_quick_execute) then
      local word_under_cursor = vim.fn.expand("<cWORD>")

      vim.api.nvim_feedkeys(base_command .. word_under_cursor .. postfix .. "\n", "n", false)
    else
      vim.api.nvim_feedkeys(base_command .. postfix, "n", false)
    end

    if move_result_to_new_tab then
      vim.defer_fn(function()
        vim.cmd('tab split | tabprev | quit | tabnext')
      end, 20)
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

vim.opt.signcolumn = "yes"
vim.diagnostic.config({
  update_in_insert = true,
})

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
      popupmenu = {
        enabled = false,
      },
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- requires blink.cmp
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
  {
    "rcarriga/nvim-notify",
    opts = {
      background_colour = "#FFF0AA"
    },
  },
  -------------------------------------------------
  -- LSP / Autocompletion
  -------------------------------------------------
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim', version = '1.32.0'},
    },
  },
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
      'saghen/blink.compat',
      {
        'zbirenbaum/copilot.lua', -- credentials are stored in ~/.config/github-copilot/hosts.json
        cmd = 'Copilot',
        event = "InsertEnter",
        opts = {
          suggestion = { enabled = false },
          panel = { enabled = false },
        }
      },
      {'zbirenbaum/copilot-cmp', config = true},
    },
    version = '*',
  },

  { 'tpope/vim-sleuth' }, -- Heuristic tabstop / softtabstop / etc.

  -------------------------------------------------
  -- Coding
  -------------------------------------------------

  {
    'echasnovski/mini.pairs',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'echasnovski/mini.surround',
    opts = {
      mappings = {
        add = 'cv', -- Add surrounding in Normal and Visual modes
        delete = 'cd', -- Delete surrounding
        replace = 'cs', -- Replace surrounding
      },
    },
  },
  {
    'folke/flash.nvim',
    event = "VeryLazy",
    opts = {
      modes = {
        char = {
          enabled = false
        },
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end },
      { "r", mode = "o", function() require("flash").remote() end },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end },
    },
  },
  {
    'Wansmer/treesj',
    lazy = true,
    keys = { 'gS' },
    config = function()
      local treesj = require('treesj')
      local lang_utils = require('treesj.langs.utils')
      treesj.setup({
        dot_repeat = true,
        use_default_keymaps = false,
        langs = {
          ruby = {
            array = lang_utils.set_preset_for_list({
              join = {
                space_in_brackets = false,
              }
            })
          }
        }
      })

      vim.keymap.set('n', 'gS', function() treesj.toggle() end)
    end
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
        n_lines = 250,
        custom_textobjects = {
          b = { { '%b()', '%b[]', '%b{}' }, '^.().*().$' },
          l = ai.gen_spec.treesitter({ a = '@block.outer', i = '@block.inner' }, {}),
          f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
          m = ai.gen_spec.treesitter({ a = '@method.outer', i = '@method.inner' }, {}),
          c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }, {}),
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
    "nvim-neotest/neotest",
    lazy = true,
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Runners
      "fredrikaverpil/neotest-golang",
      "olimorris/neotest-rspec",
      "nvim-neotest/neotest-vim-test",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-rspec"),
          require("neotest-golang"),
          require("neotest-vim-test")({
            ignore_file_types = { "ruby", "go" },
          }),
        },
      })
    end
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
      {
        '<LEADER>gop', function()
          local target = vim.fn.expand("<cWORD>")
          -- command below might be very fish-shell specific
          local my_pr_command = string.format("branch=(git-pilebranchname %s) gh pr view $branch --web", target)
          local historical_pr_command = string.format("url=$(gh pr list --search %s --state=all --json=url --jq=\".[0].url\") open $url", target)

          vim.cmd("!" .. my_pr_command .. "||" .. historical_pr_command)
        end
      },
      { '<LEADER>gso', run_or_prompt_fn('G show') },
      { '<LEADER>gsO', run_or_prompt_fn('G show', { quick_execute = true, move_result_to_new_tab = true }) },
      { '<LEADER>grb', ':G rebase<SPACE>' },
      { '<LEADER>gri', run_or_prompt_fn('G rebase --interactive') },
      { '<LEADER>grI', run_or_prompt_fn('G rebase --interactive', { quick_execute = true, postfix = "~1" }) },
      { '<LEADER>gra', ':G rebase --abort<CR>' },
      { '<LEADER>grc', ':G rebase --continue<CR>' },
      { '<LEADER>grs', ':G reset --soft<SPACE>' },
      { '<LEADER>grh', ':G reset --hard<SPACE>' },
      { '<LEADER>grv', run_or_prompt_fn('G revert') },
      { '<LEADER>grV', run_or_prompt_fn('G revert', { quick_execute = true }) },
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
      { '<LEADER>gbd', ':G branch -D <SPACE>' },
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
  {
    'declancm/windex.nvim',
    lazy = true,
    keys = {
      { "<LEADER>h", "<CMD>lua require('windex').switch_window('left')<CR>" },
      { "<LEADER>j", "<CMD>lua require('windex').switch_window('down')<CR>" },
      { "<LEADER>k", "<CMD>lua require('windex').switch_window('up')<CR>" },
      { "<LEADER>l", "<CMD>lua require('windex').switch_window('right')<CR>" },
    },
  },
  { 'echasnovski/mini.bracketed', version = '*', config = true },
  -- Open alternative files for the current buffer.
  {
    'rgroli/other.nvim',
    lazy = true,
    config = function()
      -- Config function here is explicit cause Lazy.nvim cannot find that module
      require('other-nvim').setup({
        mappings = {
          'rails'
        }
      })
    end,
    cmd = 'Other'
  },

  -- Files manager
  {
    'stevearc/oil.nvim',
    lazy = true,
    opts = {},
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
    commit = '16a51977dcaab1e1adc3152471ac862202f9be83',
    build = ':TSUpdate'
  },
  { 'nvim-treesitter/nvim-treesitter-textobjects' },
  { 'RRethy/nvim-treesitter-endwise' },
  { 'windwp/nvim-ts-autotag' },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
  { 'nvim-treesitter/playground', lazy = true },

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
      'elixir',
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

vim.keymap.set('n', '<LEADER>cc', run_in_tmux_fn(
  function() return 'chezmoi apply --source-path ' .. vim.fn.expand('%') end,
  { tmux_cmd = "split-window -h -p 25" }
))

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

vim.keymap.set('n', '<LEADER>fo', vim.cmd.Other)

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


local servers = {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { 'vim' }
        },
      }
    }
  },
  yamlls = {
    settings = {
      yaml = {
        keyOrdering = false,
      }
    }
  },
  gopls = {},
  ruby_lsp = {
    cmd = { vim.fn.expand("~/.local/share/mise/shims/ruby-lsp") },
    init_options = {
      addonSettings = {
        ["Ruby LSP Rails"] = {
          enablePendingMigrationsPrompt = false,
        }
      }
    }
  },
  rubocop = {
    cmd = { vim.fn.expand("~/.local/share/mise/shims/rubocop") },
  }
}

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'ruby_lsp',
    'lua_ls',
    'ts_ls',
    'gopls',
    'yamlls'
  },
  handlers = {
    function (server_name)
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local on_init = function(client)
        client.server_capabilities.semanticTokensProvider = nil
      end

      local server = servers[server_name] or {}
      server.capabilities = capabilities
      server.on_init = on_init

      require('lspconfig')[server_name].setup(server)
    end,
  }
})

require('blink.cmp').setup({
  keymap = {
    preset = 'default',
    ['<CR>'] = { 'accept', 'fallback' },
    ['<Tab>'] = {
      function(cmp)
        if cmp.snippet_active() then
          return cmp.snippet_forward()
        elseif cmp.is_visible() then
          local items = cmp.get_items()
          if items and #items == 1 then
            return cmp.accept()
          else
            return cmp.select_next()
          end
        end
      end,
      'fallback'
    },
    ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
    ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
  },

  appearance = {
    use_nvim_cmp_as_default = true,
    nerd_font_variant = 'mono'
  },

  sources = {
    default = { 'copilot', 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      copilot = {
        name = "copilot",
        module = "blink.compat.source",
        score_offset = 100,
        async = true,
        opts = {
          get_source = function()
            return require("copilot_cmp.source")
          end,
        },
      },
    },
  },

  completion = {
    accept = {
      auto_brackets = {
        enabled = true,
      },
    },
    menu = {
      draw = {
        treesitter = { "lsp" },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
  },

  cmdline = {
    enabled = false,
  },

  enabled = function()
    -- Disable in certain buffer types
    local disabled_filetypes = {
      'fugitive',
      'fugitiveblame',
      'gitcommit',
      'gitrebase',
      'help',
      'TelescopePrompt',
      'oil',
    }

    local ft = vim.bo.filetype
    if vim.tbl_contains(disabled_filetypes, ft) then
      return false
    end

    -- Disable in command-line mode
    return vim.api.nvim_get_mode().mode ~= 'c'
  end,

  snippets = {
    expand = function(snippet) vim.snippet.expand(snippet) end,
    active = function(filter)
      return vim.snippet.active(filter)
    end,
    jump = function(direction)
      vim.snippet.jump(direction)
    end,
  },
})

-------------------------------------------------
-- Autogroups - General
-------------------------------------------------
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd('VimResized', {
  group = augroup('glebglazov-resize', {clear = true}),
  callback = function()
    vim.cmd('wincmd =')
  end
})

-------------------------------------------------
-- Autogroups — All files
-------------------------------------------------

autocmd('LspAttach', {
  group = augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local buffnr = event.buf

    vim.keymap.set('n', 'K', vim.lsp.buf.hover, {buffer = buffnr})
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {buffer = buffnr})
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, {buffer = buffnr})
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {buffer = buffnr})
    vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, {buffer = buffnr})
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, {buffer = buffnr})
    vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, {buffer = buffnr})
    vim.keymap.set('n', 'gl', vim.diagnostic.open_float, {buffer = buffnr})
  end
})

autocmd('BufWritePre', {
  group = augroup('glebglazov-remove-end-of-line-spaces', {clear = true}),
  pattern = '*',
  command = '%s/\\s\\+$//e',
})

autocmd('BufWritePre', {
  group = augroup('glebglazov-remove-end-of-file-empty-lines', {clear = true}),
  pattern = '*',
  command = '%s#\\($\\n\\s*\\)\\+\\%$##e',
})

autocmd('VimEnter', {
  group = augroup('glebglazov-open-file-browser-at-startup', {clear = true}),
  callback = function()
    local is_headless = false
    local has_file_arg = false

    local startup_args = vim.v.argv
    for _, arg in ipairs(startup_args) do
      if arg == '--headless' then
        is_headless = true
        break
      elseif not string.match(arg, '^-') and arg ~= vim.v.argv[1] then
        -- Check if argument is not a flag and not the nvim executable name
        has_file_arg = true
      end
    end

    if not is_headless and not has_file_arg then
      telescope_find_files()
    end
  end
})

-------------------------------------------------
-- Autogroups — Fugitive
-------------------------------------------------

local fugitive_group = augroup('glebglazov-fugitive-settings', {clear = true})

autocmd('FileType', {
  group = fugitive_group,
  pattern = 'fugitive',
  callback = function ()
    vim.keymap.set('n', '<TAB>', '=', { remap = true, silent = true, buffer = true }) -- TIL: in vim.keymap.set only "remap" option works
    vim.keymap.set('n', 'ce', ':G commit --allow-empty<CR>', { silent = true, buffer = true })
  end
})

autocmd('FileType', {
  group = fugitive_group,
  pattern = 'gitcommit',
  callback = function()
    vim.opt_local.textwidth = 0
    vim.opt_local.wrapmargin = 0
    vim.opt_local.colorcolumn = "72"
  end
})

-------------------------------------------------
-- Autogroups — Lua
-------------------------------------------------
autocmd('FileType', {
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
autocmd('FileType', {
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
autocmd('FileType', {
  group = augroup('glebglazov-golang-settings', {clear = true}),
  pattern = 'go',
  callback = function ()
    local full_path = vim.fn.expand("%")
    vim.keymap.set('n', '<LEADER>ef', run_in_tmux_fn("go run " .. full_path), { buffer = true })
  end
})

-------------------------------------------------
-- Autogroups — Markdown
-------------------------------------------------
autocmd('FileType', {
  group = augroup('glebglazov-markdown-settings', {clear = true}),
  pattern = 'markdown',
  callback = function ()
    vim.keymap.set('n', '<LEADER>vf', function() vim.cmd('MarkdownPreview') end, { buffer = true })
  end
})

-- Run gofmt/gofmpt, import packages automatically on save
autocmd('BufWritePre', {
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
autocmd('FileType', {
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

vim.keymap.set('v', '<LEADER>fy', function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  local path = vim.fn.expand('%:p')
  local range_path = path .. ':' .. start_line .. '-' .. end_line

  vim.fn.setreg('+', range_path)
  print("Copied to clipboard: " .. range_path)
end)

vim.keymap.set('n', '<LEADER>by', 'ggVGy')

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

-- Window
vim.keymap.set('n', '<LEADER>w', ':hide<CR>', { silent = true })
vim.keymap.set('t', '<LEADER>w', [[<C-\><C-n>:hide<CR>]])

vim.keymap.set('n', '<LEADER>bd', ':bd<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>Bd', ':%bdelete | edit # | normal `', { silent = true })
vim.keymap.set('n', '<LEADER>d', ':vsp | :wincmd l<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>D', ':sp | :wincmd j<CR>', { silent = true })

-- git-pile (EXPERIMENTAL)
vim.keymap.set('n', '<LEADER>gsp', run_in_tmux_fn('git submitpr', { with_pause = false }))
vim.keymap.set('n', '<LEADER>gup', run_in_tmux_fn('git updatepr', { prompt = true }))
vim.keymap.set('n', '<LEADER>guP', function()
  local target = vim.fn.expand("<cWORD>")

  run_in_tmux_fn(string.format("git updatepr %s", target), { with_pause = false })()
end)
vim.keymap.set('n', '<LEADER>ghp', run_in_tmux_fn('git headpr'))
vim.keymap.set('n', '<LEADER>grp', run_in_tmux_fn('git replacepr', { prompt = true }))
vim.keymap.set('n', '<LEADER>grP', run_in_tmux_fn('git rebasepr', { prompt = true }))

-- Running tests
vim.keymap.set('n', '<LEADER>tt', function() require("neotest").run.run() end)
vim.keymap.set('n', '<LEADER>tT', function() require("neotest").run.run(vim.fn.expand("%")) end)
vim.keymap.set('n', '<LEADER>ts', function() require("neotest").run.stop() end)
vim.keymap.set('n', '<LEADER>ta', function() require("neotest").run.attach() end)

-- Files / Projects
vim.keymap.set('n', '<LEADER>fs', ':up<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>fS', ':wq<CR>', { silent = true })
vim.keymap.set('n', '<LEADER>pp', ':tcd ~/Dev/')

vim.keymap.set('n', '<LEADER>pp', ':tcd ~/Dev/')

vim.keymap.set('n', '<LEADER>qq', ':qa<CR>')
vim.keymap.set('n', '<LEADER>QQ', ':qa!<CR>')
