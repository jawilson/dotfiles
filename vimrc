filetype off
execute pathogen#infect()
execute pathogen#helptags()
filetype plugin indent on
syntax on

set t_Co=256

" Background, colorscheme, etc
set background=dark

" Airline config
let g:Powerline_symbols = "fancy"
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline_powerline_fonts = 1
let g:signify_vcs_list = [ 'git', 'svn' ]

" Ignore compatibility issues with Vi. Really don't know why ViM still defaults
" to this. Especially gViM.
set nocompatible

" General Options
set encoding=utf-8
set autoindent
set noshowmode
set showcmd
set hidden
set visualbell
set ttyfast
set ruler
set backspace=indent,eol,start
set number
set norelativenumber
set laststatus=2
set history=1000
set list
set listchars=tab:▸\ ,trail:·,extends:❯,precedes:❮
set shell=/bin/bash\ --login
set matchtime=3
set showbreak=↪
set splitbelow
set splitright
set fillchars=diff:⣿,vert:│
set autowrite
set autoread
set shiftround
"set title
set linebreak
set colorcolumn=+1
set modelines=5
set scrolloff=15

" Don't try to highlight lines longer than 800 characters.
set synmaxcol=800

" Time out on key codes but not mappings.
" Basically this makes terminal Vim work sanely.
set notimeout
set ttimeout
set ttimeoutlen=10

" Only shown when not in insert mode so I don't go insane.
augroup trailing
    au!
    au InsertEnter * :set listchars+=eol:¬
    au InsertLeave * :set listchars-=eol:¬
augroup END

" Turn plugin features on
set showmatch

" Spelling
if v:version >= 700
    set spelllang=en
    set spellfile=~/.vim/spellfile.add
endif

" Mouse options
"set mouse=a
"set mousemodel=popup

" Leader key remapping
let mapleader = ","
let maplocalleader = "\\"
map <leader><space> :noh<cr>

" Convenience mappings
" <ESC> is really far away
imap <c-d> <ESC>
nnoremap <c-d> <ESC>
vnoremap <c-d> <ESC>
cnoremap <c-d> <ESC>

" Toggle line numbers
nnoremap <leader>n :setlocal number!<cr>

" Enable tagbar
nnoremap <leader>t :TagbarToggle<cr>

" Tabs
nnoremap <leader>( :tabprev<cr>
nnoremap <leader>) :tabnext<cr>
nnoremap <leader>{ :tabnew<cr>

" Insert the directory of the current buffer in command line mode
cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'

" Toggle paste
" For some reason pastetoggle doesn't redraw the screen (thus the status bar
" doesn't change) while :set paste! does, so I use that instead.
" set pastetoggle=<F6>
nnoremap <F6> :set paste!<cr>


" Toggle [i]nvisible characters
nnoremap <leader>i :set list!<cr>

" Sudo to write
cnoremap w!! w !sudo tee % >/dev/null

" Spacing and tabbing
set expandtab
set smarttab
set softtabstop=4
set shiftwidth=4
set tabstop=4
set textwidth=100
set wrap
"set nowrap

" Filetype-specific formatting
set formatoptions+=t,c,r,o,n

au FileType c,cpp,h,hpp set cindent formatoptions+=ro tw=100
au FileType c set omnifunc=ccomplete#Complete tw=100
au FileType make set noexpandtab shiftwidth=8 tw=100
au FileType python set et sw=4 sts=4 ts=4 tw=100 ai
au FileType html,xhtml set tw=0
au FileType tex set spell tw=100
au BufRead,BufNewFile *.bb set tw=100
au BufRead,BufNewFile *.dox,*.dox.in set tw=100 filetype=doxygen spell
au Syntax {cpp,c,idl} runtime syntax/doxygen.vim

au BufRead,BufNewFile PKGBUILD set ts=4 sts=4 et sw=4
au BufNewFile,BufRead .Xdefaults* set filetype=xdefaults

" Command-mode completions
set wildmode=list:longest

" Folding
if has("folding")
    set foldenable
    set foldmethod=indent
    set foldlevel=100
    set foldopen-=search
    set foldopen-=undo
endif

hi Folded term=standout ctermfg=3 ctermbg=0

" Searching & Replacing
set nohlsearch
set ignorecase
set smartcase
set incsearch
runtime macros/matchit.vim

" Create parent directories if they do not exist
function s:MkNonExDir(file, buf)
    if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
        let dir=fnamemodify(a:file, ':h')
        if !isdirectory(dir)
            call mkdir(dir, 'p')
        endif
    endif
endfunction
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END

fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun
autocmd FileType c,cpp,java,php,ruby,python autocmd BufWritePre <buffer> :call <SID>StripTrailingWhitespaces()
