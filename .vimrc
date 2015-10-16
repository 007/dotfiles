" text / editing
" set textwidth=120
set wrapmargin=0
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
"set foldmethod=marker
" use these two together for pasting tabbed content when autoindent is enabled
" set autoindent
" set pastetoggle=<F2>

" display
set number
set laststatus=2
set statusline=
set statusline+=\ %f\ %m\ %r
set statusline+=%=
set statusline+=%v:%l/%L
set statusline+=\ 
syntax on
syntax enable
" not sure if this is necessary...
" " set t_Co=256
" colo koehler
set background=dark
set t_Co=256
colo slate
colo vividchalk
" searching
set hlsearch
set incsearch
set ignorecase

" perlcritic integration
"autocmd QuickFixCmdPost [^l]* nested cwindow
"autocmd QuickFixCmdPost    l* nested lwindow
"compiler perlcritic

"map <F5> :silent<space>make<space><cr>:redraw!<cr>
map <F5> :silent<space>make<cr>:redraw!<cr>
map <F2> :colo<space>vividchalk<cr>
