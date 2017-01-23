" Vim Compiler File
" Compiler: shellcheck
" Maintainer: Ryan Moore
" Last Change: 2017 Jan 19

if exists("current_compiler")
	finish
endif
let current_compiler = "shellcheck"

if exists(":CompilerSet") != 2 
	command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo-=C

CompilerSet makeprg=shellcheck\ -f\ gcc\ % 

let &cpo = s:cpo_save
unlet s:cpo_save
