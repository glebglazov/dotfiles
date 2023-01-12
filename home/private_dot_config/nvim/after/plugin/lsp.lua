local lsp = require('lsp-zero')
local telescope = require('telescope.builtin')
local nnoremap  = require('glebglazov.functions.remap').nnoremap

lsp.preset('recommended')
lsp.set_preferences({
  set_lsp_keymaps = false,
  sign_icons = {}
})
lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  nnoremap('gd', function() vim.lsp.buf.definition() end, opts)
  nnoremap('gr', telescope.lsp_references, opts)
end)

lsp.setup()
