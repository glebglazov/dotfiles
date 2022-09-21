local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

GeneralGroup = augroup('General', { })
autocmd({ 'BufWritePre' }, {
	group = GeneralGroup,
	pattern = '*',
	command = '%s/\\s\\+$//e',
})

RubyGroup = augroup('Ruby', {})
autocmd({ 'BufRead', 'BufNewFile' }, {
	group = RubyGroup,
	pattern = { '*.rb', 'Gemfile', 'Rakefile' },
	command = 'setlocal expandtab tabstop=2 shiftwidth=2',
})

JsGroup = augroup('JS', {})
autocmd({ 'BufRead', 'BufNewFile' }, {
	group = JsGroup,
	pattern = { '*.js' ,'*.jsx' },
	command = 'setlocal expandtab tabstop=2 shiftwidth=2',
})

LuaGroup = augroup('Lua', {})
autocmd({ 'BufRead', 'BufNewFile' }, {
	group = LuaGroup,
	pattern = '*.lua',
	command = 'setlocal expandtab tabstop=2 shiftwidth=2',
})
