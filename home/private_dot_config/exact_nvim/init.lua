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

local function get_default_remote_branch()
  local handle = io.popen("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/@@'")
  local default_branch = "origin/main"

  if handle then
    local result = handle:read("*a"):gsub("%s+", "")
    handle:close()
    if result ~= "" then
      default_branch = result
    end
  end

  return default_branch
end

local function run_in_tmux_fn(command, opts)
  return function ()
    opts = opts or {}
    local tmux_cmd = opts.tmux_cmd or "new-window"
    local with_pause = opts.with_pause == nil and true or opts.with_pause

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

-- Follow macOS light/dark appearance.
-- AppleInterfaceStyle is "Dark" in dark mode and absent (error) in light mode.
-- Setting background fires OptionSet, which re-applies gruvbox (see below).
local function sync_macos_background()
  local out = vim.fn.system({ 'defaults', 'read', '-g', 'AppleInterfaceStyle' })
  local want = (vim.v.shell_error == 0 and out:match('Dark')) and 'dark' or 'light'
  if vim.o.background ~= want then
    vim.opt.background = want
  end
end

sync_macos_background()
vim.api.nvim_create_autocmd('FocusGained', { callback = sync_macos_background })

-- Comment these two for now: I remember those causing some issues, but let's try again
-- vim.o.swapfile = false
-- vim.o.backup = false

vim.opt.iskeyword:remove('_')

vim.opt.clipboard = 'unnamed,unnamedplus'

vim.opt.signcolumn = "yes"
vim.diagnostic.config({
  update_in_insert = true,
})

