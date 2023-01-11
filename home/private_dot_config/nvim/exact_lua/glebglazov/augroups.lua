local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

GeneralGroup = augroup('General', { })
autocmd({ 'BufWritePre' }, {
	group = GeneralGroup,
	pattern = '*',
	command = '%s/\\s\\+$//e',
})

FugitiveGroup = augroup('Fugitive', {})
autocmd({ 'FileType' }, {
	group = FugitiveGroup,
	pattern = 'fugitive',
	command = 'nmap <buffer> <tab> =',
})
