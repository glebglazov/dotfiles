call plug#begin('~/.vim/plugged')

Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-fugitive'

Plug 'fatih/vim-go', { 'tag': '*' }
Plug 'tpope/vim-rails'

Plug 'yuezk/vim-js'
Plug 'maxmellon/vim-jsx-pretty'

Plug 'prettier/vim-prettier', {
			\ 'do': 'yarn install',
			\ 'for': ['javascript', 'css', 'scss', 'jsx', 'json', 'html', 'ruby'] }

call plug#end()

" Add relative numbers to lines
set relativenumber

" Uppercase from insert modes
inoremap <leader>tu <esc>bviwUi

" Remove highlighting in normal mode
nnoremap <silent> <esc> :noh<cr>
nnoremap <silent> H ^
nnoremap <silent> J <c-d>
nnoremap <silent> K <c-u>
nnoremap <silent> <c-d> <nop>
nnoremap <silent> <c-u> <nop>
nnoremap <silent> L $

let g:mapleader="\<space>"
let g:maplocalleader=","

" Global mappings setup {{{

" Top-level bindings
nnoremap <silent> <leader>/ :Rg<CR>

nnoremap <silent> <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <silent> <leader>sv :so $MYVIMRC<CR>

" Files bindings
nnoremap <silent> <leader>fs :w<CR>

" Git bindings
nnoremap <silent> <leader>gg :G<CR>

" Project bindings
nnoremap <silent> <leader>pf :GFiles<CR>

" Applications bindings
nnoremap <silent> <leader>ar :NERDTreeToggle<CR>

" Window bindings
nnoremap <silent> <leader>ws :sp<CR>
nnoremap <silent> <leader>wd :bd<CR>
"nnoremap <silent> <leader>wS :sp | :wincmd j<CR>
nnoremap <silent> <leader>wv :vsp<CR>
"nnoremap <silent> <leader>wV :vsp|:wincmd l<CR>
nnoremap <silent> <leader>wh :wincmd h<CR>
nnoremap <silent> <leader>wj :wincmd j<CR>
nnoremap <silent> <leader>wk :wincmd k<CR>
nnoremap <silent> <leader>wl :wincmd l<CR>
" }}}

" Vim FileType settings {{{
augroup my_vim_filetype 
	autocmd!
	autocmd! FileType vim setlocal foldmethod=marker
augroup END
" }}}

" Ruby FileType settings {{{
augroup my_ruby_filetype
	autocmd!
	autocmd FileType ruby :onoremap a i(
	autocmd FileType ruby :onoremap b /end<cr>
	autocmd FileType ruby :onoremap cm :<c-u>execute "normal! ?def .*\r:nohlsearch\rf lvg_"<CR>
	autocmd FileType ruby :onoremap nm :<c-u>execute "normal! /def .*\r:nohlsearch\rf lvg_"<CR>
augroup END
" }}} 

