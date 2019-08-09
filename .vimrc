" text / editing
" set textwidth=120
set wrapmargin=0
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set foldmethod=marker
set nofoldenable
" use these two together for pasting tabbed content when autoindent is enabled
" set autoindent
" set pastetoggle=<F2>

" display
set number
set laststatus=2
set statusline=
set statusline+=\ %f\ %m\ %r
set statusline+=%=
set statusline+=\ %v:%l/%L
set statusline+=\ 
syntax on
syntax enable
" not sure if this is necessary...
" " set t_Co=256
" colo koehler
set background=dark
set t_Co=256
colo slate
colo jellybeans

highlight GitGutterAdd    guifg=#009900 guibg=#000000 ctermfg=2 ctermbg=0
highlight GitGutterChange guifg=#bbbb00 guibg=#000000 ctermfg=3 ctermbg=0
highlight GitGutterDelete guifg=#ff2222 guibg=#000000 ctermfg=1 ctermbg=0
set updatetime=800

" searching
set hlsearch
set incsearch
set ignorecase

" fix mac backspace-vs-delete weirdness
set backspace=indent,eol,start

" perlcritic integration
"autocmd QuickFixCmdPost [^l]* nested cwindow
"autocmd QuickFixCmdPost    l* nested lwindow
"compiler perlcritic

"map <F5> :silent<space>make<space><cr>:redraw!<cr>
"map <F5> :silent<space>make<cr>:redraw!<cr>
map <F5> :!clear;python<space>%<cr>
map <F2> :colo<space>vividchalk<cr>

autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow
compiler shellcheck

highlight BadWhitespace ctermbg=Red
au BufRead,BufNewFile *.py match BadWhitespace /\s\+$/

" add yaml stuffs
au! BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml foldmethod=indent
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" transparent background
highlight Normal ctermbg=NONE
highlight CursorLine ctermbg=black
highlight Visual ctermbg=darkgrey
set cursorline
" end
