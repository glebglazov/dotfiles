local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

EOLSpacesGroup = augroup('EOLSpacesGroup', { })
autocmd({ 'BufWritePre' }, {
	group = EOLSpacesGroup,
	pattern = '*',
	command = '%s/\\s\\+$//e',
})

EOFEmptyLinesGroup = augroup('EOFEmptyLinesGroup', { })
autocmd({ 'BufWritePre' }, {
	group = EOFEmptyLinesGroup,
	pattern = '*',
	command = '%s#\\($\\n\\s*\\)\\+\\%$##e',
})

FugitiveGroup = augroup('Fugitive', {})
autocmd({ 'FileType' }, {
	group = FugitiveGroup,
	pattern = 'fugitive',
	command = 'nmap <buffer> <tab> =',
})
