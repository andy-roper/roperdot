" Many cues were drawn from:
" https://dougblack.io/words/a-good-vimrc.html

set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//

if $ROPERDOT_VI_COLOR_SCHEME == 'gruvbox' || $ROPERDOT_VI_COLOR_SCHEME =~ '^solarized light'
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
" let g:solarized_termcolors=256

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
