local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

GeneralGroup = augroup('General', { })
autocmd({ 'BufWritePre' }, {
	group = GeneralGroup,
	pattern = '*',
	command = '%s/\\s\\+$//e',
})

ShellGroup = augroup('Shell', {})
autocmd({ 'FileType' }, {
	group = ShellGroup,
	pattern = 'sh',
	command = 'setlocal expandtab tabstop=4 shiftwidth=4',
})

RubyGroup = augroup('Ruby', {})
autocmd({ 'FileType' }, {
	group = RubyGroup,
	pattern = 'ruby',
	command = 'setlocal expandtab tabstop=2 shiftwidth=2',
})

JsGroup = augroup('JS', {})
autocmd({ 'FileType' }, {
	group = JsGroup,
	pattern = 'javascript',
	command = 'setlocal expandtab tabstop=2 shiftwidth=2',
})

ReactGroup = augroup('React', {})
autocmd({ 'FileType' }, {
	group = JsGroup,
	pattern = 'javascriptreact',
	command = 'setlocal expandtab tabstop=2 shiftwidth=2',
})

LuaGroup = augroup('Lua', {})
autocmd({ 'FileType' }, {
	group = LuaGroup,
	pattern = 'lua',
	command = 'setlocal expandtab tabstop=2 shiftwidth=2',
})

FugitiveGroup = augroup('Fugitive', {})
autocmd({ 'FileType' }, {
	group = FugitiveGroup,
	pattern = 'fugitive',
	command = 'nmap <buffer> <tab> =',
})
