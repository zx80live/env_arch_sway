" [plugins]
call plug#begin()

Plug 'joshdick/onedark.vim'

Plug 'airblade/vim-gitgutter'

call plug#end()


" [main]
set vb t_vb=
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set autoindent
set wildmenu
set mouse=a
set encoding=utf8
set ffs=unix,dos,mac " symbol of the next line
set nowrap

" [search]
set ignorecase
set smartcase
set hlsearch
set incsearch

" [clipboard]
"set clipboard=unnamed
set clipboard+=unnamedplus

" [keys]
:inoremap <C-v> <ESC>"+pa
:vnoremap <C-c> "+y

" [appearance]
"set termguicolors
set laststatus=2
set number
syntax on
"set cursorline
"set cursorcolumn
" hi CursorLine  cterm=NONE ctermbg=0F171F ctermfg=white guibg=darkred guifg=white
" hi CursorLine  cterm=NONE ctermbg=808080 ctermfg=white guibg=darkred guifg=white
let g:airline_powerline_fonts = 1
set t_Co=256
"  1 -> blinking block
"  2 -> solid block
"  3 -> blinking underscore
"  4 -> solid underscore
"  5 -> blinking vertical bar
"  6 -> solid vertical bar
let &t_SI = "\<Esc>[6 q" "insert mode
let &t_SR = "\<Esc>[3 q" "replace mode
let &t_EI = "\<Esc>[2 q" "normal mode

colorscheme onedark
