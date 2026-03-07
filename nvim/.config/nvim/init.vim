""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Must Have
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"colorscheme solarized
" syntax on " syntax highlighting on
syntax enable
let g:solarized_termtrans = 1
"call togglebg#map("<F5>")

" Always use light
set background=light

let $PAGER=''

set colorcolumn=100

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible              " be iMproved, required
filetype off                  " required

"
" Re-install every time a Plug is added or removed
"
" open vim command prompt
"
" :PluginInstall
"
"
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Keep Plugin commands between vundle#begin/end.
" let Vundle manage Vundle
Plugin 'VundleVim/Vundle.vim'
"Plugin 'prettier/vim-prettier'
" Plugin 'Valloric/YouCompleteMe'
" Navigation (IDE frame)
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'itchyny/lightline.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-sensible'
Plugin 'justinmk/vim-sneak'
Plugin 'airblade/vim-gitgutter'
Plugin 'tpope/vim-surround'
Plugin 'dkprice/vim-easygrep'
Plugin 'editorconfig/editorconfig-vim'
"Plugin 'ctrlpvim/ctrlp.vim'
" visual undo list
Plugin 'sjl/gundo.vim'
" Plugin 'majutsushi/tagbar'
" markdown preview: opens browser with live reload when vim opens .md
"Plugin 'suan/vim-instant-markdown'
Plugin 'godlygeek/tabular'
" language tools
Plugin 'vim-syntastic/syntastic'
"Plugin 'millermedeiros/vim-esformatter'
Plugin 'digitaltoad/vim-pug'
" Plugin 'elzr/vim-json'
" Plugin 'SirVer/ultisnips'
"Plugin 'sheerun/vim-polyglot'
" plugins from http://vim-scripts.org/vim/scripts.html
Plugin 'node.js'
Plugin 'SuperTab'
" Git plugin not hosted on GitHub
" Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
Plugin 'neoclide/coc.nvim', {'branch': 'release'}
" Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" prettierInstall L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}
" TypeScript
Plugin 'leafgarland/typescript-vim'
" Vue.js
Plugin 'posva/vim-vue'
" Copy of the Official Apple Swift VIM Plugin
Plugin 'bumaociyuan/vim-swift'
" Ale, async language linting and syntax checking
Plugin 'dense-analysis/ale'
"Plugin 'file:///Users/adammork/.dotfiles/ale'
"
Plugin 'tpope/vim-unimpaired'

Plugin 'kkoomen/gfi.vim'
Plugin 'junegunn/fzf'
Plugin 'dyng/ctrlsf.vim'
Plugin 'pechorin/any-jump.vim'

Plugin 'prabirshrestha/asyncomplete.vim'
Plugin 'prabirshrestha/async.vim'
Plugin 'prabirshrestha/vim-lsp'
Plugin 'prabirshrestha/asyncomplete-lsp.vim'
"Plugin 'ryanolsonx/vim-lsp-swift'

Plugin 'elixir-editors/vim-elixir'
" post install (yarn install | npm install) then load plugin only for editing supported files
Plugin 'prettier/vim-prettier', {
    \ 'do': 'npm install',
    \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss'] }
" All of your Plugins must be added before the following line
call vundle#end()            " required
"
"

call plug#begin()
Plug 'mfussenegger/nvim-dap'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'Pocco81/dap-buddy.nvim'
Plug 'rcarriga/nvim-dap-ui'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'theHamsta/nvim-dap-virtual-text'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
Plug 'antoinemadec/FixCursorHold.nvim'
Plug 'nvim-neotest/neotest'
call plug#end()

filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
filetype plugin on

if executable('sourcekit-lsp')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'sourcekit-lsp',
        \ 'cmd': {server_info->['sourcekit-lsp']},
        \ 'whitelist': ['swift'],
        \ })
endif