-- Detect helm filetype
vim.filetype.add({
  extension = {
    gotmpl = 'gotmpl',
  },
  pattern = {
    [".*/templates/.*%.tpl"] = "helm",
    [".*/templates/.*%.ya?ml"] = "helm",
    ["helmfile.*%.ya?ml"] = "helm",
  },
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
      {'williamboman/mason-lspconfig.nvim'},
    },
  },
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
      {
        'zbirenbaum/copilot.lua', -- credentials are stored in ~/.config/github-copilot/hosts.json
        cmd = 'Copilot',
        event = "InsertEnter",
        opts = {
          suggestion = { enabled = false },
          panel = { enabled = false },
        }
      },
      'fang2hou/blink-copilot',
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
    'iamcco/markdown-preview.nvim',
    ft = { 'markdown' },
    build = function() vim.fn["mkdp#util#install"]() end,
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
  },

  -------------------------------------------------
  -- Git integration
  -------------------------------------------------
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signcolumn = false, -- off by default; toggle with <LEADER>tg
    },
    keys = {
      { '<LEADER>tg', function() require('gitsigns').toggle_signs() end, desc = 'Toggle git signs' },
      { '<LEADER>td', function() require('gitsigns').toggle_deleted() end, desc = 'Toggle deleted lines inline' },
      { '<LEADER>tp', function() require('gitsigns').preview_hunk() end, desc = 'Preview hunk (added + removed)' },
      { '<LEADER>tb', function() require('gitsigns').change_base(get_default_remote_branch(), true) end, desc = 'Gitsigns base → default branch' },
      { ']h', function() require('gitsigns').nav_hunk('next') end, desc = 'Next hunk' },
      { '[h', function() require('gitsigns').nav_hunk('prev') end, desc = 'Previous hunk' },
    },
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
      {
        '<LEADER>gop', function()
          local target = vim.fn.expand("<cWORD>")
          -- zsh version
          local my_pr_command = string.format("branch=$(git-pilebranchname %s) && gh pr view $branch --web", target)
          local historical_pr_command = string.format("url=$(gh pr list --search %s --state=all --json=url --jq=\".[0].url\") && open $url", target)

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
      {
        '<LEADER>gcB',
        function()
          local default_branch = get_default_remote_branch()
          local cmd = ":G checkout -b  " .. default_branch
          local left_moves = string.rep("<Left>", #default_branch + 1)
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd .. left_moves, true, false, true), "n", false)
        end,
      },
      { '<LEADER>gce', ':G commit --allow-empty -m \'\'<LEFT>' },
      {
        '<LEADER>gpl',
        function()
          vim.system({ 'git', 'pull', '--rebase', '--tags' }, { text = true }, function(pull)
            vim.schedule(function()
              if pull.code ~= 0 then
                vim.notify((pull.stderr or '') .. (pull.stdout or ''), vim.log.levels.ERROR)
                return
              end
              vim.system(
                { 'git', 'submodule', 'update', '--init', '--recursive' },
                { text = true },
                function(sub)
                  vim.schedule(function()
                    local out = (pull.stdout or '') .. (sub.stdout or '') .. (sub.stderr or '')
                    vim.notify(out, sub.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
                    vim.cmd('checktime')
                  end)
                end
              )
            end)
          end)
        end,
      },
      { '<LEADER>gpo', ':G push<CR>' },
      { '<LEADER>gpf', ':G push --force-with-lease origin HEAD<CR>' },
      { '<LEADER>gpF', ':G push --force origin HEAD<CR>' },
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
      { '<LEADER>gf', ':G fetch<CR>' },
      {
        '<LEADER>gpr',
        function()
          vim.fn.system('tmux new-window -n "pr" git-push-pr')
        end,
      },
      {
        '<LEADER>gwp', -- "git worktree prinstine"
        function()
          -- Step 1: Check for uncommitted changes
          local status = vim.fn.system("git status --porcelain 2>/dev/null")
          if status ~= "" then
            vim.notify("Uncommitted changes present", vim.log.levels.ERROR)
            return
          end

          -- Get worktree branch name (directory name)
          local worktree_branch = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

          -- Get default remote branch
          local default_branch = get_default_remote_branch()

          -- Step 2: Git fetch
          vim.notify("Fetching...", vim.log.levels.INFO)
          local fetch_result = vim.fn.system("git fetch 2>&1")
          if vim.v.shell_error ~= 0 then
            vim.notify("git fetch failed: " .. fetch_result, vim.log.levels.ERROR)
            return
          end

          -- Step 3: Checkout worktree branch
          local checkout_result = vim.fn.system("git checkout " .. worktree_branch .. " 2>&1")
          if vim.v.shell_error ~= 0 then
            vim.notify("git checkout failed: " .. checkout_result, vim.log.levels.ERROR)
            return
          end

          -- Step 4: Check for unpushed commits
          local commits_ahead = vim.fn.system("git log " .. default_branch .. "..HEAD --oneline 2>/dev/null")
          if commits_ahead ~= "" then
            vim.notify("Branch " .. worktree_branch .. " has commits not in " .. default_branch .. ":\n" .. commits_ahead, vim.log.levels.ERROR)
            return
          end

          -- Step 5: Reset hard to default branch
          local reset_result = vim.fn.system("git reset --hard " .. default_branch .. " 2>&1")
          if vim.v.shell_error ~= 0 then
            vim.notify("git reset failed: " .. reset_result, vim.log.levels.ERROR)
            return
          end

          vim.notify("Worktree reset to " .. default_branch, vim.log.levels.INFO)
        end,
      }
    },
  },
  {
    'sindrets/diffview.nvim',
    keys = {
      {
        '<LEADER>gd',
        function()
          local function resolve_base()
            -- Prefer the remote's default branch when a remote HEAD is set.
            local remote = vim.fn.systemlist('git symbolic-ref --short refs/remotes/origin/HEAD')[1]
            if vim.v.shell_error == 0 and remote and remote ~= '' then
              return remote
            end
            -- Fall back to a local default branch (no remote, or origin/HEAD unset).
            for _, b in ipairs({ 'main', 'master' }) do
              vim.fn.system({ 'git', 'rev-parse', '--verify', '--quiet', 'refs/heads/' .. b })
              if vim.v.shell_error == 0 then
                return b
              end
            end
            return nil
          end

          local base = resolve_base()
          if not base then
            vim.notify('diffview: could not resolve a default branch', vim.log.levels.WARN)
            return
          end
          vim.cmd('DiffviewOpen ' .. base .. '..HEAD')
        end,
        desc = 'Diffview vs default branch',
      },
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

      -- Dark uses hard contrast (matches Ghostty "Gruvbox Dark Hard");
      -- light uses medium (matches Ghostty "Gruvbox Light").
      local function apply()
        gruvbox.setup({
          contrast = vim.o.background == 'dark' and 'hard' or '',
          overrides = {
            DiffAdd = { fg = "#b8bb26", bg = "NONE" },
            DiffDelete = { fg = "#fb4934", bg = "NONE" },
          },
        })
        vim.cmd([[colorscheme gruvbox]])
      end

      apply()
      -- Re-apply whenever the background flips (set by the macOS-appearance sync).
      vim.api.nvim_create_autocmd('OptionSet', { pattern = 'background', callback = apply })
    end
  },

  -------------------------------------------------
  -- Navigation
  -------------------------------------------------
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

  -- Image preview
  {
    '3rd/image.nvim',
    event = 'VeryLazy',
    build = false,
    opts = {
      backend = 'kitty',
      processor = 'magick_cli',
      max_width_window_percentage = 100,
      max_height_window_percentage = 100,
      tmux_show_only_in_active_window = true,
      integrations = {
        markdown = { enabled = true },
        neorg = { enabled = true },
        html = { enabled = false },
        css = { enabled = false },
      },
    },
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
      local previewers = require('telescope.previewers')
      local telescope_image_preview = require('telescope_image_preview')

      require('telescope').setup({
        defaults = {
          buffer_previewer_maker = telescope_image_preview.wrap_buffer_previewer_maker(
            previewers.buffer_previewer_maker
          ),
        },
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
    branch = 'main',
    build = ':TSUpdate',
  },
  { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
  { 'RRethy/nvim-treesitter-endwise' },
  { 'windwp/nvim-ts-autotag', opts = {} },

})

-------------------------------------------------
-- Configure Treesitter
-------------------------------------------------
vim.defer_fn(function() -- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
  require('nvim-treesitter').install {
    'ruby', 'elixir', 'terraform', 'hcl', 'lua', 'vimdoc', 'vim',
    'markdown', 'markdown_inline', 'clojure', 'javascript', 'typescript', 'tsx', 'python', 'go',
    'git_config', 'git_rebase', 'gitcommit', 'gitignore', 'gitattributes',
  }

  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local max_filesize = 100 * 1024 -- 100 KB
      local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
      if ok and stats and stats.size > max_filesize then
        return
      end

      if not pcall(vim.treesitter.start, args.buf) then
        return
      end

      if vim.bo[args.buf].filetype ~= 'ruby' then
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end,
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

vim.keymap.set('n', '<LEADER>u', vim.cmd.Undotree)

vim.keymap.set('n', '<LEADER>nd', function()
  require('notify').dismiss({ silent = true, pending = true })
end, { desc = 'Dismiss all notifications' })

vim.keymap.set('n', '<LEADER>cf', function()
  vim.cmd('edit ~/.local/share/chezmoi/home/private_dot_config/exact_nvim/init.lua', { silent = true })
end)

vim.keymap.set('n', '<LEADER>cs', function()
  vim.cmd('!chezmoi apply ~/.config/nvim/init.lua', { silent = true })
  vim.cmd('source ' .. vim.fn.stdpath('config') .. '/init.lua')
end)

vim.keymap.set('n', '<LEADER>cc', run_in_tmux_fn(
  function() return 'chezmoi apply --force --source-path ' .. vim.fn.expand('%') end,
  { tmux_cmd = "split-window -h -p 25", with_pause = false }
))

vim.keymap.set('n', '<LEADER>bb',builtin.buffers)
vim.keymap.set('n', '<LEADER>/', function()
  builtin.live_grep({
    file_ignore_patterns = { "thoughts/" }
  })
end)
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
    cwd = vim.fn.getcwd(),
    hidden = true,
    file_ignore_patterns = { "^.git/", "^node_modules/" },
  })
end

vim.keymap.set('n', '<LEADER>fb', require('telescope.builtin').buffers)
vim.keymap.set('n', '<LEADER>fh', require('telescope.builtin').help_tags)
vim.keymap.set('n', '<LEADER>ft', function()
  local results = vim.fn.systemlist("fd --type f --no-ignore . thoughts 2>/dev/null | sort -r")
  if #results == 0 then return end
  local order = {}
  for i, r in ipairs(results) do order[r] = i end

  require('telescope.pickers').new({}, {
    prompt_title = 'Thoughts',
    finder = require('telescope.finders').new_table({
      results = results,
      entry_maker = function(line)
        return { value = line, display = line, ordinal = line, path = vim.fn.getcwd() .. "/" .. line }
      end,
    }),
    sorter = require('telescope.sorters').Sorter:new({
      scoring_function = function(_, prompt, line)
        if prompt ~= "" and not line:lower():find(prompt:lower(), 1, true) then return -1 end
        return order[line] or 0
      end,
    }),
    previewer = require('telescope.config').values.file_previewer({}),
  }):find()
end)
vim.keymap.set('n', '<LEADER>fp', telescope_find_files)

-------------------------------------------------
-- Setup LSP / Autocompletion
-------------------------------------------------


-- Configure LSP servers using vim.lsp.config (Neovim 0.11+ API)
-- Must be called BEFORE mason-lspconfig.setup()
local capabilities = require('blink.cmp').get_lsp_capabilities()
local on_init = function(client)
  client.server_capabilities.semanticTokensProvider = nil
end

vim.lsp.config('*', {
  capabilities = capabilities,
  on_init = on_init,
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      },
    }
  }
})

