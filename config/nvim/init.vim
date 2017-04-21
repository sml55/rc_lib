"-----------------------------------------------------------------------------------------------------
"Options
"-----------------------------------------------------------------------------------------------------
execute pathogen#infect()
syntax on
filetype plugin indent on

syntax on       
set number "zeilennummern
set incsearch "schon bei eingabe anfangen zu suchen
set ruler<
set expandtab "lehrzeichen statt tabs
set tabstop =2 
set shiftwidth =2 
set hlsearch "suche hervorheben
set showmatch "anzeigen passender klammern etc
set wildmode=longest:list,full "completion on fileopening
set hidden "change buffer without saving
set smartcase "smart case insensitivity
set cindent
set smartindent
set autoindent
set spelllang=de,en     " Mehrere Sprachen
set spellsuggest=5      " Max NN Korrekturen vorschlagen
silent! set cryptmethod=blowfish
"set spell              " Rechtschreibprüfung für alle Dateien einschalten
au BufNewFile,BufRead *.md setlocal spell
"set foldmethod=syntax
set tags=tags

set rtp+=~/.fzf

set nobackup
set noswapfile
set nowritebackup


"------------------------------------------------------------------------------------------------------
"Mappings
"------------------------------------------------------------------------------------------------------
"

let mapleader = "^"


" remap j and k to scroll by visual lines not "physical" lines
nnoremap j gj
nnoremap k gk

" better ESC
inoremap jk <Esc>
inoremap kj <Esc>

" buffer traversal
nnoremap <C-P> :bp <CR>     "previous buffer
nnoremap <C-N> :bn <CR>     "next buffer

map <right> :bn<cr>
map <left> :bp<cr>

map <C-h> <C-w>h
map <C-l> <C-w>l
map <C-j> <C-w>j
map <C-k> <C-w>k

map <space> <PageDown>
map <S-space> <PageUp>

" since C-a is my prefix for tmux, i have to remap these
nn <C-i> <C-a>

" taglist
nnoremap <silent> <F7> :TagbarToggle<CR>
let g:tagbar_autofocus = 1

" vdebug
map <leader>b :Breakpoint <CR>

" nerdtree 
nnoremap <silent> <F8> :NERDTreeToggle <CR>

" hard times
map <F12> :HardTimeToggle <CR>

" coworker mode
"map <leader>c :Cw <CR>

" search function declarations
map <leader>f /function <CR>

"map F11 to run tests on php files
autocmd FileType inc,php map <F11> :! phpqa.sh % <CR>

" map F11 to run tests on Rails files
autocmd FileType rb nmap <F11> <Esc>:! ruby -c % 

" map <F5> to run mysql
autocmd FileType sql nmap <F5> <Esc>:w <CR>:! mysql -f < % <CR>

"insert todo item in github-markdown
autocmd FileType md imap <C-t> <Esc>I - [ ] <Esc>

"F9 runs current file
map <F9> :! % <CR>

"open current file in other editor
map <leader>e :!kate % <CR> :e <CR>

"tab movement
map <leader>t :tabn <CR>

"FZF
map <leader>o :FZF -m <CR>
"

tnoremap <leader><Esc> <C-\><C-n>

"denite
map <leader>g :Denite grep:.<CR>

"-----------------------------------------------------------------------------------------------------------
"Plugin config
"-----------------------------------------------------------------------------------------------------------

"CtrlP
"let g:ctrlp_map = '<c-o>' 
"let g:ctrlp_working_path_mode = 2
"let g:ctrlp_cache_dir = $HOME . '/.cache/ctrlp'
"let g:ctrlp_custom_ignore = 'Zend|Vendor'

"continue doxygen comments
autocmd FileType c,cpp set comments-=://
autocmd FileType c,cpp set comments+=:///
autocmd FileType c,cpp set comments+=://

"hard time
"let g:hardtime_default_on = 1
let g:list_of_visual_keys = [ "h", "j", "k", "l", "-", "+"]
let g:list_of_normal_keys = [ "h", "j", "k", "l", "-", "+"]

"vdebug
silent! let g:vdebug_options['break_on_open'] = 0

" explorer
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1

" nerd commenter
nnoremap <leader>c :call NERDComment(0,"toggle") <CR>


" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

"--------------------------------------------------------------------------------------------------------
" functions
"--------------------------------------------------------------------------------------------------------

function! MdPreview()
  :! markdown % > /tmp/md_preview.html && firefox  /tmp/md_preview.html
endfunction
command MdPreview call MdPreview()

function! FoldFunctions()
  :%g /function .* {.*$/ normal! $zf%
endfunction
command Fa call FoldFunctions()


"make vim noob friendly
function CoworkerMode()
:unmap <right>
:unmap <left>
:HardTimeOff
endfunction
command Cw call CoworkerMode()


"--------------------------------------------------------------------------------------------------------
"Misc
"--------------------------------------------------------------------------------------------------------


" Edit another file in the same directory as the current file
" " uses expression to extract path from current file's path
" " (thanks Douglas Potts)
 if has("unix")
   map ,e :e <C-R>=expand("%:p:h") . '/'<CR>
 else
   map ,e :e <C-R>=expand("%:p:h") . '\'<CR>
 endif
 

"pastemode with simple p
:command PM set paste
:command MP set nopaste

"-------------
"local
"-------------

if filereadable(glob("~/.vimrc.local")) 
  source ~/.vimrc.local
endif

