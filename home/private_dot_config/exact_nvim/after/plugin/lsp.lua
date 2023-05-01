local lsp = require('lsp-zero')
local cmp = require('cmp')
local telescope = require('telescope.builtin')
local nnoremap  = require('glebglazov.functions.remap').nnoremap
local configure = require('lspconfig')

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

configure.ruby_ls.setup({
  on_attach = function(client, buffer)
    local diagnostic_handler = function ()
      local params = vim.lsp.util.make_text_document_params(buffer)
      client.request(
        'textDocument/diagnostic',
        { textDocument = params } ,
        function(err, result)
          if err then
            local err_msg = string.format("ruby-lsp - diagnostics error - %s", vim.inspect(err))
            vim.lsp.log.error(err_msg)
          end
          if not result then return end
          vim.lsp.diagnostic.on_publish_diagnostics(
            nil,
            vim.tbl_extend('keep', params, { diagnostics = result.items }),
            { client_id = client.id }
          )
        end
      )
    end

    diagnostic_handler() -- to request diagnostics when attaching the client to the buffer

    local ruby_group = vim.api.nvim_create_augroup('ruby_ls', {clear = false})
    vim.api.nvim_create_autocmd(
      { 'BufEnter', 'BufWritePre', 'InsertLeave', 'TextChanged' },
      {
        buffer = buffer,
        callback = diagnostic_handler,
        group = ruby_group,
      }
    )
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

lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  nnoremap('gd', function() vim.lsp.buf.definition() end, opts)
  nnoremap('gr', telescope.lsp_references, opts)
end)

lsp.setup()
