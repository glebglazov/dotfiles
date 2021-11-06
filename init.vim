call plug#begin('~/.vim/plugged')

Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }

Plug 'fatih/vim-go', { 'tag': '*' }
Plug 'tpope/vim-rails'

Plug 'tpope/vim-fugitive'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()
