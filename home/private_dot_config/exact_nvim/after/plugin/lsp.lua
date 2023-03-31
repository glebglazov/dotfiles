local lsp = require('lsp-zero')
local cmp = require('cmp')
local telescope = require('telescope.builtin')
local nnoremap  = require('glebglazov.functions.remap').nnoremap

local cmp_sources = lsp.defaults.cmp_sources()
table.insert(cmp_sources, { name = 'copilot' })

lsp.preset('recommended')
lsp.set_preferences({
  set_lsp_keymaps = false,
  sign_icons = {}
})
lsp.setup_nvim_cmp({
  sources = cmp_sources,
  mapping = lsp.defaults.cmp_mappings({
    ['<CR>'] = cmp.mapping.confirm({
      -- Documentation says this is important.
      -- I don't know why.
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    })
  })
})
lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  nnoremap('gd', function() vim.lsp.buf.definition() end, opts)
  nnoremap('gr', telescope.lsp_references, opts)
end)

lsp.setup()
