" =============================================================================
" File:          autoload/ctrlp.vim
" Description:   Full path fuzzy file and buffer finder for Vim.
" Author:        Kien Nguyen <github.com/kien>
" License:       MIT
" =============================================================================

if v:version < '700' "{{{
	func! ctrlp#init(...)
		echoh Error | ec 'CtrlP requires Vim 7.0+' | echoh None
	endfunc
	fini
endif "}}}

" Option variables {{{
if !exists('g:ctrlp_match_window_reversed')
	let s:mwreverse = 1
else
	let s:mwreverse = g:ctrlp_match_window_reversed
	unl g:ctrlp_match_window_reversed
endif

if !exists('g:ctrlp_persistent_input')
	let s:pinput = 1
else
	let s:pinput = g:ctrlp_persistent_input
	unl g:ctrlp_persistent_input
endif

if !exists('g:ctrlp_split_window')
	let s:splitwin = 0
else
	let s:splitwin = g:ctrlp_split_window
	unl g:ctrlp_split_window
endif

if !exists('g:ctrlp_update_delay')
	let s:udelay = 500
else
	let s:udelay = g:ctrlp_update_delay
	unl g:ctrlp_update_delay
endif

if !exists('g:ctrlp_ignore_space')
	let s:igspace = 1
else
	let s:igspace = g:ctrlp_ignore_space
	unl g:ctrlp_ignore_space
endif

if !exists('g:ctrlp_working_path_mode')
	let s:pathmode = 1
else
	let s:pathmode = g:ctrlp_working_path_mode
	unl g:ctrlp_working_path_mode
endif

if !exists('g:ctrlp_max_height')
	let s:mxheight = 10
else
	let s:mxheight = g:ctrlp_max_height
	unl g:ctrlp_max_height
endif

if !exists('g:ctrlp_regexp_search')
	let s:regexp = 0
else
	let s:regexp = g:ctrlp_regexp_search
	unl g:ctrlp_regexp_search
endif

if !exists('g:ctrlp_use_caching')
	let s:caching = 0
else
	let s:caching = g:ctrlp_use_caching
	unl g:ctrlp_use_caching
endif

if !exists('g:ctrlp_cache_dir')
	let s:cache_dir = $HOME
else
	let s:cache_dir = g:ctrlp_cache_dir
endif

if !exists('g:ctrlp_newcache')
	let g:ctrlp_newcache = 0
endif

if !exists('g:ctrlp_by_filename')
	let s:byfname = 0
else
	let s:byfname = g:ctrlp_by_filename
	unl g:ctrlp_by_filename
endif

if !exists('g:ctrlp_prompt_mappings')
	let s:urprtmaps = 0
else
	let s:urprtmaps = g:ctrlp_prompt_mappings
	unl g:ctrlp_prompt_mappings
endif
"}}}

" Clear caches {{{
func! ctrlp#clearcache()
	let g:ctrlp_newcache = 1
endfunc

func! ctrlp#clearallcaches()
	let cache_dir = ctrlp#utils#cachedir()
	if isdirectory(cache_dir) && match(cache_dir, '.ctrlp_cache') >= 0
		let cache_files = split(globpath(cache_dir, '*.txt'), '\n')
		cal filter(cache_files, '!isdirectory(v:val)')
		try
			for each in cache_files | cal delete(each) | endfor
		catch
			echoh Error | ec 'Can''t delete cache files' | echoh None
		endtry
	else
		echoh Error | ec 'Caching directory not found. Nothing to delete.' | echoh None
	endif
	cal ctrlp#clearcache()
endfunc
"}}}

" ListAllFiles {{{
func! s:List(dirs, allfiles)
	" note: wildignore is ignored when using **
	let entries      = split(globpath(a:dirs, '*'), '\n')
	let entries_copy = deepcopy(entries)
	let alldirs      = filter(entries, 'isdirectory(v:val)')
	let allfiles     = filter(entries_copy, '!isdirectory(v:val)')
	cal extend(allfiles, a:allfiles, 0)
	if empty(alldirs)
		let s:allfiles = allfiles
	else
		let dirs = join(alldirs, ',')
		cal s:progress(allfiles)
		cal s:List(dirs, allfiles)
	endif