vim.lsp.config('yamlls', {
  settings = {
    yaml = {
      keyOrdering = false,
    }
  }
})

vim.lsp.config('gopls', {})

vim.lsp.config('ts_ls', {})

vim.lsp.config('ruby_lsp', {
  cmd = { vim.fn.expand("~/.local/bin/mise-gem-exec"), "ruby-lsp" },
  init_options = {
    addonSettings = {
      ["Ruby LSP Rails"] = {
        enablePendingMigrationsPrompt = false,
      }
    }
  }
})

vim.lsp.config('rubocop', {
  cmd = { vim.fn.expand("~/.local/bin/mise-gem-exec"), "rubocop" },
})

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'ruby_lsp',
    'lua_ls',
    'ts_ls',
    'gopls',
    'yamlls'
  },
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
        module = "blink-copilot",
        score_offset = 100,
        async = true,
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
      auto_show_delay_ms = 0,
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
      -- Check if we're in a bare repo root and cd to default worktree
      local cwd = vim.fn.getcwd()
      local git_dir = cwd .. '/.git'

      -- Detect bare repo: .git is a directory with bare = true config
      local is_bare_repo = vim.fn.isdirectory(git_dir) == 1
        and vim.fn.system('git -C ' .. cwd .. ' config --get core.bare'):gsub('%s+', '') == 'true'

      if is_bare_repo then
        -- We're in a bare repo root, cd to default branch worktree
        local default_branches = {'main', 'master'}
        for _, branch in ipairs(default_branches) do
          local worktree_path = cwd .. '/' .. branch
          if vim.fn.isdirectory(worktree_path) == 1 then
            vim.cmd('cd ' .. worktree_path)
            break
          end
        end
      end

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
-- Autogroups — JSON
-------------------------------------------------
autocmd('FileType', {
  group = augroup('glebglazov-json-settings', {clear = true}),
  pattern = 'json',
  callback = function ()
    vim.bo.equalprg = [=[
      sh -c 'input=$(cat); jq_output=$(echo "$input" | jq . 2>/dev/null); [[ $? -eq 0 ]] && echo "$jq_output" || echo "$input"'
    ]=]
  end
})

-------------------------------------------------
-- Changeset → QuickFix
-------------------------------------------------
-- Resolve a base spec into (base_rev, uncommitted). '--uncommitted' reviews the
-- working tree (staged + unstaged) against HEAD; a bare ref is used as the base;
-- nil/'' falls back to the default remote branch.
local function review_resolve_base(arg)
  if arg == '--uncommitted' then return 'HEAD', true end
  return (arg and arg ~= '') and arg or get_default_remote_branch(), false
end

