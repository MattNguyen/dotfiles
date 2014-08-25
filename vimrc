set nocompatible        " Must be first line

if filereadable(expand("~/.vimrc.plugins"))
    source ~/.vimrc.plugins
endif

filetype plugin indent on " Automatically detect file types.
set background=dark       " Assume a dark background
set t_co=256
syntax on                 " Syntax highlighting
set mouse=a               " Automatically enable mouse usage
set mousehide             " Hide the mouse cursor while typing
scriptencoding utf-8
set clipboard=unnamed,unnamedplus
autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" | lcd %:p:h | endif " Always switch to the current file directory
set virtualedit=onemore " Allow for cursor beyond last character
set history=1000        " Store a ton of history (default is 20)
set spell               " Spell checking on
set hidden              " Allow buffer switching without saving
colorscheme jellybeans
set iskeyword-=.        " '.' is an end of word designator
set iskeyword-=#        " '#' is an end of word designator
set iskeyword-=-        " '-' is an end of word designator

" Restore cursor to file position in previous editing session
function! ResCur()
   if line("'\"") <= line("$")
       normal! g`"
       return 1
   endif
endfunction

augroup resCur
   autocmd!
   autocmd BufWinEnter * call ResCur()
augroup END

set backup                     " Backups are nice ...
set backupdir=~/.vim/backups
set directory=~/.vim/backups
set undodir=~/.vim/backups
set undofile                   " So is persistent undo ...
set undolevels=1000            " Maximum number of changes that can be undone
set undoreload=10000           " Maximum number lines to save for undo on a buffer reload
set showmode                   " Display the current mode
set cursorline                 " Highlight current line
set ruler                      " Show the ruler
set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) " A ruler on steroids
" Status line
set laststatus=2
set statusline=%<%f\                       " Filename
set statusline+=%w%h%m%r                   " Options
set statusline+=\ %{fugitive#statusline()} " Git Hotness
set statusline+=\ [%ff/%Y]                 " Filetype
set statusline+=\ [%{getcwd()}]            " Current dir
set statusline+=%=%-14.(%l,%c%V%)\ %p%%    " Right aligned file nav info
set backspace=indent,eol,start             " Backspace for dummies
set linespace=0                            " No extra spaces between rows
set nu                                     " Line numbers on
set showmatch                              " Show matching brackets/parenthesis
set incsearch                              " Find as you type search
set hlsearch                               " Highlight search terms
set winminheight=0                         " Windows can be 0 line high
set ignorecase                             " Case insensitive search
set smartcase                              " Case sensitive when uc present
set wildmenu                               " Show list instead of just completing
set wildmode=list:longest,full             " Command <Tab> completion, list matches, then longest common part, then all.
set whichwrap=b,s,h,l,<,>,[,]              " Backspace and cursor keys wrap too
set scrolljump=5                           " Lines to scroll when cursor leaves screen
set scrolloff=3                            " Minimum lines to keep above and below cursor
set foldenable                             " Auto fold code
set list
set listchars=tab:›\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace
set nowrap                      " Do not wrap long lines
set autoindent                  " Indent at the same level of the previous line
set shiftwidth=4                " Use indents of 4 spaces
set expandtab                   " Tabs are spaces, not tabs
set tabstop=4                   " An indentation every four columns
set softtabstop=4               " Let backspace delete indent
set nojoinspaces                " Prevents inserting two spaces after punctuation on a join (J)
set splitright                  " Puts new vsplit windows to the right of the current
set splitbelow                  " Puts new split windows to the bottom of the current
autocmd FileType coffee,haskell,puppet,ruby,yml setlocal expandtab shiftwidth=2 softtabstop=2
set nospell
set clipboard=unnamed
set title
set visualbell

" Remappings
let mapleader = ','
inoremap jk <ESC>
noremap j gj
noremap k gk
nnoremap Y y$
nmap <silent> <leader>/ :nohlsearch<CR>
vnoremap < <gv
vnoremap > >gv
cmap w!! w !sudo tee % >/dev/null
map <Leader>= <C-w>=
map zl zL
map zh zH
:nnoremap <leader>daws :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl<CR>

" Airline Config
let g:airline_theme='jellybeans'
