call plug#begin('~/.vim/plugged')

Plug 'christoomey/vim-system-copy'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-fugitive'
Plug 'iberianpig/tig-explorer.vim'

Plug 'fatih/vim-go', { 'tag': '*' }
Plug 'tpope/vim-rails'
Plug 'pangloss/vim-javascript'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }

Plug 'prettier/vim-prettier', {
      \ 'do': 'yarn install',
      \ 'for': ['javascript', 'css', 'scss', 'jsx', 'json', 'html'] }

Plug 'morhetz/gruvbox'
Plug 'vim-airline/vim-airline'

call plug#end()

colorscheme gruvbox
set background=dark

" Enable hybrid line numbers
set number relativenumber

" Allow to hide buffers which have changes
set hidden

" In order for "e" in normal mode to jump onto _ as well
set iskeyword-=_

let g:mapleader="\<space>"
let g:maplocalleader=","

" Insert mode bindings {{{
inoremap jk <esc>
" }}}

" Visual mode bindings {{{
vnoremap <leader>/ y:Rg<space><c-r>"<cr>
vnoremap # y/<c-r>"<cr>
" }}}

" Top-level bindings {{{
nnoremap <silent> <esc> :noh<cr>

nnoremap <silent> H ^
nnoremap <silent> J <c-d>
nnoremap <silent> K <c-u>
nnoremap <silent> <c-d> <nop>
nnoremap <silent> <c-u> <nop>
nnoremap <silent> L $

nnoremap <silent> <leader>/ :Rg<CR>

nnoremap <silent> <leader><tab> :b#<CR>
nnoremap <silent> [b :bp<CR>
nnoremap <silent> ]b :bn<CR>

nnoremap <silent> <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :so $MYVIMRC<CR>
" }}}

" Files bindings {{{
nnoremap <silent> <leader>fs :up<CR>
" }}}

" Git bindings {{{
nnoremap <silent> <leader>gg :G<CR>
nnoremap <silent> <leader>gbl :G blame<CR>
nnoremap <leader>gfo :G fetch origin<CR>
nnoremap <leader>gcp :G cherry-pick<space>
nnoremap <leader>grb :G rebase<space>
nnoremap <leader>gri :G rebase --interactive<space>
nnoremap <leader>gra :G rebase --abort<CR>
nnoremap <leader>grc :G rebase --continue<CR>
nnoremap <leader>grs :G reset --soft<space>
nnoremap <leader>grh :G reset --hard<space>
nnoremap <leader>gco :G checkout<space>
nnoremap <leader>gcb :G checkout -b<space>
nnoremap <silent> <leader>gt :TigOpenProjectRootDir<CR>
nnoremap <leader>glg :Gclog<space>
nnoremap <leader>gpl :G pull<CR>
nnoremap <leader>gpo :G push origin HEAD<CR>
nnoremap <leader>gpf :G push --force origin HEAD<CR>
nnoremap <leader>gps :G push origin HEAD:
" }}}

" Project bindings {{{

" Prevent vim-prettier to mess with project bindings
noremap <leader>p <nop>

nnoremap <leader>pp :cd ~/Dev/
nnoremap <silent> <leader>pf :GFiles<CR>
nnoremap <silent> <leader>pgs :cd ~/Dev/game_server<CR>
" }}}

" Applications bindings {{{
function MyNERDTreeOpenHere()
  if exists("g:NERDTree") && g:NERDTree.IsOpen()
    execute "NERDTreeToggle"
    execute "NERDTreeToggle %"
  else
    execute "NERDTreeToggle %"
  endif
endfunction

nnoremap <silent> <leader>ar :call MyNERDTreeOpenHere()<CR>
nnoremap <silent> <leader>af :NERDTreeFocus<CR>
" }}}

" Window bindings {{{
function! MaximizeToggle()
  if exists("s:maximize_session")
    exec "source " . s:maximize_session
    call delete(s:maximize_session)
    unlet s:maximize_session
    let &hidden=s:maximize_hidden_save
    unlet s:maximize_hidden_save
  else
    let s:maximize_hidden_save = &hidden
    let s:maximize_session = tempname()
    set hidden
    exec "mksession! " . s:maximize_session
    only
  endif
endfunction

nnoremap <silent> <leader>ws :sp<CR>
nnoremap <silent> <leader>wd :hide<CR>
nnoremap <silent> <leader>wS :sp <bar> :wincmd j<CR>
nnoremap <silent> <leader>wv :vsp<CR>
nnoremap <silent> <leader>wV :vsp <bar> :wincmd l<CR>
nnoremap <silent> <leader>wm :call MaximizeToggle()<CR>
nnoremap <silent> <leader>wp :wincmd p<CR>
nnoremap <silent> <leader>wh :wincmd h<CR>
nnoremap <silent> <leader>wj :wincmd j<CR>
nnoremap <silent> <leader>wk :wincmd k<CR>
nnoremap <silent> <leader>wl :wincmd l<CR>
" }}}

" General autogroup settings {{{
augroup my_general_group
  autocmd!
  autocmd! BufWritePre * :%s/\s\+$//e
augroup END
" }}}

" Vim FileType settings {{{
augroup my_vim_filetype
  autocmd!
  autocmd! FileType vim setlocal foldmethod=marker expandtab tabstop=2 shiftwidth=2
augroup END
" }}}

" Ruby FileType settings {{{
augroup my_ruby_filetype
  autocmd!
  autocmd FileType ruby :onoremap a i(
  autocmd FileType ruby :onoremap b /end<cr>
  autocmd FileType ruby :nnoremap <leader>rt :!rubocop -a %<cr>
  autocmd FileType ruby :onoremap cm :<c-u>execute "normal! ?def .*\r:nohlsearch\rf lvg_"<CR>
  autocmd FileType ruby :onoremap nm :<c-u>execute "normal! /def .*\r:nohlsearch\rf lvg_"<CR>
  autocmd FileType ruby :iabbrev bpr binding.pry
augroup END
" }}}

" Javascript FileType settings {{{
augroup my_javascript_filetype
  autocmd!
  autocmd FileType javascript setlocal expandtab tabstop=2 shiftwidth=2
augroup END
" }}}

" Fugitive FileType settings {{{
augroup my_fugitive_filetype
  autocmd!
  autocmd FileType fugitive :nmap <tab> =
augroup END
" }}}