-- Populate the quickfix list with files changed against `base`. Committed reviews
-- use `base...<head>` (merge-base), where <head> defaults to HEAD but may be a
-- single commit (e.g. base=<c>^, head=<c> → just that commit); --uncommitted
-- uses the working tree vs HEAD.
local function review_files(base, uncommitted, head)
  local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 or not root or root == '' then
    vim.notify('Review: not in a git repo', vim.log.levels.WARN)
    return false
  end

  -- Buffer we started from; dropped below so the session opens on a clean,
  -- single-file view (just the first changed file) instead of whatever was open.
  local prev_buf = vim.api.nvim_get_current_buf()
  local range = uncommitted and 'HEAD' or (base .. '...' .. ((head and head ~= '') and head or 'HEAD'))
  -- --name-status so we can flag added/deleted/renamed files in the qf text;
  -- gitsigns only marks hunks within a file (and shows nothing for files absent
  -- from the base), so the per-file "new" indicator has to live in the list.
  local status_label = { A = '[new] ', D = '[del] ', R = '[ren] ', C = '[cpy] ' }
  local lines = vim.fn.systemlist('git -C ' .. root .. ' diff --name-status ' .. range)
  local items = {}
  for _, line in ipairs(lines) do
    -- "A\tpath", "M\tpath", "R100\told\tnew" — status is the first char, the
    -- path we want is the last tab-separated field.
    local parts = vim.split(line, '\t', { plain = true })
    local status = parts[1]:sub(1, 1)
    local f = parts[#parts]
    table.insert(items, {
      filename = root .. '/' .. f,
      lnum = 1,
      text = (status_label[status] or '') .. f,
    })
  end
  -- Close any open qf window first: setqflist into an open window reloads its
  -- buffer and fires `FileType qf` while we're still focused elsewhere, which
  -- trips qf_helper's set_qf_defaults (get_win_type() → nil). copen below opens
  -- a fresh window with the qf window focused, so the FileType fires cleanly.
  pcall(vim.cmd, 'cclose')
  vim.fn.setqflist(items)
  vim.cmd('copen')
  -- Jump to the first changed file, then drop the buffer we came from.
  if #vim.fn.getqflist() > 0 then
    vim.cmd('cfirst')
    if vim.api.nvim_buf_is_valid(prev_buf) and vim.api.nvim_get_current_buf() ~= prev_buf then
      pcall(vim.cmd, 'bdelete ' .. prev_buf)
    end
  end
  return true
end

-------------------------------------------------
-- Local code review (own state, agent-facing export)
-------------------------------------------------
-- Annotate changed buffers with comments, then export them all as a single
-- Markdown block for pasting into an AI agent. State lives here, NOT in the
-- quickfix list, so it never collides with :Changes above.
local review = {
  comments = {}, -- comments[abs_path] = { { lnum, end_lnum, text }, ... }
  general = nil, -- at most one session-wide note: { text, status }
  active = false, -- whether a review session is in progress (drives statusline)
}
local review_ns = vim.api.nvim_create_namespace('glebglazov-review')
local review_default_statusline = vim.o.statusline

-- Muted, easy-on-the-eyes review statusline badge (gruvbox neutral aqua on bg1).
vim.api.nvim_set_hl(0, 'ReviewStatus', { fg = '#83a598', bg = '#3c3836', bold = true })
-- Left-margin range bars: aqua while unresolved, muted grey once resolved.
vim.api.nvim_set_hl(0, 'ReviewBar', { fg = '#83a598' })
vim.api.nvim_set_hl(0, 'ReviewBarResolved', { fg = '#665c54' })

local function review_repo_root()
  local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 or not root or root == '' then
    return nil
  end
  return root
end

-- Render inline virtual text for a loaded buffer (only when toggled on).
local function review_render_buf(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, review_ns, 0, -1)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local total = vim.api.nvim_buf_line_count(bufnr)
  for _, c in ipairs(review.comments[path] or {}) do
    local resolved = c.status == 'resolved'
    -- Left bar spanning every line of the commented range (priority above
    -- gitsigns so the range wins the sign cell on its own lines).
    local bar_hl = resolved and 'ReviewBarResolved' or 'ReviewBar'
    for l = c.lnum, math.min(c.end_line or c.lnum, total) do
      pcall(vim.api.nvim_buf_set_extmark, bufnr, review_ns, l - 1, 0, {
        sign_text = '▌',
        sign_hl_group = bar_hl,
        priority = 100,
      })
    end
    -- Inline label at the head line.
    local first = c.text:match('[^\n]*') or c.text
    local label = first
    if c.text:find('\n') then label = first .. ' …' end
    local icon = resolved and '󰄬' or '󰆉'
    local hl = resolved and 'Comment' or 'DiagnosticVirtualTextInfo'
    pcall(vim.api.nvim_buf_set_extmark, bufnr, review_ns, c.lnum - 1, 0, {
      virt_text = { { icon .. ' ' .. label, hl } },
      virt_text_pos = 'eol',
    })
  end
end

-- Re-render every loaded buffer that has comments (and the current one).
local function review_render_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      review_render_buf(bufnr)
    end
  end
end

-- Re-render the buffer for `path` (signs + inline labels both come from extmarks).
local function review_refresh(path)
  local bufnr = vim.fn.bufnr(path)
  if bufnr ~= -1 then review_render_buf(bufnr) end
end

-- Reorder the quickfix list so files with comments float to the top (with a
-- marker + comment count). Only acts during a review session.
local function review_qf_sort()
  if not review.active then return end
  local qf = vim.fn.getqflist({ items = 0, title = 0 })
  local items = qf.items or {}
  if #items == 0 then return end
  local root = review_repo_root()
  local commented, rest = {}, {}
  for _, it in ipairs(items) do
    local name = (it.bufnr and it.bufnr > 0) and vim.api.nvim_buf_get_name(it.bufnr) or ''
    local rel = (root and name ~= '' and name:sub(1, #root) == root) and name:sub(#root + 2) or name
    local list = review.comments[name]
    if list and #list > 0 then
      it.text = ('● (%d) %s'):format(#list, rel)
      table.insert(commented, it)
    else
      it.text = rel
      table.insert(rest, it)
    end
  end
  vim.list_extend(commented, rest)
  vim.fn.setqflist({}, 'r', { items = commented, title = qf.title })
end

local function review_add(start_line, end_line)
  local path = vim.fn.expand('%:p')
  -- Reuse an existing comment instead of stacking a new one. A single-line
  -- request (cursor, no range) edits whatever comment covers that line; an
  -- explicit range edits only a comment with the exact same span.
  local single = start_line == end_line
  local existing
  for _, c in ipairs(review.comments[path] or {}) do
    local cs, ce = c.lnum, (c.end_line or c.lnum)
    local match
    if single then
      match = start_line >= cs and start_line <= ce
    else
      match = cs == start_line and ce == end_line
    end
    if match then
      existing = c
      break
    end
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'
  vim.b[buf].completion = false -- blink.cmp honours this: no autocomplete popup in the comment box
  if existing then
    local lines = vim.split(existing.text, '\n', { plain = true })
    table.insert(lines, '') -- fresh trailing line so the cursor lands ready to keep typing
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  local width = math.min(80, math.floor(vim.o.columns * 0.6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = 8,
    border = 'rounded',
    title = (existing and ' Edit comment' or ' Review comment') .. '  (<CR> save · <Esc> cancel) ',
    title_pos = 'center',
    style = 'minimal',
  })
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
      vim.cmd('startinsert!')
    end
  end)

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  local function confirm()
    local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'))
    close()
    if existing then
      if text == '' then
        -- emptied → drop the comment
        local list = review.comments[path]
        for i = #list, 1, -1 do
          if list[i] == existing then table.remove(list, i) end
        end
      else
        existing.text = text
      end
    else
      if text == '' then return end
      review.comments[path] = review.comments[path] or {}
      table.insert(review.comments[path], { lnum = start_line, end_line = end_line, text = text, status = 'unresolved' })
    end
    review_refresh(path)
  end
  vim.keymap.set('n', '<CR>', confirm, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true })
end

-- Session-wide note not tied to any file. Only one allowed; reopens for edit if present
-- and unresolved. A resolved note stays in preview but rC opens a fresh editor instead.
local function review_add_general()
  local existing = review.general
  if existing and existing.status == 'resolved' then
    existing = nil
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'
  vim.b[buf].completion = false
  if existing then
    local lines = vim.split(existing.text, '\n', { plain = true })
    table.insert(lines, '')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  local width = math.min(80, math.floor(vim.o.columns * 0.6))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor(vim.o.lines * 0.3),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = 8,
    border = 'rounded',
    title = (existing and ' Edit general note' or ' General review note') .. '  (<CR> save · <Esc> cancel) ',
    title_pos = 'center',
    style = 'minimal',
  })
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
      vim.cmd('startinsert!')
    end
  end)

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  local function confirm()
    local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'))
    close()
    if text == '' then
      review.general = nil
    else
      review.general = { text = text, status = existing and existing.status or 'unresolved' }
    end
  end
  vim.keymap.set('n', '<CR>', confirm, { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true })
