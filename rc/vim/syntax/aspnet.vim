" Vim syntax file
" Language:     ASP.NET pages with C#
" Maintainer:   Stacey Abshire <vim.3.sabshire@xoxy.net>
" Last Change:  $Id: aspnet.vim,v 1.0 2004/04/02 02:00:03 sabshire Exp $
" Filenames:    *.aspx,*.ascx,*.asmx
"
" CREDITS: Mark Feeney for the original.  I tweaked it to correctly
"          handle code in a DataBind region.
"

" Quit when a syntax file was already loaded
if version < 600
  syn clear
elseif exists("b:current_syntax")
  finish
endif

if !exists("main_syntax")
  let main_syntax = 'aspnet'
endif

syn include @aspnetAddCS $VIMRUNTIME/syntax/cs.vim
unlet b:current_syntax

"

if version < 600
  source <sfile>:p:h/html.vim
else
  runtime! syntax/html.vim
endif
unlet b:current_syntax


syn region csharpBlock matchgroup=aspnetCsharpDelim start=#<%=\?# end=#%># keepend containedin=ALL contains=@aspnetAddCS,csharpEnd
syn match csharpEnd #\<end\>#

let b:current_syntax = "aspnet"


