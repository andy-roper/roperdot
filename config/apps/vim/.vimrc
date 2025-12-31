" Many cues were drawn from:
" https://dougblack.io/words/a-good-vimrc.html

set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//

if $ROPERDOT_VI_COLOR_SCHEME == 'gruvbox light' || $ROPERDOT_VI_COLOR_SCHEME =~ '^solarized light'
	set background=light
else
	set background=dark
endif
if $ROPERDOT_VI_COLOR_SCHEME == 'hybrid'
	"let g:hybrid_custom_term_colors = 1
	colorscheme hybrid
elseif $ROPERDOT_VI_COLOR_SCHEME == 'monokai'
	colorscheme monokai
elseif $ROPERDOT_VI_COLOR_SCHEME =~ '^solarized'
	colorscheme solarized8
endif
if $ROPERDOT_VI_TERMGUICOLORS_SUPPORTED == 'true'
	set termguicolors
endif

let mapleader=","          " leader is comma instead of \

syntax on                  " Enable syntax highlighting
set showmatch              " Show matching brackets
set number                 " Show the line numbers
set formatoptions+=o       " Continue comment marker in new lines
set tabstop=4              " Render tabs with this many spaces
set softtabstop=4          " Number of spaces per tab when editing
set shiftwidth=4           " Indentation amount for < and > commands
set nostartofline          " Don't jump to first character with page commands
set nojoinspaces           " Prevent inserting two spaces after punctuation on a join (J)
set cursorline             " Highlight current line
set wildmenu               " Visual autocomplete for command menu
set lazyredraw             " Redraw only when necessary
set incsearch              " Search as characters are typed
set hlsearch               " Highlight matches
filetype plugin indent on  " Enable filetype detection, plugin and indent

" More natural splits
set splitbelow             " Horizontal split below current
set splitright             " Vertical split to right of current

" Folding
set foldenable             " enable folding
set foldlevelstart=10      " open most folds by default
set foldnestmax=10         " 10 nested fold max
" space open/closes folds
nnoremap <space> za
set foldmethod=indent      " fold based on indent level

if !&scrolloff
	set scrolloff=3      " Show next 3 lines while scrolling.
endif
if !&sidescrolloff
	set sidescrolloff=5  " Show next 5 columns while side-scrolling.
endif

set ignorecase           " Make searching case insensitive
set smartcase            " ... unless the query has capital letters
set gdefault             " Use 'g' flag by default with :s/foo/bar/

nnoremap <leader><space> :nohlsearch<CR>  " turn off search highlight
" Use <C-L> to clear the highlighting of :set hlsearch.
"if maparg('<C-L>', 'n') ==# ''
"    nnoremap <silent> <C-L> :nohlsearch<CR><C-L>
"endif

" Search and Replace
nmap <leader>s :%s//g<Left><Left>

" Relative numbering
function! NumberToggle()
	if(&relativenumber == 1)
		set nornu
		set number
	else
		set rnu
	endif
endfunc

" Toggle between normal and relative numbering.
nnoremap <leader>r :call NumberToggle()<cr>

nnoremap ; :    " Use ; for commands.
nnoremap Q @q   " Use Q to execute default register.

set rtp^=~/.vim/bundle/vim-airline
set rtp^=~/.vim/bundle/vim-airline-themes
let g:airline#extensions#tabline#enabled = 2

if !exists('g:airline_symbols')
let g:airline_symbols = {}
endif

" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" airline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''

let g:airline#extensions#tabline#fnamemod = ':t'

let g:airline_theme = 'solarized'
set rtp^="/usr/bin/fzf"
set rtp^=~/.vim/bundle/fzf.vim
set rtp^=~/.vim/bundle/vim-multiple-cursors
set rtp^=~/.vim/bundle/nerdtree
map <C-t> :NERDTreeToggle<CR>
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
let g:NERDTreeDirArrowExpandable = '>'
let g:NERDTreeDirArrowCollapsible = 'v'
set rtp^=~/.vim/bundle/vim-javascript
let g:javascript_plugin_jsdoc = 1
let g:javascript_plugin_ngdoc = 1
let g:javascript_plugin_flow = 1
augroup javascript_folding
au!
au FileType javascript setlocal foldmethod=syntax
augroup END
"let g:javascript_conceal_arrow_function = "⇒"
"set conceallevel=1
"map <leader>l :exec &conceallevel ? "set conceallevel=0" : "set conceallevel=1"<CR>
set rtp^=~/.vim/bundle/vim-node
let g:matchparen_timeout = 2
let g:matchparen_insert_timeout = 2