end

local function review_add_normal()
  local lnum = vim.fn.line('.')
  review_add(lnum, lnum)
end

local function review_add_visual()
  local s = vim.fn.getpos('v')[2]
  local e = vim.fn.getpos('.')[2]
  -- leave visual mode synchronously BEFORE opening the float; a queued nvim_input('<ESC>')
  -- would otherwise land after startinsert and kick us back to normal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'nx', false)
  review_add(math.min(s, e), math.max(s, e))
end

local function review_delete_at_cursor()
  local path = vim.fn.expand('%:p')
  local list = review.comments[path]
  if not list then return end
  local cur = vim.fn.line('.')
  for i = #list, 1, -1 do
    local c = list[i]
    if cur >= c.lnum and cur <= (c.end_line or c.lnum) then
      table.remove(list, i)
    end
  end
  review_refresh(path)
end

local function review_clear()
  review.comments = {}
  review.general = nil
  review_render_all()
  vim.notify('Review comments cleared', vim.log.levels.INFO)
end

local function review_set_statusline()
  -- setglobal only: a bare `vim.o`/`:set` on this global-local option also resets the
  -- CURRENT window's local statusline, which would clobber the qf-local one we set.
  if review.active then
    vim.go.statusline = '%#ReviewStatus# 󰆉 REVIEW %* %f %m%r%=%l:%c '
  else
    vim.go.statusline = review_default_statusline
  end
end

-- Lazy-load gitsigns and run a function against it (keys-lazy plugin).
local function review_with_gitsigns(fn)
  pcall(function()
    require('lazy').load({ plugins = { 'gitsigns.nvim' } })
    fn(require('gitsigns'))
  end)
end

-- Start a review: changeset → quickfix, gitsigns base→<base> + signs on, inline
-- comments on, statusline badge. `base` is a resolved rev; `uncommitted` reviews
-- the working tree vs HEAD.
local function review_start(base, uncommitted, head)
  base = base or get_default_remote_branch()
  review.active = true
  review_with_gitsigns(function(gs)
    gs.change_base(base, true)
    gs.toggle_signs(true)
  end)
  review_files(base, uncommitted, head)
  review_render_all()
  review_set_statusline()
  local target = uncommitted and 'working tree'
    or ((head and head ~= '') and (base .. '...' .. head) or ('base: ' .. base))
  vim.notify(('Review started (%s)'):format(target), vim.log.levels.INFO)
end

