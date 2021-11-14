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

Plug 'liuchengxu/vim-which-key', { 'on': ['WhichKey', 'WhichKey!'] }

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
nnoremap <silent> <leader> :WhichKey '<space>'<CR>
let g:which_key_map={}

" Top-level bindings
nnoremap <silent> <leader>/ :Rg<CR>
" let g:which_key_map./ = 'find-text-in-project'

nnoremap <silent> <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <silent> <leader>sv :so $MYVIMRC<CR>

" Files bindings
let g:which_key_map.f = { 'name' : '+files' }
"
nnoremap <silent> <leader>fs :w<CR>
let g:which_key_map.f.s = 'save-file'

" Git bindings
let g:which_key_map.g = { 'name' : '+git' }

nnoremap <silent> <leader>gg :G<CR>

" Project bindings
let g:which_key_map.p = { 'name' : '+project' }

nnoremap <silent> <leader>pf :GFiles<CR>
let g:which_key_map.p.f = 'find-file-in-project'

" Applications bindings
let g:which_key_map.a = { 'name' : '+applications' }

nnoremap <silent> <leader>ar :NERDTreeToggle<CR>
let g:which_key_map.a.r = 'NERDTree'

" Window bindings
let g:which_key_map.w = { 'name' : '+window' }

nnoremap <silent> <leader>ws :sp<CR>
let g:which_key_map.w.s = 'split-below'

nnoremap <silent> <leader>wd :bd<CR>
let g:which_key_map.w.d = 'buffer-close-and-save'

"nnoremap <silent> <leader>wS :sp | :wincmd j<CR>
"let g:which_key_map.w.s = 'split-below-and-focus'

nnoremap <silent> <leader>wv :vsp<CR>
let g:which_key_map.w.v = 'split-right'

"nnoremap <silent> <leader>wV :vsp|:wincmd l<CR>
"let g:which_key_map.w.V = 'split-right-and-focus'

nnoremap <silent> <leader>wh :wincmd h<CR>
nnoremap <silent> <leader>wj :wincmd j<CR>
nnoremap <silent> <leader>wk :wincmd k<CR>
nnoremap <silent> <leader>wl :wincmd l<CR>
" Global mappings setup }}}

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

