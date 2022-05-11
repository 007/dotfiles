" Vim Compiler File
" Compiler: rego
" Maintainer: Ryan Moore
" Last Change: 2022 Feb 15

if exists("current_compiler")
	finish
endif
let current_compiler = "rego"

if exists(":CompilerSet") != 2 
	command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo-=C

let s:test_base = expand("%:r")
let s:test_ext  = expand("%:e")

" CompilerSet makeprg=opa\ test\ --explain=full\ %
CompilerSet makeprg="opa test --explain=full s:test_base . \"_test\" . s:test_ext"

let &cpo = s:cpo_save
unlet s:cpo_save
