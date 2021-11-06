call plug#begin('~/.vim/plugged')

Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }

Plug 'fatih/vim-go', { 'tag': '*' }
Plug 'tpope/vim-rails'

Plug 'tpope/vim-fugitive'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()
 
map <Space> <Leader>
nnoremap <Leader>s :w<CR>
nnoremap <Leader>g :G<CR>
nnoremap <Leader>f :GFiles<CR>
nnoremap <Leader>/ :Rg<CR>