-- Flatten all comments into a stable, path-sorted list of { path, rel, c }.
local function review_entries()
  local root = review_repo_root()
  local paths = {}
  for p in pairs(review.comments) do table.insert(paths, p) end
  table.sort(paths)
  local entries = {}
  for _, path in ipairs(paths) do
    local rel = (root and path:sub(1, #root) == root) and path:sub(#root + 2) or path
    for _, c in ipairs(review.comments[path]) do
      table.insert(entries, { path = path, rel = rel, c = c })
    end
  end
  return entries
end

local function review_loc(rel, c)
  return (c.end_line and c.end_line ~= c.lnum)
    and ('%s:%d-%d'):format(rel, c.lnum, c.end_line)
    or ('%s:%d'):format(rel, c.lnum)
end

local function review_append_export(out, n, label, c)
  if c.status == 'resolved' then return n end
  n = n + 1
  if c.text:find('\n') then
    table.insert(out, ('%d. `%s`:\n   %s'):format(n, label, c.text:gsub('\n', '\n   ')))
  else
    table.insert(out, ('%d. `%s` - %s'):format(n, label, c.text))
  end
  return n
end

-- Build the Markdown review body and a count of comments (resolved are skipped).
local function review_build()
  local out, n = {}, 0
  if review.general then
    n = review_append_export(out, n, 'General', review.general)
  end
  for _, e in ipairs(review_entries()) do
    n = review_append_export(out, n, review_loc(e.rel, e.c), e.c)
  end
  return out, n
end

local function review_export()
  local out, n = review_build()
  if n == 0 then
    vim.notify('No review comments to export', vim.log.levels.WARN)
    return false
  end
  vim.fn.setreg('+', table.concat(out, '\n'))
  vim.notify(('Exported %d review comment(s) to clipboard'):format(n), vim.log.levels.INFO)
  return true
end

-- Finish a review: export to clipboard, then clear comments, gitsigns off, badge off.
local function review_finish()
  review_export() -- copies to clipboard (warns if empty); we tear down regardless
  review_with_gitsigns(function(gs) gs.toggle_signs(false) end)
  review_clear()
  review.active = false
  review_set_statusline()
  vim.notify('Review finished', vim.log.levels.INFO)
end

-- Preview the assembled review in a floating scratch buffer (no clipboard write).
-- Shows ALL comments (incl. resolved) with a [ ]/[x] status checkbox; `t` toggles
-- the comment under the cursor. Only unresolved comments are exported.
local function review_preview()
  local entries = review_entries()
  if not review.general and #entries == 0 then
    vim.notify('No review comments to preview', vim.log.levels.WARN)
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'

  local line_to_comment = {}
  local function append_preview(lines, i, mark, label, c)
    if c.text:find('\n') then
      table.insert(lines, ('%d. %s `%s`:'):format(i, mark, label))
      line_to_comment[#lines] = c
      for _, l in ipairs(vim.split(c.text, '\n', { plain = true })) do
        table.insert(lines, '   ' .. l)
        line_to_comment[#lines] = c
      end
    else
      table.insert(lines, ('%d. %s `%s` - %s'):format(i, mark, label, c.text))
      line_to_comment[#lines] = c
    end
  end
  local function render()
    line_to_comment = {}
    local lines = {}
    local i = 0
    if review.general then
      i = i + 1
      local mark = review.general.status == 'resolved' and '[x]' or '[ ]'
      append_preview(lines, i, mark, 'General', review.general)
    end
    for _, e in ipairs(entries) do
      i = i + 1
      local c = e.c
      local mark = c.status == 'resolved' and '[x]' or '[ ]'
      append_preview(lines, i, mark, review_loc(e.rel, c), c)
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
  end
  render()

  local nlines = vim.api.nvim_buf_line_count(buf)
  local width = math.min(140, math.floor(vim.o.columns * 0.9))
  local max_height = math.floor(vim.o.lines * 0.9)
  local height = math.max(math.min(nlines + 1, max_height), math.min(20, max_height))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = 'rounded',
    title = ' Review preview  (t toggle resolved · q close) ',
    title_pos = 'center',
    style = 'minimal',
  })
  vim.keymap.set('n', 't', function()
    local c = line_to_comment[vim.fn.line('.')]
    if not c then return end
    c.status = (c.status == 'resolved') and 'unresolved' or 'resolved'
    local pos = vim.api.nvim_win_get_cursor(win)
    render()
    pcall(vim.api.nvim_win_set_cursor, win, pos)
    review_render_all() -- reflect status in inline virt_text on source buffers
  end, { buffer = buf, nowait = true })
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, { buffer = buf, nowait = true })
end

local function agent_message_lines(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  while #lines > 0 and vim.trim(lines[1]) == '' do
    table.remove(lines, 1)
  end
  while #lines > 0 and vim.trim(lines[#lines]) == '' do
    table.remove(lines, #lines)
  end
  return lines
end

local function agent_pick_pane(on_pick, on_cancel)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'

  local width = math.min(140, math.floor(vim.o.columns * 0.9))
  local max_height = math.floor(vim.o.lines * 0.9)
  local height = math.max(math.min(30, max_height), math.min(10, max_height))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = 'rounded',
    title = ' Pick agent pane ',
    title_pos = 'center',
    style = 'minimal',
  })

  local job_id = vim.fn.jobstart({ 'pop', 'monitor', 'dashboard', '--pick' }, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        local pane_id = nil
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        for i = #lines, 1, -1 do
          local line = vim.trim(lines[i])
          if line:match('^%%%d+$') then
            pane_id = line
            break
          end
        end

        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end

        if code ~= 0 or not pane_id then
          vim.notify('No agent pane selected', vim.log.levels.WARN)
          if on_cancel then on_cancel() end
          return
        end

        on_pick(pane_id)
      end)
    end,
  })

  if job_id <= 0 then
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.notify('Failed to open Pop dashboard picker', vim.log.levels.ERROR)
    if on_cancel then on_cancel() end
    return
  end

  vim.cmd('startinsert')
end

