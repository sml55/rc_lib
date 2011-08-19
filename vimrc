


" enable filetype plugin
filetype plugin on
filetype indent on

"searching

set hlsearch "Highlight search things
set showmatch "Show matching bracets when text indicator is over them

"display
syntax enable "Enable syntax hl
set ruler


"tabbing
set expandtab
set shiftwidth=4
set tabstop=4
set smarttab


"copy and paste
set clipboard+=unnamed " share windows clipboard

"taglist
let Tlist_WinWidth = 45 "breite
let Tlist_Exit_OnlyWindow = 1 "vim beenden wenn taglist letztes fenster
let Tlist_Use_Right_Window = 1 "taglist auf rechter seite
let Tlist_Sort_Type = "name" "nach namen sortieren
"else
set nocompatible " explicitly get out of vi-compatible mode
set foldenable


"explorer

let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1

" taglist
nnoremap <silent> <F7> :TlistToggle<CR>

" nerdtree 
nnoremap <silent> <F8> :NERDTreeToggle <CR>

" folding
:map <F5> <Esc>zf/end<cr>
:map <F6> <Esc>zo

" Rails
nmap <F11> <Esc>:! ruby -c % 
nmap <F12> <Esc>:Rake<cr>
imap <F12> <Esc>:w<cr>:Rake<cr>
"buffers"
map <C-h> :bp <CR>
map <C-l> :bn <CR> 

" Edit another file in the same directory as the current file
" " uses expression to extract path from current file's path
" " (thanks Douglas Potts)
 if has("unix")
   map ,e :e <C-R>=expand("%:p:h") . '/'<CR>
 else
   map ,e :e <C-R>=expand("%:p:h") . '\'<CR>
 endif
