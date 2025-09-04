" Add to your .vimrc - Terminal.app color compatibility
if $TERM_PROGRAM == 'Apple_Terminal'
    " Use 256-color mode instead of 24-bit
    set t_Co=256
    if exists('$VIM_COLOR_MODE') && $VIM_COLOR_MODE == '256color'
        " Use a colorscheme that works well in 256-color mode
        colorscheme desert  " or another Terminal.app-friendly scheme
        " Override specific colors that Terminal.app handles poorly
        highlight Normal ctermbg=NONE ctermfg=White
        highlight Directory ctermfg=Blue ctermbg=NONE
    endif
else
    " Full 24-bit color support for other terminals
    set termguicolors
    " Use your preferred colorscheme here
endif

" Force redraw after color changes
autocmd ColorScheme * redraw!