local function agent_send_to_pane(pane_id, message, press_enter)
  local args = {
    'pop',
    'pane',
    'send',
    '--pane-id',
    pane_id,
    message,
  }
  if press_enter then
    table.insert(args, 'Enter')
  end

  local result = vim.system(args, { text = true }):wait()

  if result.code ~= 0 then
    local stderr = vim.trim(result.stderr or '')
    if stderr ~= '' then
      return stderr
    end
    return 'Failed to send message'
  end

  return nil
end

local function agent_paste_to_pane(pane_id, text, press_enter)
  local load = vim.system({ 'tmux', 'load-buffer', '-' }, { text = true, stdin = text }):wait()
  if load.code ~= 0 then
    local stderr = vim.trim(load.stderr or '')
    if stderr ~= '' then
      return stderr
    end
    return 'Failed to load tmux paste buffer'
  end

  local paste = vim.system({ 'tmux', 'paste-buffer', '-p', '-d', '-t', pane_id }, { text = true }):wait()
  if paste.code ~= 0 then
    local stderr = vim.trim(paste.stderr or '')
    if stderr ~= '' then
      return stderr
    end
    return 'Failed to paste text into pane'
  end

  if press_enter then
    return agent_send_to_pane(pane_id, 'Enter', false)
  end

  return nil
end

local function agent_text_float(title, width, height)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'
  vim.b[buf].completion = false -- blink.cmp honours this: no autocomplete popup in agent/review send boxes

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = 'rounded',
    title = title,
    title_pos = 'center',
    style = 'minimal',
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set('n', 'q', close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true, silent = true })

  return buf, win, close
end

local function agent_map_text_send(buf, close, empty_message, success_message)
  local pending = false
  local function submit(press_enter)
    if pending then
      return
    end

    local lines = agent_message_lines(buf)
    if #lines == 0 then
      vim.notify(empty_message, vim.log.levels.WARN)
      return
    end
    local text = table.concat(lines, '\n')
    if text == '' then
      vim.notify(empty_message, vim.log.levels.WARN)
      return
    end

    -- On a type (no Enter) leave the cursor on a fresh line so a follow-up
    -- type lands below instead of being glued onto this one.
    local paste_text = press_enter and text or (text .. '\n')

    pending = true
    agent_pick_pane(function(pane_id)
      pending = false
      local send_err = agent_paste_to_pane(pane_id, paste_text, press_enter)
      if send_err then
        vim.notify(send_err, vim.log.levels.ERROR)
        return
      end

      close()
      vim.notify(success_message:format(pane_id), vim.log.levels.INFO)
    end, function()
      pending = false
    end)
  end

  vim.keymap.set('n', '<CR>', function() submit(false) end, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set('n', '<S-CR>', function() submit(true) end, { buffer = buf, nowait = true, silent = true })
end

local function agent_message_popup()
  local width = math.min(100, math.floor(vim.o.columns * 0.8))
  local max_height = math.floor(vim.o.lines * 0.5)
  local height = math.max(math.min(10, max_height), 3)
  local buf, _, close = agent_text_float(' Agent message  (Enter type · Shift+Enter send · q close) ', width, height)

  agent_map_text_send(buf, close, 'No agent message to send', 'Sent message to %s')

  vim.cmd('startinsert')
end

local function review_send_preview()
  local out, n = review_build()
  if n == 0 then
    vim.notify('No review comments to send', vim.log.levels.WARN)
    return
  end

  local lines = vim.split(table.concat(out, '\n'), '\n', { plain = true })
  local nlines = #lines
  local width = math.min(140, math.floor(vim.o.columns * 0.9))
  local max_height = math.floor(vim.o.lines * 0.9)
  local height = math.max(math.min(nlines + 1, max_height), math.min(20, max_height))
  local buf, _, close = agent_text_float(' Review send  (Enter type · Shift+Enter send · q close) ', width, height)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  agent_map_text_send(buf, close, 'No review text to send', 'Sent review to %s')
end

-- Resolve the commit ref to review: the visual selection in any visual mode,
-- otherwise the word under the cursor (a hash/branch/tag in e.g. a git log).
local function review_target_ref()
  local mode = vim.fn.mode()
  local ref
  if mode == 'v' or mode == 'V' or mode == '\22' then
    local sel = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = mode })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'nx', false)
    ref = vim.trim(table.concat(sel, ' '))
  else
    ref = vim.trim(vim.fn.expand('<cword>'))
  end
  if ref == '' then
    vim.notify('Review: no commit ref under cursor/selection', vim.log.levels.WARN)
    return nil
  end
  return ref
end

-- "Review start commit": review only <ref>'s own content (base=<ref>^, head=<ref>).
local function review_start_commit()
  local ref = review_target_ref()
  if not ref then return end
  review_start(ref .. '^', false, ref)
end

-- "Review start range": review the whole span from <ref> through HEAD,
-- <ref> included (base=<ref>^, head=HEAD). Mirrors the old visual <leader>rs.
local function review_start_range()
  local ref = review_target_ref()
  if not ref then return end
  review_start(ref .. '^', false)
end