endfunc

func! s:ListAllFiles(path)
	let cache_file = ctrlp#utils#cachefile()
	if g:ctrlp_newcache || !filereadable(cache_file) || !s:caching
		" get the files
		cal s:List(a:path, [])
		let allfiles = s:allfiles
		unl s:allfiles
		" remove base directory
		let path = &ssl || !exists('+ssl') ? getcwd().'/' : substitute(getcwd(), '\', '\\\\', 'g').'\\'
		cal map(allfiles, 'substitute(v:val, path, "", "g")')
		let read_cache = 0
	else
		let allfiles = ctrlp#utils#readfile(cache_file)
		let read_cache = 1
	endif
	if len(allfiles) <= 3000 | cal sort(allfiles, 's:compare') | endif
	" write cache
	if !read_cache &&
				\ ( ( g:ctrlp_newcache || !filereadable(cache_file) )
				\ && s:caching || len(allfiles) > 4000 )
		if len(allfiles) > 4000 | let s:caching = 1 | endif
		cal ctrlp#utils#writecache(allfiles)
	endif
	retu allfiles
endfunc
"}}}

func! s:ListAllBuffers() "{{{
	let allbufs = []
	for each in range(1, bufnr('$'))
		if getbufvar(each, '&bl')
			let bufname = bufname(each)
			if strlen(bufname) && getbufvar(each, '&ma') && bufname != 'ControlP'
				cal add(allbufs, fnamemodify(bufname, ':p'))
			endif
		endif
	endfor
	retu allbufs
endfunc "}}}

func! s:SplitPattern(str,...) "{{{
	" Split into a list, ignoring spaces
	if s:igspace
		let str = substitute(a:str, ' ', '', 'g')
	endif
	if s:regexp || match(str, '[*^$+|]') >= 0
				\ || match(str, '\\\(zs\|ze\|<\|>\)') >= 0
		let str = substitute(str, '\\\\', '\', 'g')
		let array = [str]
		if match(str, ':\d*$') >= 0 " If pattern contains :\d (e.g. abc:25)
			let s:jmpln = matchstr(str, ':\d*$')
			let array[0] = substitute(array[0], ':\d*$', '', 'g')
		endif
	elseif match(str, ':\d*$') >= 0 " If string contains :\d
		let tmp = split(str, ':\ze\d*$')
		let array = split(tmp[0], '\zs')
		if len(tmp) >= 2
			cal add(array, ':'.tmp[1])
		endif
	else
		let array = split(str, '\zs')
	endif
	" Build the new pattern
	let nitem = !empty(array) ? array[0] : ''
	let newpats = [nitem]
	if len(array) > 1
		for i in range(1, len(array) - 1)
			" Separator
			let sp = exists('a:1') ? a:1 : '.\{-}'
			let nitem .= sp.array[i]
			cal add(newpats, nitem)
		endfor
	endif
	retu newpats
endfunc "}}}

func! s:GetMatchedItems(items, pats, limit) "{{{
	let items = a:items
	let pats  = a:pats
	let limit = a:limit
	" if pattern contains line number
	if match(pats[-1], ':\d*$') >= 0
		if exists('s:jmpln') | unl s:jmpln | endif
		let s:jmpln = substitute(pats[-1], '.*\ze:\d*$', '', 'g')
		cal remove(pats, -1)
	endif
	" if items is longer than 2000, use only the last pattern
	if len(items) >= 2000
		let pats = [pats[-1]]
	endif
	" loop through the patterns
	for each in pats
		if exists('newitems') && len(newitems) < limit
			let items = newitems
		endif
		if empty(items)
			retu exists('newitems') ? newitems : []
		else
			let newitems = []
			" loop through the items
			for item in items
				if s:byfname
					if s:matchsubstr(item, each) >= 0 | cal add(newitems, item) | endif
				else
					if match(item, each) >= 0 | cal add(newitems, item) | endif
				endif
				" stop if reached the limit
				if a:limit > 0 && len(newitems) == limit | break | endif
			endfor
		endif
	endfor
	retu newitems
endfunc "}}}

func! s:SetupBlank() "{{{
	setf ctrlp
	setl bt=nofile
	setl bh=delete
	setl noswf
	setl nobl
	setl ts=4
	setl sw=4
	setl sts=4
	setl nonu
	setl nowrap
	setl nolist
	setl nospell
	setl cul
	setl nocuc
	setl tw=0
	setl wfw
	if v:version >= '703'
		setl nornu
		setl noudf
		setl cc=0
	endif
	redr
endfunc "}}}

func! s:BufOpen(...) "{{{
	" a:1 bufname; a:2 delete
	let buf = a:1
	let bufnum = bufnr(buf)
	" Closing
	if bufnum > 0 && bufwinnr(bufnum) > 0
		exe bufwinnr(bufnum).'winc w'
		exe 'winc c'
	endif
	if exists('a:2')
		" Restore the changed global options
		exe 'let &magic=' . s:CtrlP_magic
		exe 'let &to='    . s:CtrlP_to
		exe 'se tm='      . s:CtrlP_tm
		exe 'let &sb='    . s:CtrlP_sb
		exe 'let &hls='   . s:CtrlP_hls
		exe 'let &im='    . s:CtrlP_im
		exe 'se report='  . s:CtrlP_report
		exe 'let &sc='    . s:CtrlP_sc
		exe 'se ss='      . s:CtrlP_ss
		exe 'se siso='    . s:CtrlP_siso
		exe 'let &ea='    . s:CtrlP_ea
		exe 'let &ut='    . s:CtrlP_ut
		exe 'se gcr='     . s:CtrlP_gcr
		exe s:currwin.'winc w'
		ec
	else
		let s:currwin = winnr()
		" Open new buffer
		exe 'sil! botright 1new' buf
		" Store global options
		let s:CtrlP_magic  = &magic
		let s:CtrlP_to     = &to
		let s:CtrlP_tm     = &tm
		let s:CtrlP_sb     = &sb
		let s:CtrlP_hls    = &hls
		let s:CtrlP_im     = &im
		let s:CtrlP_report = &report
		let s:CtrlP_sc     = &sc
		let s:CtrlP_ss     = &ss
		let s:CtrlP_siso   = &siso
		let s:CtrlP_ea     = &ea
		let s:CtrlP_ut     = &ut
		let s:CtrlP_gcr    = &gcr
		if !exists('g:CtrlP_prompt') || !s:pinput
			let g:CtrlP_prompt = ['', '', '']
		endif
		se magic
		se to
		se tm=0
		se sb
		se nohls
		se noim
		se report=9999
		se nosc
		se ss=0
		se siso=0
		se noea
		exe 'se ut='.s:udelay
		se gcr=a:block-PmenuSel-blinkon0
	endif
endfunc "}}}

func! s:Renderer(lines) "{{{
	let nls = []
	for i in range(0, len(a:lines) - 1)
		let nls = add(nls, '> '.a:lines[i])
	endfor
	" Detemine/set max height
	let height = s:mxheight
	let max = len(nls) < height ? len(nls) : height
	exe 'res' max
	" Output to buffer
	if len(nls) >= 1
		setl cul
		cal sort(nls, 's:compare')
		if s:mwreverse
			cal reverse(nls)
		endif
		cal setline('1', nls)
		if s:mwreverse
			keepj norm! G
		else
			keepj norm! gg
		endif
		keepj norm! 1|
		let b:matched = nls
	else
		" If empty
		setl nocul
		cal setline('1', ' == NO MATCHES ==')
	endif
	" Remember selected line
	if exists('g:CtrlP_cline')
		cal setpos('.', [0, g:CtrlP_cline, 1, 0])
	endif
endfunc "}}}

func! s:UpdateMatches(pat) "{{{
	" Delete the buffer's content
	sil! %d _
	let newpat = s:SplitPattern(a:pat)
	let lines  = s:GetMatchedItems(s:lines, newpat, s:mxheight)
	cal s:Renderer(lines)
endfunc "}}}

func! s:BuildPrompt(...) "{{{
	let base1 = s:regexp ? 'r' : '>'
	let base2 = s:byfname ? 'd' : '>'
	let base  = base1.base2.'> '
	let cur   = '_'
	let estr  = '"\'
	let start = escape(g:CtrlP_prompt[0], estr)
	let mid   = escape(g:CtrlP_prompt[1], estr)
	let end   = escape(g:CtrlP_prompt[2], estr)
	cal s:UpdateMatches(start.mid.end)
	" Toggling
	if !exists('a:1') || ( exists('a:1') && a:1 )
		let hiactive = 'Normal'
	elseif exists('a:1') || ( exists('a:1') && !a:1 )
		let hiactive = 'Comment'
		let base = substitute(base, '>', '-', 'g')
	endif
	let hibase = 'Comment'
	" Build it
	redr
	exe 'echohl' hibase '| echon "'.base.'"
				\ | echohl' hiactive '| echon "'.start.'"
				\ | echohl' hibase '| echon "'.mid.'"
				\ | echohl' hiactive '| echon "'.end.'"
				\ | echohl None'
	" Append the cursor _ at the end
	if empty(mid) && ( !exists('a:1') || ( exists('a:1') && a:1 ) )
		exe 'echohl' hibase '| echon "'.cur.'" | echohl None'
	endif
endfunc "}}}

"Mightdo: PrtSelectJump() cycles through matches. /medium
" Prt Actions {{{
func! s:PrtClear()
	let g:CtrlP_prompt = ['','','']
	cal s:BuildPrompt()
endfunc

func! s:PrtAdd(char)
	let g:CtrlP_prompt[0] = g:CtrlP_prompt[0] . a:char
	cal s:BuildPrompt()
endfunc

func! s:PrtBS()
	let str = g:CtrlP_prompt[0]
	let g:CtrlP_prompt[0] = strpart(str, -1, strlen(str))
	cal s:BuildPrompt()
endfunc

func! s:PrtDelete()
	let g:CtrlP_prompt[1] = strpart(g:CtrlP_prompt[2], 0, 1)
	let g:CtrlP_prompt[2] = strpart(g:CtrlP_prompt[2], 1)
	cal s:BuildPrompt()
endfunc

func! s:PrtCurLeft()
	if !empty(g:CtrlP_prompt[0])
		let g:CtrlP_prompt[2] = g:CtrlP_prompt[1] . g:CtrlP_prompt[2]
		let g:CtrlP_prompt[1] = strpart(g:CtrlP_prompt[0], strlen(g:CtrlP_prompt[0]) - 1)
		let g:CtrlP_prompt[0] = strpart(g:CtrlP_prompt[0], -1, strlen(g:CtrlP_prompt[0]))
	endif
	cal s:BuildPrompt()
endfunc

func! s:PrtCurRight()
	let g:CtrlP_prompt[0] = g:CtrlP_prompt[0] . g:CtrlP_prompt[1]
	cal s:PrtDelete()
endfunc

func! s:PrtCurStart()
	let str = g:CtrlP_prompt[0] . g:CtrlP_prompt[1] . g:CtrlP_prompt[2]
	let g:CtrlP_prompt[2] = strpart(str, 1)
	let g:CtrlP_prompt[1] = strpart(str, 0, 1)
	let g:CtrlP_prompt[0] = ''
	cal s:BuildPrompt()
endfunc

func! s:PrtCurEnd()
	let str = g:CtrlP_prompt[0] . g:CtrlP_prompt[1] . g:CtrlP_prompt[2]
	let g:CtrlP_prompt[2] = ''
	let g:CtrlP_prompt[1] = ''
	let g:CtrlP_prompt[0] = str
	cal s:BuildPrompt()
endfunc

func! s:PrtDeleteWord()
	let str = g:CtrlP_prompt[0]
	if match(str, ' [^ ]\+$') >= 0
		let str = matchstr(str, '^.\+ \ze[^ ]\+$')
	elseif match(str, '[ ]\+$') >= 0
		let str = matchstr(str, '^.*[^ ]\+\ze[ ]\+$')
	elseif match(str, ' ') <= 0
		let str = ''
	endif
	let g:CtrlP_prompt[0] = str
	cal s:BuildPrompt()
endfunc

func! s:PrtSelectMove(dir)
	exe 'keepj norm!' a:dir
	let g:CtrlP_cline = line('.')
endfunc

func! s:PrtSelectJump(char,...)
	let lines = map(b:matched, 'substitute(v:val, "^> ", "", "g")')
	if exists('a:1')
		let lines = map(lines, 'split(v:val, ''[\/]\ze[^\/]\+$'')[-1]')
	endif
	if match(lines, '\c^'.a:char) >= 0
		exe match(lines, '\c^'.a:char) + 1
		let g:CtrlP_cline = line('.')
	endif
endfunc

func! s:PrtClearCache()
	cal ctrlp#clearallcaches()
	sil! cal s:SetLines(s:itemtype)
	cal s:BuildPrompt()
endfunc
"}}}

" MapKeys {{{
func! s:MapKeys(...)
	" Normal keystrokes
	let func = !exists('a:1') || ( exists('a:1') && a:1 ) ? 'PrtAdd' : 'PrtSelectJump'
	let sjbyfname = s:byfname && func == 'PrtSelectJump' ? ', 1' : ''
	for each in range(32,126)
		exe "nn \<buffer> \<silent> \<char-".each."> :cal \<SID>".func."(\"".escape(nr2char(each), '"|\')."\"".sjbyfname.")\<cr>"
	endfor
	if exists('a:2') | retu | endif
	" Special keystrokes
	if exists('a:1') && !a:1
		cal s:MapSpecs('unmap')
	else
		cal s:MapSpecs()
	endif
endfunc

func! s:MapSpecs(...)
	let prtmaps = {
				\ 'PrtBS()':                    ['<bs>'],
				\ 'PrtDelete()':                ['<del>'],
				\ 'PrtDeleteWord()':            ['<c-w>'],
				\ 'PrtClear()':                 ['<c-u>'],
				\ 'PrtSelectMove("j")':         ['<c-n>', '<c-j>', '<down>'],
				\ 'PrtSelectMove("k")':         ['<c-p>', '<c-k>', '<up>'],
				\ 'AcceptSelection("e")':       ['<cr>'],
				\ 'AcceptSelection("h")':       ['<c-cr>', '<c-s>'],
				\ 'AcceptSelection("t")':       ['<c-t>'],
				\ 'AcceptSelection("v")':       ['<c-v>'],
				\ 'ToggleFocus()':              ['<tab>'],
				\ 'ToggleRegex()':              ['<c-r>'],
				\ 'ToggleByFname()':            ['<c-d>'],
				\ 'ToggleType(1)':              ['<c-f>', '<c-up'],
				\ 'ToggleType(-1)':             ['<c-b>', '<c-down>'],
				\ 'Type(0)':                    ['<m-1>'],
				\ 'Type(1)':                    ['<m-2>'],
				\ 'Type(2)':                    ['<m-3>'],
				\ 'PrtCurStart()':              ['<c-a>'],
				\ 'PrtCurEnd()':                ['<c-e>'],
				\ 'PrtCurLeft()':               ['<c-h>', '<left>'],
				\ 'PrtCurRight()':              ['<c-l>', '<right>'],
				\ 'PrtClearCache()':            ['<F5>'],
				\ 'BufOpen("ControlP", "del")': ['<esc>', '<c-c>'],
				\ }
	if type(s:urprtmaps) == 4
		cal extend(prtmaps, s:urprtmaps)
	endif
	" toggleable mappings for toggleable features
	let prttempdis = {
				\ 'Type(2)': ['<m-3>'],
				\ }
	for each in keys(prttempdis)
		if g:ctrlp_mru_files && !has_key(prtmaps, each)
			cal extend(prtmaps, {each:prttempdis[each]})
		elseif !g:ctrlp_mru_files
			cal remove(prtmaps, each)
		endif
	endfor
	if exists('a:1') && a:1 == 'unmap'
		let prtunmaps = [
					\ 'PrtBS()',
					\ 'PrtDelete()',
					\ 'PrtDeleteWord()',
					\ 'PrtClear()',
					\ 'PrtCurStart()',
					\ 'PrtCurEnd()',
					\ 'PrtCurLeft()',
					\ 'PrtCurRight()',
					\ ]
		for each in prtunmaps | for kp in prtmaps[each]
			exe 'nn <buffer> <silent>' kp '<Nop>'
		endfor | endfor
	else
		for each in keys(prtmaps) | for kp in prtmaps[each]
			exe 'nn <buffer> <silent>' kp ':cal <SID>'.each.'<cr>'
		endfor | endfor
	endif
endfunc
"}}}

" ToggleFocus {{{
func! s:Focus()
	retu !exists('b:focus') ? 1 : b:focus
endfunc

func! s:ToggleFocus()
	let b:focus = !exists('b:focus') || b:focus ? 0 : 1
	cal s:MapKeys(b:focus)
	cal s:statusline(b:focus)
	cal s:BuildPrompt(b:focus)
endfunc
"}}}

func! s:ToggleRegex() "{{{
	let s:regexp = s:regexp ? 0 : 1
	cal s:statusline()
	cal s:BuildPrompt(s:Focus())
endfunc "}}}

func! s:ToggleByFname() "{{{
	let s:byfname = s:byfname ? 0 : 1
	cal s:MapKeys(s:Focus(), 1)
	cal s:statusline()
	cal s:BuildPrompt(s:Focus())
endfunc "}}}

func! s:ToggleType(dir) "{{{
	let len = 1 + g:ctrlp_mru_files
	let s:itemtype = s:walker(len, s:itemtype, a:dir)
	cal s:Type(s:itemtype)
endfunc "}}}

func! s:Type(type) "{{{
	let s:itemtype = a:type
	cal s:syntax()
	cal s:SetLines(s:itemtype)
	cal s:statusline()
	cal s:BuildPrompt(s:Focus())
endfunc "}}}

" ctrlp#SetWorkingPath(...) {{{
func! s:FindRoot(curr, mark)
	if !empty(globpath(a:curr, a:mark))
		exe 'chdir' a:curr
	else
		let parent = substitute(a:curr, '[\/]\zs[^\/]\+[\/]\?$', '', '')
		if parent != a:curr
			cal s:FindRoot(parent, a:mark)
		endif
	endif
endfunc

func! ctrlp#SetWorkingPath(...)
	let l:pathmode = 2
	if exists('a:1')
		let l:pathmode = a:1
	endif
	if match(expand('%:p'), '^\<.\+\>://.*') >= 0
				\ || !s:pathmode || !l:pathmode
		retu
	endif
	if exists('+acd')
		se noacd
	endif
	exe 'chdir' fnameescape(expand('%:p:h'))
	if s:pathmode == 1 || l:pathmode == 1 | retu | endif
	let markers = [
				\ 'root.dir',
				\ '.vimprojects',
				\ '.git/',
				\ '_darcs/',
				\ '.hg/',
				\ '.bzr/',
				\ ]
	if exists('g:ctrlp_root_markers')
				\ && type(g:ctrlp_root_markers) == 3
				\ && !empty(g:ctrlp_root_markers)
		cal extend(markers, g:ctrlp_root_markers, 0)
	endif
	for marker in markers
		cal s:FindRoot(getcwd(), marker)
		if getcwd() != expand('%:p:h') | break | endif
	endfor
endfunc
"}}}

func! s:AcceptSelection(mode,...) "{{{
	let md = a:mode
	let matchstr = matchstr(getline('.'), '^> \zs.\+\ze\t*$')
	let filepath = s:itemtype ? matchstr : getcwd().ctrlp#utils#lash().matchstr
	let filename = split(filepath, ctrlp#utils#lash())[-1]
	" If only need the full path
	if exists('a:1') && a:1 | retu filepath | endif
	" Remove the prompt and match window
	cal s:BufOpen('ControlP', 'del')
	" Split the mode string if it's longer than 1 char
	if len(md) > 1
		let mds = split(md, '\zs')
		let md = mds[0]
	endif
	" Do something with the selected entry
	if md == 't' || s:splitwin == 1 " in new tab
		tabnew
		let cmd = 'e'
	elseif md == 'h' || s:splitwin == 2 " in new hor split
		let cmd = 'new'
	elseif md == 'v' || s:splitwin == 3 " in new ver split
		let cmd = 'vne'
	elseif md == 'e' || !s:splitwin " in current window
		let cmd = 'e'
	endif
	let bufnum = bufnr(filename)
	if bufnum > 0 && bufwinnr(bufnum) > 0
		exe 'b' bufnum
	else
		exe 'bo '.cmd.' '.filepath
	endif
	if exists('s:jmpln')
		exe s:jmpln
		keepj norm! 0zz
	endif
	ec
endfunc "}}}

" Helper functions {{{
func! s:compare(s1, s2)
	" by length
	let str1 = strlen(a:s1)
	let str2 = strlen(a:s2)
	retu str1 == str2 ? 0 : str1 > str2 ? 1 : -1
endfunc

func! s:walker(max, pos, dir, ...)
	if a:dir == 1
		let pos = a:pos < a:max ? a:pos + 1 : 0
	elseif a:dir == -1
		let pos = a:pos > 0 ? a:pos - 1 : a:max
	endif
	if !g:ctrlp_mru_files && pos == 2
				\ && !exists('a:1')
		let jmp = pos == a:max ? 0 : 3
		let pos = a:pos == 1 ? jmp : 1
	endif
	retu pos
endfunc

func! s:statusline(...)
	let itemtypes = {
				\ 0: ['files', 'fil'],
				\ 1: ['buffers', 'buf'],
				\ 2: ['recent\ files', 'mru'],
				\ }
	if !g:ctrlp_mru_files
		cal remove(itemtypes, 2)
	endif
	let max     = len(itemtypes) - 1
	let next    = itemtypes[s:walker(max, s:itemtype,  1, 1)][1]
	let prev    = itemtypes[s:walker(max, s:itemtype, -1, 1)][1]
	let item    = itemtypes[s:itemtype][0]
	let focus   = s:Focus() ? 'prt'   : 'win'
	let byfname = s:byfname ? 'file'  : 'path'
	let regex   = s:regexp  ? '%#Conditional#\ regex\ %*' : ''
	let focus   = '%#MatchParen#\ '.focus.'\ %*'
	let byfname = '%#Character#\ '.byfname.'\ %*'
	let item    = '%#Constant#\ '.item.'\ %*'
	exe 'setl stl='.focus.byfname.regex.'\ +-<'.prev.'>-{'.item.'}-<'.next.'>-+'
endfunc

func! s:matchsubstr(item, pat)
	retu match(split(a:item, '[\/]\ze[^\/]\+$')[-1], a:pat)
endfunc

func! s:matchlists(item, lst)
	for each in a:lst
		if match(a:item, each) >= 0 | retu 0 | endif
	endfor
	retu 1
endfunc

func! s:progress(entries)
	exe 'setl stl=%#WarningMsg#\ '.len(a:entries).'\ %*\ '
	redr
endfunc

func! s:syntax()
	syn match CtrlPNoEntries '^ == NO MATCHES ==$'
	syn match CtrlPNoEntries '^ == DISABLED ==$'
	syn match CtrlPLineMarker '^>'
	hi link CtrlPNoEntries Error
	hi CtrlPLineMarker guifg=bg
endfunc
"}}}

func! s:SetLines(type) "{{{
	let s:itemtype = a:type
	if !s:itemtype
		let s:lines = s:ListAllFiles(getcwd())
	elseif s:itemtype == 1
		let s:lines = s:ListAllBuffers()
	elseif s:itemtype >= 2
		let s:lines = s:hooks(s:itemtype)
	endif
endfunc "}}}

func! s:hooks(type) "{{{
	let types = {
				\ '2': 'ctrlp#mrufiles#list(-1)'
				\ }
	retu eval(types[a:type])
endfunc "}}}

func! ctrlp#init(type, ...) "{{{
	if exists('a:1')
		sil! cal ctrlp#SetWorkingPath(a:1)
	else
		sil! cal ctrlp#SetWorkingPath()
	endif
	sil! cal s:BufOpen('ControlP')
	sil! cal s:SetupBlank()
	sil! cal s:MapKeys()
	sil! cal s:SetLines(a:type)
	cal s:statusline()
	cal s:BuildPrompt()
	sil! cal s:syntax()
endfunc "}}}

aug CtrlPAug "{{{
	au!
	au BufLeave,WinLeave ControlP cal s:BufOpen('ControlP', 'del')
aug END "}}}

" vim:fen:fdl=0:ts=2:sw=2:sts=2
