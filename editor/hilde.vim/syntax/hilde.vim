" Modified by Heiko Zimmermann for Hilde, 2026.
" Language:    Hilde
" Filenames:   *.hiq (module body), *.hih (module interface)
"
" The groups follow the compiler's lexer, lib/Lexer.mll.  A keyword or an
" operator added there is added here as well.

" quit when a syntax file was already loaded
if exists("b:current_syntax")
	finish
endif
let s:keepcpo = &cpo
set cpo&vim

syntax case match
syntax iskeyword @,48-57,_


" Section: Names {{{1
"
" A type or constructor starts with a capital letter.  The name after a
" declaring keyword is a function or a type.  These come first, so that the
" keywords below win where both match.
syntax match   hildeType        "\<[A-Z][a-zA-Z0-9_]*\>"
syntax match   hildeFunction    "\(\<\(function\|method\)\s\+\)\@<=[a-zA-Z][a-zA-Z0-9_]*"
syntax match   hildeTypedef     "\(\<\(record\|union\|typeclass\|type\|instance\)\s\+\)\@<=[a-zA-Z][a-zA-Z0-9_]*"
syntax match   hildeNamedArg    "\<[a-zA-Z][a-zA-Z0-9_]*\>\ze\s*=>"


" Section: Keywords {{{1
"
syntax keyword hildeStructure   module body is import as pragma
syntax keyword hildeStorage     constant type function generic record union
syntax keyword hildeStorage     typeclass instance method let var
syntax keyword hildeConditional if then case of when
syntax keyword hildeRepeat      while for do from to
syntax keyword hildeStatement   return skip raise borrow
syntax keyword hildeContract    requires ensures invariant raises
syntax keyword hildeOperator    and or not sizeof
syntax keyword hildeUniverse    Free Linear Type Region
syntax match   hildeUniverse    "\<Span\>!\="
syntax keyword hildeBoolean     true false
syntax keyword hildeConstant    nil

" end and else are matches, not keywords: a keyword would win over the
" longer matches below.  The lexer reads else and if as one token when only
" blanks are between.
syntax match   hildeStructure   "\<end\>"
syntax match   hildeConditional "\<else\>"
syntax match   hildeConditional "\<else[ \t]\+if\>"
syntax match   hildeConditional "\<end\s\+\(if\|case\)\>"
syntax match   hildeRepeat      "\<end\s\+\(while\|for\)\>"
syntax match   hildeStatement   "\<end\s\+borrow\>"
syntax match   hildeStructure   "\<end\s\+module\(\s\+body\)\=\>"

" The directives that read files, SQL or C at compile time.
syntax match   hildePreproc     "@\(embed\|bytes\|template\|query\|execute\|migrations\)\>"


" Section: Operators {{{1
"
syntax match   hildeDelimiter   "[;,:.]"
syntax match   hildeOperator    "[-+*/<>=|?!]"
syntax match   hildeOperator    "/=\|<=\|>=\|\.\."
syntax match   hildeOperator    "&!\=(\=\|&\~"
syntax match   hildeSpecial     ":=\|=>\|->"


" Section: Numbers {{{1
"
" Digits may be grouped with a quote, 1'000; #x, #o and #b give the base.
syntax match   hildeNumber      "\<[0-9][0-9']*"
syntax match   hildeNumber      "#x[0-9a-fA-F][0-9a-fA-F']*"
syntax match   hildeNumber      "#o[0-7][0-7']*"
syntax match   hildeNumber      "#b[01][01']*"
syntax match   hildeFloat       "\<[0-9][0-9']*\.[0-9][0-9']*\([eE][+-]\=[0-9][0-9']*\)\="
syntax match   hildeCharacter   "'\([^\\]\|\\[nrt\\]\)'"


" Section: Strings {{{1
"
" A string may span lines; a backslash escapes the next character.  A
" triple string is a docstring before a declaration; its only escape is
" a backslash before three quotes.
syntax region  hildeString      start=+"+ skip=+\\.+ end=+"+ contains=hildeEscape,@Spell
syntax match   hildeEscape      contained "\\."
syntax region  hildeDocString   start=+"""+ skip=+\\"""+ end=+"""+ contains=@Spell


" Section: Comments {{{1
"
syntax keyword hildeTodo        contained TODO FIXME XXX NOTE
syntax match   hildeComment     "--.*$" contains=hildeTodo,@Spell


" Section: Highlighting {{{1
"
highlight def link hildeComment     Comment
highlight def link hildeTodo        Todo
highlight def link hildeDocString   SpecialComment
highlight def link hildeString      String
highlight def link hildeEscape      SpecialChar
highlight def link hildeCharacter   Character
highlight def link hildeNumber      Number
highlight def link hildeFloat       Float
highlight def link hildeBoolean     Boolean
highlight def link hildeConstant    Constant
highlight def link hildeStructure   Structure
highlight def link hildeStorage     StorageClass
highlight def link hildeConditional Conditional
highlight def link hildeRepeat      Repeat
highlight def link hildeStatement   Statement
highlight def link hildeContract    PreCondit
highlight def link hildeOperator    Operator
highlight def link hildeSpecial     Special
highlight def link hildeDelimiter   Delimiter
highlight def link hildeUniverse    Type
highlight def link hildeType        Type
highlight def link hildeTypedef     Typedef
highlight def link hildeFunction    Function
highlight def link hildeNamedArg    Identifier
highlight def link hildePreproc     PreProc

let b:current_syntax = "hilde"

let &cpo = s:keepcpo
unlet s:keepcpo