vim.keymap.set('n', '<LEADER>rC', review_add_general, { silent = true, desc = 'Review: general note' })
vim.keymap.set('n', '<LEADER>rc', review_add_normal, { silent = true, desc = 'Review: add comment' })
vim.keymap.set('v', '<LEADER>rc', review_add_visual, { silent = true, desc = 'Review: add comment (range)' })
vim.keymap.set('n', '<LEADER>rd', review_delete_at_cursor, { silent = true, desc = 'Review: delete comment at cursor' })
vim.keymap.set('n', '<LEADER>re', review_export, { silent = true, desc = 'Review: export comments to clipboard' })
vim.keymap.set('n', '<LEADER>rf', function() review_files(review_resolve_base(nil)) end, { silent = true, desc = 'Review: changed files to quickfix' })
vim.keymap.set('n', '<LEADER>rs', function() review_start() end, { silent = true, desc = 'Review: start session' })
vim.keymap.set({ 'n', 'v' }, '<LEADER>rsc', review_start_commit, { silent = true, desc = 'Review: start session for commit (just its content)' })
vim.keymap.set({ 'n', 'v' }, '<LEADER>rsr', review_start_range, { silent = true, desc = 'Review: start session for range (commit..HEAD)' })
vim.keymap.set('n', '<LEADER>rS', function() review_start(review_resolve_base('--uncommitted')) end, { silent = true, desc = 'Review: start session (uncommitted)' })
vim.keymap.set('n', '<LEADER>rX', review_clear, { silent = true, desc = 'Review: clear all comments' })
vim.keymap.set('n', '<LEADER>rQ', review_finish, { silent = true, desc = 'Review: finish (export + clear + signs off)' })
vim.keymap.set('n', '<LEADER>rp', review_preview, { silent = true, desc = 'Review: preview in float' })
vim.keymap.set('n', '<LEADER>rE', review_send_preview, { silent = true, desc = 'Review: send comments to Pop pane' })
vim.keymap.set('n', '<LEADER>as', agent_message_popup, { silent = true, desc = 'Agent: send message to Pop pane' })

-- :Review [start|finish|files] [<ref>|--uncommitted]
--   start  — begin a session against <ref> (default branch if omitted)
--   finish — export + clear + signs off
--   files  — quickfix-only, no session
local review_subcommands = { 'start', 'finish', 'files' }

vim.api.nvim_create_user_command('Review', function(opts)
  local sub = opts.fargs[1] or 'start'
  if sub == 'finish' then
    review_finish()
  elseif sub == 'start' then
    review_start(review_resolve_base(opts.fargs[2]))
  elseif sub == 'files' then
    review_files(review_resolve_base(opts.fargs[2]))
  else
    vim.notify('Review: unknown subcommand ' .. sub, vim.log.levels.WARN)
  end
end, {
  nargs = '*',
  desc = 'Local code review session (start/finish/files)',
  complete = function(arglead, cmdline, _)
    local args = vim.split(vim.trim(cmdline), '%s+')
    local function pick(cands)
      return vim.tbl_filter(function(s) return s:find(arglead, 1, true) == 1 end, cands)
    end
    -- Completing the subcommand (args = {'Review'} or {'Review', partial}).
    if #args <= 1 or (#args == 2 and arglead ~= '') then
      return pick(review_subcommands)
    end
    -- Completing the base spec for start/files.
    if args[2] == 'start' or args[2] == 'files' then
      local cands = { '--uncommitted' }
      vim.list_extend(cands, vim.fn.systemlist(
        'git for-each-ref --format="%(refname:short)" refs/heads refs/remotes refs/tags'))
      return pick(cands)
    end
    return {}
  end,
})

vim.api.nvim_create_user_command('ReviewClear', review_clear, { desc = 'Review: clear all comments' })

-- Re-render inline comments when a buffer is shown (e.g. after jumping via quickfix).
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('glebglazov-review-render', { clear = true }),
  callback = function(args)
    review_render_buf(args.buf)
  end,
})

-------------------------------------------------
-- Autogroups — QuickFix
-------------------------------------------------
autocmd('FileType', {
  group = augroup('glebglazov-quickfix-settings', {clear = true}),
  pattern = 'qf',
  callback = function ()
    vim.api.nvim_buf_set_keymap(0, '', 'dd', ':.Reject<cr>', { silent = true })
    -- on demand: float files with comments to the top (no longer automatic on add/delete)
    vim.keymap.set('n', 'gs', review_qf_sort, { buffer = 0, silent = true, desc = 'Review: sort commented files to top' })
    -- window-local statusline so the global REVIEW badge doesn't duplicate into qf
    vim.wo.statusline = ' %t%{exists("w:quickfix_title") ? " " . w:quickfix_title : ""} %=%-14(%l,%c%V%) %P'
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

local function git_relative_path(path)
  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if git_root and path:sub(1, #git_root) == git_root then
    return path:sub(#git_root + 2)
  end
  return path
end

local function yank_file_path_fn(opts)
  return function()
    opts = opts or {}
    local path_manipulation_fn = opts.path_manipulation_fn or function(path) return path end

    local path = path_manipulation_fn(vim.fn.expand('%:p'))
    vim.fn.setreg('+', path)
    print("Copied to clipboard: " .. path)
  end
end

-- Git-relative paths
vim.keymap.set('n', '<LEADER>fY', yank_file_path_fn({
  path_manipulation_fn = function(path)
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    return git_relative_path(path) .. ':' .. line_num
  end
}), { silent = true })
vim.keymap.set('n', '<LEADER>fy', yank_file_path_fn({
  path_manipulation_fn = git_relative_path
}), { silent = true })

-- Absolute paths
vim.keymap.set('n', '<LEADER>faY', yank_file_path_fn({
  path_manipulation_fn = function(path)
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    return path .. ':' .. line_num
  end
}), { silent = true })
vim.keymap.set('n', '<LEADER>fay', yank_file_path_fn(), { silent = true })

vim.keymap.set('v', '<LEADER>fY', function()
  local v_line = vim.fn.getpos('v')[2]
  local cursor_line = vim.fn.getpos('.')[2]
  local start_line = math.min(v_line, cursor_line)
  local end_line = math.max(v_line, cursor_line)

  local path = git_relative_path(vim.fn.expand('%:p'))
  local range_path = path .. ':' .. start_line .. '-' .. end_line

  vim.fn.setreg('+', range_path)
  print("Copied to clipboard: " .. range_path)
end, { silent = true })

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
