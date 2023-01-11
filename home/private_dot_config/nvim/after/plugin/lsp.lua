local lsp = require('lsp-zero')

lsp.preset('recommended')
lsp.set_preferences({
  set_lsp_keymaps = false,
  sign_icons = {}
})
lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
end)

lsp.setup()
