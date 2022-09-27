local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

GeneralGroup = augroup('General', { })
autocmd({ 'BufWritePre' }, {
	group = GeneralGroup,
	pattern = '*',
	command = '%s/\\s\\+$//e',
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
