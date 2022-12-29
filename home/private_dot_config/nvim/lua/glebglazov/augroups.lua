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
	command = 'setlocal expandtab tabstop=4 softtabstop=4 shiftwidth=4',
})

FugitiveGroup = augroup('Fugitive', {})
autocmd({ 'FileType' }, {
	group = FugitiveGroup,
	pattern = 'fugitive',
	command = 'nmap <buffer> <tab> =',
})