" Ruby LSP
if executable('solargraph')
    " gem install solargraph
    au User lsp_setup call lsp#register_server({
        \ 'name': 'solargraph',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'solargraph stdio']},
        \ 'initialization_options': {"diagnostics": "true"},
        \ 'whitelist': ['ruby'],
        \ })
endif

let g:lsp_log_verbose = 1
let g:lsp_log_file = expand('~/vim-lsp.log')

" for asyncomplete.vim log
let g:asyncomplete_log_file = expand('~/asyncomplete.log')

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Telescope
"""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>


" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" set UTF-8 encoding
set enc=utf-8
set fenc=utf-8
set termencoding=utf-8
set history=1000 " How many lines of history to remember
set cf " enable error files and error jumping
" set clipboard+=unnamed " turns out I do like sharing windows clipboard
set ffs=unix,dos,mac " support all three, in this order
set viminfo+=! " make sure it can save viminfo
set isk+=_,$,@,%,# " none of these should be word dividers, so make them not be
set nosol " leave my cursor where it was
set pastetoggle=<F10>
imap kj <Esc> " make shift enter exit insert mode to normal mode, should make exiting faster because VIM isnt waiting for a key combination tied to <esc>
set shell=/bin/zsh
"set shell=/usr/local/bin/zsh

" Save file on double esc
map <Esc><Esc> :w<CR>

" Edit vimr configuration file
nnoremap <leader>confe :e $MYVIMRC<CR>
" Reload vims configuration file
nnoremap <leader>confr :source $MYVIMRC<CR>

" Search commands automatically center viewport
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" Search for text selected in visual mode
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Auto-Paste toggle
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor, Current Line
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif
autocmd InsertEnter * set cul
autocmd InsertLeave * set nocul

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Files/Backups/Sessions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set autoread
set nobackup
set nowb
set noswapfile
set directory=~/.vim/temp " directory for temp files
set makeef=error.err " When using make, where should it dump the file
set sessionoptions+=globals " What should be saved during sessions being saved
set sessionoptions+=localoptions " What should be saved during sessions being saved
set sessionoptions+=resize " What should be saved during sessions being saved
set sessionoptions+=winpos " What should be saved during sessions being saved

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim UI
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set lsp=0 " space it out a little more (easier to read)
set wildmenu " turn on wild menu
set wildmode=list:longest " turn on wild menu in special format (long format)
set wildignore=*.dll,*.o,*.obj,*.bak,*.exe,*.pyc,*.swp,*.jpg,*.gif,*.png " ignore formats
set ruler " Always show current positions along the bottom
set cmdheight=1 " the command bar is 1 high
set number " turn on line numbers

" turn hybrid line numbers on
set number relativenumber
set nu rnu


noremap <silent> <Leader>h :call ToggleHybridLine()<CR>
function ToggleHybridLine()
  " toggle hybrid line numbers
  set number! relativenumber!
  set nu! rnu!
endfunction


set lz " do not redraw while running macros (much faster) (LazyRedraw)
set hid " you can change buffer without saving
set backspace=2 " make backspace work normal
set whichwrap+=<,>,h,l  " backspace and cursor keys wrap to
set mouse=a " use mouse everywhere
set shortmess=atI " shortens messages to avoid 'press a key' prompt
set report=0 " tell us when anything is changed via :...
set noerrorbells " don't make noise
set list " we do what to show tabs, to ensure we get them out of my files
set listchars=tab:>-,trail:- " show tabs and trailing whitespace

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Visual Cues
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set showmatch " show matching brackets
set mat=5 " how many tenths of a second to blink matching brackets for
set nohlsearch " do not highlight searched for phrases
set incsearch " BUT do highlight as you type you search phrase
set so=5 " Keep 5 lines (top/bottom) for scope
set novisualbell " don't blink
" statusline example: ~\myfile[+] [FORMAT=format] [TYPE=type] [ASCII=000] [HEX=00] [POS=0000,0000][00%] [LEN=000]
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set laststatus=2 " always show the status line

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Indent Related
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set ai " autoindent (filetype indenting instead)
set nosi " smartindent (filetype indenting instead)
set cindent " do c-style indenting
set softtabstop=2 " unify
set shiftwidth=2 " unify
set tabstop=2 " real tabs should be 4, but they will show with set list on
set expandtab
set copyindent " but above all -- follow the conventions laid before us
" wrap lines at 120 chars. 80 is somewhat antiquated with nowadays displays.
"set textwidth=180
filetype plugin indent on " load filetype plugins and indent settings

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Text Formatting/Layout
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set fo=tcrq " See Help (complex)
set shiftround " when at 3 spaces, and I hit > ... go to 4, not 5
set expandtab " no real tabs!
set wrap linebreak nolist
"set nowrap " do not wrap line
set preserveindent " but above all -- follow the conventions laid before us
set ignorecase " case insensitive by default
set smartcase " if there are caps, go case-sensitive
set completeopt=menu,longest,preview " improve the way autocomplete works
set cursorcolumn " show the current column
set cursorline

" turn on spellcheck
autocmd BufRead,BufNewFile *.md setlocal spell
set spellfile=$HOME/.dotfiles/homedir/.vim/spell/en.utf-8.add

" Minimum 5 lines above or below the cursor
set scrolloff=5

" Make search results appear in the middle of the screen
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz

" hi CursorLine term=underline ctermbg=008 guibg=#493a35

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Folding
"    Enable folding, but by default make it act like folding is
"    off, because folding is annoying in anything but a few rare
"    cases
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set foldenable " Turn on folding
set foldmarker={,} " Fold C style code
set foldmethod=marker " Fold on the marker
set foldlevel=100 " Don't autofold anything (but I can still fold manually)
set foldopen-=search " don't open folds when you search into them
set foldopen-=undo " don't open folds when you undo stuff

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CTags
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"let Tlist_Ctags_Cmd = 'ctags' " Location of ctags
"let Tlist_Sort_Type = "name" " order by
"let Tlist_Use_Right_Window = 1 " split to the right side of the screen
"let Tlist_Compact_Format = 1 " show small meny
"let Tlist_Exist_OnlyWindow = 1 " if you are the last, kill yourself
"let Tlist_File_Fold_Auto_Close = 0 " Do not close tags for other files
"let Tlist_Enable_Fold_Column = 1 " Do show folding tree
"let Tlist_WinWidth = 50 " 50 cols wide, so I can (almost always) read my functions


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" lsp
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map \ld :LspDefinition<cr>
map \lr :LspReferences<cr>


map \[ <ESC>:bp<RETURN> " leader bracket (normal mode) switches buffers
map \] <ESC>:bn<RETURN> " leader bracket (normal mode) switches buffers


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Matchit
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let b:match_ignorecase = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Perl
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" let perl_extended_vars=1 " highlight advanced perl vars inside strings

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Custom Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select range, then hit :SuperRetab($width) - by p0g and FallingCow
function! SuperRetab(width) range
    silent! exe a:firstline . ',' . a:lastline . 's/\v%(^ *)@<= {'. a:width .'}/\t/g'
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Workaround for bd killing vim if nerdtree is open
nnoremap <Leader>d :bp<cr>:bd #<cr>

" quicker save
noremap <Leader>s :update<CR>
noremap <ESC><ESC> :update<CR>
" Convenience wrapper to open the buffer list
nnoremap gb :ls<CR>:b<Space>

" Make square brackets cycle to next and previous buffers

" Make control + hjkl jump to different VIM windows
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
let NERDTreeQuitOnOpen = 0
let NERDTreeNaturalSort = 1
" map <right> <ESC>:Tlist<RETURN> " show taglist
" map <left> <ESC>:NERDTreeToggle<RETURN>  " moves left fa split
" map <F2> <ESC>ggVG:call SuperRetab()<left>
" map <F12> ggVGg? " apply rot13 for people snooping over shoulder, good fun

map <Leader>exp yyp!!sh<CR><Esc>

" List all lowercase marks
nnoremap <silent> ,m :marks abcdefghijklmnopqrstuvwxyz<CR>:normal! `

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Useful abbrevs
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
iab xdate <c-r>=strftime("%d/%m/%y %H:%M:%S")<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
au BufRead,BufNewFile *.zcml set filetype=xml
au BufRead,BufNewFile *.rb,*.rhtml set tabstop=2
au BufRead,BufNewFile *.rb,*.rhtml set shiftwidth=2
au BufRead,BufNewFile *.rb,*.rhtml set softtabstop=2
au BufRead,BufNewFile *.otl set syntax=blockhl
au BufRead,BufNewFile *.json set syntax=javascript
au FileType python set omnifunc=pythoncomplete#Complete
au FileType javascript set omnifunc=javascriptcomplete#CompleteJS
au FileType html set omnifunc=htmlcomplete#CompleteTags
au FileType css set omnifunc=csscomplete#CompleteCSS
au FileType xml set omnifunc=xmlcomplete#CompleteTags
au FileType c set omnifunc=ccomplete#Complete
" autocmd vimenter * NERDTree

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change paging overlap amount from 2 to 5 (+3)
" if you swapped C-y and C-e, and set them to 2, it would
" remove any overlap between pages
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <C-b> <C-b>3<C-e> "  Make overlap 3 extra on control-b

" Yank text to the macOS clipboard
noremap <leader>y "*y
noremap <leader>yy "*Y
noremap yy "*y

" Preserve indentation while pasting text from the macOS clipboard
noremap <leader>p :set paste<CR>:put  *<CR>:set nopaste<CR>

" esformatter
" type \es to format
nnoremap <silent> <leader>es :Esformatter<CR>
vnoremap <silent> <leader>es :EsformatterVisual<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NERDTree
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:NERDTreeGitStatusLogLevel = 3

let NERDTreeShowHidden=1
let NERDTreeSortOrder=['\/$','*','[[-timestamp]]']
let NERDTreeIgnore=['\.DS_Store$']
" auto open if no file sent as arg
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" Toggle NERDtree with ,-n
map ,n <plug>NERDTreeTabsToggle<CR>
" Autoclose if only NERDtree is left
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
nnoremap <silent> <Leader>v :NERDTreeFind<CR>

let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ 'Ignored'   : '☒',
    \ "Unknown"   : "?"
    \ }

map ,nf :NERDTreeFind<CR>

" enable line numbers
let NERDTreeShowLineNumbers=1
" make sure relative line numbers are used
autocmd FileType nerdtree setlocal relativenumber

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NERDCommenter
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'elixir': { 'left': '#','right': '' } }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Syntastic
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_html_tidy_quiet_messages = { "level": "warnings" }
let g:syntastic_html_tidy_ignore_errors = [ '<template> is not recognized!' ]

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0
let g:syntastic_enable_eslint_checker = 1
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_enable_tslint_checker = 1
let g:syntastic_typescript_checkers = ['tslint', 'tsc']
let g:syntastic_enable_pug_checker = 1
let g:syntastic_pug_checkers = ['jade','pug']

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ale (VIM syntax linting, and fixing)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Set this variable to 1 to fix files when you save them.
let g:ale_fix_on_save = 1

" Enable completion where available.
" " This setting must be set before ALE is loaded.
let g:ale_completion_enabled = 1

" Keep gutter always open
let g:ale_sign_column_always = 1

" Signs
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '--'

" Finish color scheme later
"highlight ALEWarning ctermbg=Magenta

" In ~/.vim/vimrc, or somewhere similar.
let g:ale_fixers = {}
let g:ale_fixers.swift = []

"let g:ale_fixers.javascript = ['eslint']
"let g:ale_fixers['*'] = ['remove_trailing_lines', 'trim_whitespace']
"let g:ale_javascript_prettier_options = '--use-tabs'

" Do not lint or fix minified files.
let g:ale_pattern_options = {
\ '\.envrc': {'ale_linters': ['sh'], 'ale_fixers': []},
\}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Git Gutter
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

nmap ]h <Plug>GitGutterNextHunk
nmap [h <Plug>GitGutterPrevHunk

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ctrlP Vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"let g:ctrlp_show_hidden = 1
"let g:ctrlp_map = '<c-p>'
"let g:ctrlp_cmd = 'CtrlP'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" FZF
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" An action can be a reference to a function that processes selected lines
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Default fzf layout
" - down / up / left / right
let g:fzf_layout = { 'down': '~40%' }

" You can set up fzf window using a Vim command (Neovim or latest Vim 8 required)
let g:fzf_layout = { 'window': 'enew' }
let g:fzf_layout = { 'window': '-tabnew' }
let g:fzf_layout = { 'window': '10new' }

" Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

" Enable per-command history
" - History files will be stored in the specified directory
" - When set, CTRL-N and CTRL-P will be bound to 'next-history' and
"   'previous-history' instead of 'down' and 'up'.
let g:fzf_history_dir = '~/.local/share/fzf-history'

" Leader + o  opens a default FZFConfiguration.
nnoremap <silent> <expr> <Leader>o (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":FZFDefault\<cr>"
nnoremap <silent> <expr> <Leader>oa (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":FZFAllDefault\<cr>"
command! -nargs=*  FZFDefault :call fzf#run({'source': 'rg --hidden -l --ignore-file "/Users/adam/.vimfzfignore" ""', 'sink': 'e'})
command! -nargs=*  FZFAllDefault :call fzf#run({'source': 'rg --hidden -l ""', 'sink': 'e'})

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CtrlSF
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

nmap     \sf <Plug>CtrlSFPrompt
vmap     \sf <Plug>CtrlSFVwordPath
vmap     \sF <Plug>CtrlSFVwordExec
nmap     \sn <Plug>CtrlSFCwordPath
nmap     \sp <Plug>CtrlSFPwordPath
nnoremap \so :CtrlSFOpen<CR>
nnoremap \st :CtrlSFToggle<CR>
inoremap \st <Esc>:CtrlSFToggle<CR>


let g:ctrlsf_ackprg = '/opt/homebrew/bin/rg'
let g:ctrlsf_extra_backend_args = {
    \ 'rg': '--hidden -g "!.build/*" -g "!.git/*"', 
    \ }
let g:ctrlsf_position = 'bottom'
let g:ctrlsf_winsize = '50%'

let g:ctrlsf_auto_focus = {
    \ "at": "done",
    \ "duration_less_than": 500
    \ }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Instant Markdown
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"let g:instant_markdown_slow = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Other
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:sneak#streak = 1
"let g:airline_theme='bubblegum'
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ }

"Prettier"
"
let g:prettier#autoformat = 0
"autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue Prettier

nnoremap { gT
nnoremap } gt
nnoremap + :tabnew<CR>

" Wrap text in VIM
command! -nargs=* Wrap set wrap linebreak nolist

" https://stackoverflow.com/questions/20975928/moving-the-cursor-through-long-soft-wrapped-lines-in-vim
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'

noremap <silent> <Leader>w :call ToggleWrap()<CR>
function ToggleWrap()
  if &wrap
    echo "Wrap OFF"
    setlocal nowrap
  else
    echo "Wrap ON"
    setlocal wrap linebreak nolist
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Make default paste more useful
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"vnoremap p "_dP
xnoremap <expr> p 'pgv"'.v:register.'y'



""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COC Example VIMRC
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <C-d> for select selections ranges, needs server support, like: coc-tsserver, coc-python
"nmap <silent> <C-i> <Plug>(coc-range-select)
"xmap <silent> <C-i> <Plug>(coc-range-select)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

function! AddLastLine()
    if getline('$') !~ "^$"
        call append(line('$'), '')
    endif
endfunction

autocmd BufWritePre * call AddLastLine()
