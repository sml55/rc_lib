" Vim syntax file
" Language:     Mason
" Filenames:    *.mas,*.do
"
" Quit when a syntax file was already loaded
if version < 600
  syn clear
elseif exists("b:current_syntax")
  finish
endif

if !exists("main_syntax")
  let main_syntax = 'mason'
endif

syn include @embPerl $VIMRUNTIME/syntax/perl.vim
unlet b:current_syntax

"

if version < 600
  source <sfile>:p:h/html.vim
else
  runtime! syntax/html.vim
endif
unlet b:current_syntax

" <%method>...</%method>
syn region masonMethodTag start=+<%+ end=+>+ contains=masonMethodTagN
syn region masonMethodEndTag start=+<\/%+ end=+>+ contains=masonMethodTagN
syn match  masonMethodTagN contained +</\s*[-a-zA-Z0-9]\++hs=s+2 contains=masonMethodTagName
syn keyword masonMethodTagName contained method

" <%init>...</%init>
syn region namedEmbPerlBlock matchgroup=namedEmbPerlDelim start=#<%\(perl\|flags\|once\|init\|args\)># end=#<\/%\(perl\|flags\|once\|init\|args\)># containedin=ALL contains=@embPerl,namedEmbPerlEnd
syn match namedEmbPerlEnd #\<end\>#

" <& ... &>
syn region masonCallBlock matchgroup=masonCallBlockDelim start=#<&.\+,# end=#&># containedin=ALL contains=@embPerl,masonCallBlockEnd
syn match masonCallBlockEnd #\<end\>#

" % ....
syn region embPerlLine matchgroup=embPerlLineDelim start=#^%# end=#$# keepend containedin=ALLBUT,namedEmbPerlBlock,masonCallBlock,embPerlStatement contains=@embPerl

" <% ... %>
syn region embPerlStatement matchgroup=embPerlStatementDelim start=#<%# end=#%># oneline keepend containedin=ALLBUT,namedEmbPerlBlock,embPerlLine contains=@embPerl,embPerlStatementEnd
syn match embPerlStatementEnd #\<end\>#

" redefine html endtag to avoid matching mason end tags 
syn region htmlEndTag start=+<\/[^%]+ end=+>+ contains=htmlTagN,htmlTagError
" Redefine htmlTag so that it can contain jspExpr
" syn region htmlTag start=+<[^/%]+ end=+>+ contains=htmlTagN,htmlString,htmlArg,htmlValue,htmlTagError,htmlEvent,htmlCssDefinition,@htmlPreproc,@htmlArgCluster


let b:current_syntax = "mason"


