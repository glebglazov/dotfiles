call plug#begin('~/.vim/plugged')

Plug 'preservim/vimux'
Plug 'jgdavey/vim-turbux'
Plug 'christoomey/vim-system-copy'

Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-fugitive'

Plug 'hashivim/vim-terraform'
Plug 'fatih/vim-go', { 'branch': 'master' }
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'
Plug 'pangloss/vim-javascript'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
Plug 'slim-template/vim-slim'

Plug 'prettier/vim-prettier', {
      \ 'do': 'yarn install',
      \ 'for': ['javascript', 'css', 'scss', 'jsx', 'json', 'html'] }

Plug 'morhetz/gruvbox'
Plug 'vim-airline/vim-airline'
Plug 'easymotion/vim-easymotion'

Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'vim-voom/VOoM'

call plug#end()

let g:go_doc_keywordprg_enabled=0

colorscheme gruvbox
set background=dark

" Enable hybrid line numbers
set number relativenumber

" Allow to hide buffers which have changes
set hidden

let g:mapleader="\<space>"
let g:maplocalleader=","

" System copy plugin setup {{{
nmap zc <Plug>SystemCopy
nmap zyy <Plug>SystemCopyLine
nmap zp <Plug>SystemPaste

xmap zc <Plug>SystemCopy
xmap zv <Plug>SystemPaste

autocmd VimEnter * xunmap cv
autocmd VimEnter * xunmap cp
" }}}

" Top-level bindings {{{
nnoremap <silent> <esc> :noh<cr>
inoremap jk <esc>

vnoremap <leader>/ y:Rg<space><c-r>"<cr>
vnoremap # y/<c-r>"<cr>

nnoremap <silent> H ^
nnoremap <silent> L $
vnoremap <silent> H ^
vnoremap <silent> L $

nnoremap <silent> J <c-d>
nnoremap <silent> K <c-u>
vnoremap <silent> J <c-d>
vnoremap <silent> K <c-u>

nnoremap <silent> <leader>/ :Rg<CR>

nnoremap <silent> <leader><tab> :b#<CR>
nnoremap <silent> [b :bp<CR>
nnoremap <silent> ]b :bn<CR>

nnoremap <silent> <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :so $MYVIMRC<CR>

nnoremap <leader>vp :VimuxPromptCommand<CR>
nnoremap <leader>vl :VimuxRunLastCommand<CR>

nmap <leader>s <Plug>(easymotion-overwin-f2)
vmap <leader>s <Plug>(easymotion-s)
" }}}

" Text/Tab bindings {{{
nnoremap <silent> tm J
vnoremap <silent> tm J

nnoremap <leader>tn :tabnext<CR>
nnoremap <leader>tp :tabprev<CR>
nnoremap <leader>tt :tabnew<CR>
" }}}

" Files bindings {{{
nnoremap <silent> <leader>fs :up<CR>

function MyNERDTreeOpenHere()
  if exists("g:NERDTree") && g:NERDTree.IsOpen()
    execute "NERDTreeToggle"
    execute "NERDTreeToggle %"
  else
    execute "NERDTreeToggle %"
  endif
endfunction

nnoremap <silent> <leader>fl :call MyNERDTreeOpenHere()<CR>
nnoremap <silent> <leader>ff :NERDTreeFocus<CR>
nnoremap <silent> <leader>fc :NERDTreeClose<CR>
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
nnoremap <leader>glg :Gclog<space>
nnoremap <leader>gpl :G pull<CR>
nnoremap <leader>gpo :G push origin HEAD<CR>
nnoremap <leader>gpf :G push --force origin HEAD<CR>
nnoremap <leader>gpp :G push origin HEAD:
" }}}

" Project bindings {{{

" Prevent vim-prettier to mess with project bindings
noremap <leader>p <nop>

nnoremap <leader>pp :tcd ~/Dev/
nnoremap <silent> <leader>pf :GFiles<CR>
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

" Golang FileType settings {{{
augroup my_golang_filetype
  autocmd!
  autocmd FileType go :set tabstop=4
  autocmd FileType go :set shiftwidth=4
" }}}

" Fugitive FileType settings {{{
augroup my_fugitive_filetype
  autocmd!
  autocmd FileType fugitive :nmap <tab> =
augroup END
" }}}

" Focus function {{{
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_guifg = 'DarkGray'

let g:focused = 0
function! Focus()
  let g:focused = 1 - g:focused

  if g:focused == 1
    let b:coc_suggest_disable = 1
    :Goyo 120
    :Limelight
    :exe "normal \<C-w>\<C-w>"

    set noshowmode

    :nmap j jzz
    :nmap k kzz
    :nmap G Gzz
    :nmap J Jzz
    :vmap J Jzz
    :nmap K Kzz
    :vmap K Kzz

    :silent !tmux set status off
  else
    let b:coc_suggest_disable = 0
    :Goyo!
    :Limelight!

    set showmode

    :unmap j
    :unmap k
    :unmap G
    :nnoremap <silent> J <c-d>
    :nnoremap <silent> K <c-u>
    :vnoremap <silent> J <c-d>
    :vnoremap <silent> K <c-u>

    :silent !tmux set status on
  endif
endfunction

command Focus call Focus()
" }}}
