" Turn on syntax highlighting
syntax on

" Background, colorscheme, etc
set background=dark

" Utility features
set ruler
set number
"set cursorline
set history=1000
set hidden
set title
set scrolloff=15
set visualbell

" Set the terminal font encoding
set encoding=utf-8
set termencoding=utf-8

" Turn plugin features on
filetype on
filetype plugin on
filetype indent on
set autoindent
set showmatch

" Spelling
if v:version >= 700
    set spelllang=en
    set spellfile=~/.vim/spellfile.add
endif

" Mouse options
"set mouse=a
"set mousemodel=popup

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
au FileType yaml set et sw=2 sts=2 ts=2 tw=100 ai
au FileType html,xhtml set tw=0
au FileType tex set spell tw=100
au BufRead,BufNewFile *.bb set tw=100
au BufRead,BufNewFile *.dox,*.dox.in set tw=100 filetype=doxygen spell
au Syntax {cpp,c,idl} runtime syntax/doxygen.vim

au BufRead,BufNewFile PKGBUILD set ts=4 sts=4 et sw=4
au BufNewFile,BufRead .Xdefaults* set filetype=xdefaults

" Key mappings
nnoremap <silent> <F7> :Explore<CR>
"map <silent> <F7> :TMiniBufExplorer<CR>
"nnoremap <silent> <F8> :TlistToggle<CR>
nnoremap <F8> :setl noai nocin nosi inde=<CR>
nnoremap <silent> <F9> :tabnew<CR>
nnoremap <silent> <F10> :tabp<CR>
nnoremap <silent> <F11> :tabn<CR>
nnoremap ` '
nnoremap ' `
nnoremap <C-e> 5<C-e>
nnoremap <C-y> 5<C-y>
"---------------- <F12> mapped by project flag 'g'

" Map ,s to show whitespace
set listchars=tab:>-,trail:·,eol:$
nmap <silent> <leader>s :set nolist!<CR>

" Status line settings
set laststatus=2
set statusline=%-3.3n\ %f%(\ %r%)%(\ %#WarningMsg#%m%0*%)%=(%l,\ %c)\ %P\ [%{&encoding}:%{&fileformat}]%(\ %w%)\ %y\
set shortmess+=aI

hi StatusLine term=inverse cterm=NONE ctermfg=white ctermbg=black
hi StatusLineNC term=none cterm=NONE ctermfg=darkgray ctermbg=black

" Command-mode completions
set wildmode=list:longest

" Intuitive backspacing in insert mode
set backspace=indent,eol,start

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

" Taglist settings
let Tlist_Process_File_Always = 1
let Tlist_Auto_Highlight_Tag = 1
let Tlist_Auto_Update = 1
let Tlist_Enable_Fold_Column = 1
let Tlist_Highlight_Tag_On_BufEnter = 1
let Tlist_Max_Tag_Length = 35
let Tlist_Use_Right_Window = 1
let Tlist_Inc_Winwidth = 0
let Tlist_WinWidth = 40

" OmniCPPComplete settings
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_NamespaceSearch = 1
let OmniCpp_DisplayMode = 1
let OmniCpp_ShowScopeInAbbr = 0
let OmniCpp_ShowPrototypeInAbbr = 0
let OmniCpp_ShowAccess = 1
let OmniCpp_DefaultNamespaces = ["std"]
let OmniCpp_MayCompleteDot = 1
let OmniCpp_MayCompleteArrow = 1
let OmniCpp_MayCompleteScope = 0
let OmniCpp_SelectFirstItem = 0

" Project plugin settings
let g:proj_flags = 'imstgLST'
let g:proj_window_width = 30

" SuperTab plugin settings
let g:SuperTabDefaultCompletionType = "<C-P>"
let g:SuperTabRetainCompletionType = 1
let g:SuperTabMappingForward = '<s-tab>'
let g:SuperTabMappingBackward = '<s-c-tab>'
