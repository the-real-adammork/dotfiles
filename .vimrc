" kill vi compatibility
set nocompatible

" disable help mapping
nnoremap <F1> <nop>
inoremap <F1> <nop>
vnoremap <F1> <nop>

" TODO: organize these settings better!
set encoding=utf-8
set wildmenu
set wildmode=list:longest
set showcmd
set hidden
set ruler
set cursorline
set ttyfast

"set undofile


set smartindent
set number
"set relativenumber
set tabstop=4
syntax on
filetype plugin on
filetype indent on
set shiftwidth=4
set expandtab

set wildignore+=*/tmp/*,*.so,*.swp,*.zip   " Linux/MacOSX

" autoreload buffers
let autoreadargs={'autoread':1,'quiet':1}
au VimEnter * execute WatchForChanges("*",autoreadargs)


" filetypes

au BufNewFile,BufRead *.cljs setfiletype clojure
au BufNewFile,BufRead *.md setfiletype markdown
au BufNewFile,BufRead *.less setfiletype css

autocmd Filetype ruby setlocal ts=2 sw=2 expandtab

" tabs & buffers

map <leader>o :tabnew<CR>
map <leader>[ :tabprev<CR>
map <leader>] :tabnext<CR>
map <leader>w :bd<CR>

set showtabline=2


" splits

nnoremap <leader><bar> :rightb vert new<CR>
nnoremap <leader>_ :rightb new<CR>

nnoremap <leader><up> <C-w>k
nnoremap <leader><down> <C-w>j
nnoremap <leader><left> <C-w>h
nnoremap <leader><right> <C-w>l

" ctrl-t

let g:ctrlp_map = '<leader>p'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 2
let g:ctrlp_custom_ignore = '\.git$\|\.hg$\|\.svn$'

" mapping enter and shift enter to newline without insert mode

nnoremap <S-CR> O<Esc>
nnoremap <CR> o<Esc>

" mapping to quick no indent

nnoremap <C-p> :set invpaste paste?<CR>
set pastetoggle=<C-p>
set showmode

" reselect pasted text
nnoremap <leader>v V`]

" matching of brackets, if else, etc
runtime macros/matchit.vim

" better buffers
set hidden

" better completion
set wildmode=list:longest
let g:SuperTabDefaultCompletionType = "context"

" snipmate
let g:snips_author = 'Kenneth Ballenegger'

" clang osx
let sdk_path = 'echo -n `ls /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs | head -1`'
let g:clang_complete_copen = 1
autocmd FileType objc let g:clang_use_library=1
autocmd FileType objc let g:clang_user_options = '-fblocks -isysroot ' . sdk_path . ' -D__IPHONE_OS_VERSION_MIN_REQUIRED=40300'


" scroll by three lines when cursor moves off screen
set scrolloff=3

" swap files location
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp

" scroll viewport faster
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>

" backspace bullshit
set backspace=indent,eol,start

" better search

nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault

" ack \a
nnoremap <leader>a :Ack<space>
nmap <C-a> <Plug>ToggleAutoCloseMappings



" vlj
let vimclojure#HighlightBuiltins=1
let vimclojure#ParenRainbow=1

" disable arrow keys

nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
nnoremap j gj
nnoremap k gk


" fix arrow keys in tmux

nnoremap <Esc>A <nop>
nnoremap <Esc>B <nop>
nnoremap <Esc>C <nop>
nnoremap <Esc>D <nop>
inoremap <Esc>A <nop>
inoremap <Esc>B <nop>
inoremap <Esc>C <nop>
inoremap <Esc>D <nop>

" copy to os x pasteboard
vmap <C-c> :w !pbcopy<CR>

" Make Vim to handle long lines nicely.
set wrap
set textwidth=79
set formatoptions=qrn1

" color scheme
let g:solarized_termcolors=256
set background=dark
colorscheme solarized

" nmap <F8> :TagbarToggle<CR> 
nnoremap <leader>t :TagbarToggle<CR> 
"au BufNewFile,BufRead * TagbarToggle

" gist settings
let g:gist_clip_command = 'pbcopy'
let g:gist_detect_filetype = 1
let g:gist_show_privates = 1
let g:gist_post_private = 1
let g:gist_get_multiplefile = 1
nnoremap <Leader>s :Gist<space>


" uppercase word in insert mode
inoremap <m-u> <esc>viwUea


" enable pathogen
call pathogen#infect()

