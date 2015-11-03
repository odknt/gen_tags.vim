" ============================================================================
" File: gen_tags.vim
" Author: Jia Sui <jsfaint@gmail.com>
" Description: This file contains some command function for other file.
" ============================================================================

"Check if has vimproc
function! gen_tags#has_vimproc()
  let l:has_vimproc = 0
  silent! let l:has_vimproc = vimproc#version()
  return l:has_vimproc
endfunction

"Find the root of the project
"if the project managed by git, find the git root.
"else return the current work directory.
function! gen_tags#find_project_root()
  if gen_tags#has_vimproc()
    call vimproc#system2('git rev-parse --show-toplevel')
    if vimproc#get_last_status() == 0
      let l:sub = vimproc#popen2('git rev-parse --show-toplevel')
      let l:line = l:sub.stdout.read()
      let l:line = substitute(l:line, '\r\|\n', '', 'g')
      return l:line
    endif
  else
    if has('win32') || has('win64')
      let l:path=getcwd()
      let l:path=substitute(l:path, '\\', '/', 'g')
      return l:path
    else
      return getcwd()
    endif
  endif
endfunction