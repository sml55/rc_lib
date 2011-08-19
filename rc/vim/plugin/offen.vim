function! Offen()
        let s:file = input("file: ")
        let s:x = findfile(s:file)
        echo s:x
"perl << EOF
"  	
"	VIM::Msg("searchstring: ");
"EOF
endfunction

command DoS  :call Offen() 


