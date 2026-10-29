" Modified by Heiko Zimmermann for Hilde, 2026.
" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

let s:cpoptions = &cpoptions
set cpoptions-=C


setlocal expandtab
setlocal tabstop=4
setlocal softtabstop=4
setlocal shiftwidth=4


" Section: Comments  {{{1
"
setlocal comments=:--
setlocal commentstring=--\ %s


" Section: Matching  {{{1
"
" With the matchit plug-in, % jumps between a construct and its end.
let b:match_words = '\<if\>:\<else\>:\<end\s\+if\>,'
      \ . '\<case\>\ze.*\<of\>:\<when\>:\<end\s\+case\>,'
      \ . '\<while\>:\<end\s\+while\>,'
      \ . '\<for\>\ze.*\<do\>:\<end\s\+for\>,'
      \ . '\<borrow\>:\<end\s\+borrow\>'
let b:undo_ftplugin = 'setlocal expandtab< tabstop< softtabstop< shiftwidth<'
      \ . ' comments< commentstring< | unlet! b:match_words'


" 1}}}
" Reset cpoptions
let &cpoptions = s:cpoptions
unlet s:cpoptions

finish " 1}}}
