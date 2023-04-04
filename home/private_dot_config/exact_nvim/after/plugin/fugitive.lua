local nnoremap  = require('glebglazov.functions.remap').nnoremap

nnoremap('<LEADER>gg', function ()
  vim.cmd('G')
end)
nnoremap('<LEADER>gfo', ':G fetch origin<CR>')
nnoremap('<LEADER>gbl', ':G blame<CR>')
nnoremap('<LEADER>glg', ':Gclog<CR>')
nnoremap('<LEADER>gcp', ':G cherry-pick<SPACE>')
nnoremap('<LEADER>gcm', function ()
  local output = vim.fn.system('git branch -l')

  if string.find(output, 'master') then
    vim.cmd('G checkout master')
  else
    vim.cmd('G checkout main')
  end
end)
nnoremap('<LEADER>grb', ':G rebase<SPACE>')
nnoremap('<LEADER>gri', ':G rebase --interactive<SPACE>')
nnoremap('<LEADER>gra', ':G rebase --abort<CR>')
nnoremap('<LEADER>grc', ':G rebase --continue<CR>')
nnoremap('<LEADER>grs', ':G reset --soft<SPACE>')
nnoremap('<LEADER>grh', ':G reset --hard<SPACE>')
nnoremap('<LEADER>grv', ':G revert<SPACE>')
nnoremap('<LEADER>gco', ':G checkout<SPACE>')
nnoremap('<LEADER>gcb', ':G checkout -b<SPACE>')
nnoremap('<LEADER>gpl', ':G pull --rebase<CR>')
nnoremap('<LEADER>gpo', ':G push origin HEAD<CR>')
nnoremap('<LEADER>gpf', ':G push --force origin HEAD<CR>')
nnoremap('<LEADER>gpp', ':G push origin HEAD:')
nnoremap('<LEADER>gap', ':G commit --amend --no-edit | G push --force origin HEAD<CR>')
nnoremap('<LEADER>gf', ':G fetch<CR>')
