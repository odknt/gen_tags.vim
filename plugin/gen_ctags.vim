" ============================================================================
" File: gen_ctags.vim
" Arthur: Jia Sui <jsfaint@gmail.com>
" Description:  1. Generate ctags under the given folder.
"               2. Add db when vim is open.
"               3. support generate third-party project ctags
" Required: This script requires ctags.
" Usage:
"   1. Generate All tags:
"       :GenAll or <leader>ga
"   2. Generate ctags db:
"       :GenCtags or <leader>gt
"   3. Edit Extend project list
"       :EditExt or <leader>ge
"   4. Generate Extend ctags based on the content of ext.conf
"       :GenExt
"   5. Clear tags file
"       :ClearTags
" ============================================================================

let s:tagdir = expand("$HOME/.cache/tags_dir")
let s:ctags_db = "prj_tags"
let s:ext = "ext.conf"

if !executable('ctags')
  echomsg "ctags not found"
  echomsg "gen_tags.vim need ctags to generate tags"
  finish
endif

"Get db name, remove / : with , beacause they are not valid filename
function! s:get_db_name(path)
  let l:fold = substitute(a:path, '/\|\\\|\ \|:\|\.', '', 'g')
  return l:fold
endfunction

function! s:fix_path_for_windows(path)
  if has('win32') || has('win64')
    let l:path = substitute(a:path, '\\', '/', 'g')
    return l:path
  else
    return a:path
  endif
endfunction

function! s:get_project_ctags_dir()
  let l:dir = expand(s:tagdir . "/" . s:get_db_name(gen_tags#find_project_root()))

  let l:dir = s:fix_path_for_windows(l:dir)

  return l:dir
endfunction

function! s:get_project_ctags_name()
  let l:file = expand(s:get_project_ctags_dir() . "/" . s:ctags_db)
  let l:file = s:fix_path_for_windows(l:file)

  return l:file
endfunction

function! s:get_extend_ctags_list()
  let l:file = expand(s:get_project_ctags_dir() . "/" . s:ext)
  let l:file = s:fix_path_for_windows(l:file)

  if filereadable(l:file)
    let l:list = readfile(l:file)
    return l:list
  endif

  return []
endfunction

function! s:get_extend_ctags_name(item)
  if has('win32') || has('win64')
    let l:item = substitute(a:item, '\\', '/', 'g')
  else
    let l:item = a:item
  endif

  let l:file = expand(s:get_project_ctags_dir() . "/" . s:get_db_name(l:item))
  let l:file = s:fix_path_for_windows(l:file)

  return l:file
endfunction

"Create ctags root dir and cwd db dir.
function! s:make_ctags_dir(dir)
  if !isdirectory(s:tagdir)
    call mkdir(s:tagdir, 'p')
  endif

  if !isdirectory(a:dir)
    call mkdir(a:dir, 'p')
  endif
endfunction

function! s:add_ctags(file)
  if filereadable(a:file)
    exec 'set tags' . "+=" . a:file
  endif
endfunction

"Only add ctags db as extension database
function! s:add_ext()
  for l:item in s:get_extend_ctags_list()
    let l:file = s:get_extend_ctags_name(l:item)
    call s:add_ctags(l:file)
  endfor
endfunction

"Generate ctags tags in cwd db dir.
"if the first parameter is null, will generate project ctags
function! s:Ctags_db_gen(filename, dir)
  echon "Generate " | echohl NonText | echon "project" | echohl None | echon " ctags database "

  let l:dir = s:get_project_ctags_dir()

  call s:make_ctags_dir(l:dir)

  if a:filename == ""
    let l:file = l:dir . "/" . s:ctags_db
    let l:cmd = 'ctags -f '. l:file . ' -R ' . gen_tags#find_project_root()
  else
    let l:file = a:filename
    let l:cmd = 'ctags -f '. l:file . ' -R ' . a:dir
  endif

  if gen_tags#has_vimproc()
    call vimproc#system_bg(l:cmd)
  else
    if has('unix')
      let l:cmd = l:cmd . ' &'
    else
      let l:cmd = 'cmd /c start ' . l:cmd
    endif

    call system(l:cmd)
  endif

  "Search for existence tags string.
  let l:ret = stridx(&tags, l:dir)
  if l:ret == -1
    call s:add_ctags(l:file)
  endif

  echohl Function | echon "[Background]" | echohl None
endfunction

function! s:Add_DBs()
  let l:file = s:get_project_ctags_name()
  call s:add_ctags(l:file)

  call s:add_ext()
endfunction

"Generate project and library ctags
function! s:Gen_all()
  echon "Generate "
  echohl NonText | echon "project" | echohl None
  echon " and "
  echohl NonText | echon "library"
  echohl None | echon " tags "

  exec "silent! GenCtags"
  exec "silent! GenExt"

  echohl Function | echon "[Done]" | echohl None
endfunction

function! s:Edit_ext()
  let l:dir = s:get_project_ctags_dir()
  call s:make_ctags_dir(l:dir)
  let l:file = l:dir . "/" . s:ext
  exec 'split' l:file
endfunction

"Geterate extend ctags
function! s:Ext_db_gen()
  for l:item in s:get_extend_ctags_list()
    let l:file = s:get_extend_ctags_name(l:item)
    call s:Ctags_db_gen(l:file, l:item)
  endfor
endfunction

"Delete exist tags file
function! s:Tags_clear()
  "Remove project ctags
  let l:file = s:get_project_ctags_name()
  if filereadable(l:file)
    call delete(l:file)
  endif

  "Remove extend ctags
  for l:item in s:get_extend_ctags_list()
    let l:file = s:get_extend_ctags_name(l:item)
    if filereadable(l:file)
      call delete(l:file)
    endif
  endfor
endfunction

"Command list
command! -nargs=0 -bar GenCtags call s:Ctags_db_gen("", "")
command! -nargs=0 -bar GenAll call s:Gen_all()
command! -nargs=0 -bar EditExt call s:Edit_ext()
command! -nargs=0 -bar GenExt call s:Ext_db_gen()
command! -nargs=0 -bar ClearTags call s:Tags_clear()

"Mapping hotkey
nmap <silent> <leader>gt :GenCtags<cr>
nmap <silent> <leader>ga :GenAll<cr>
nmap <silent> <leader>ge :EditExt<cr>

function! UpdateCtags()
  let l:dir = s:get_project_ctags_dir()
  let l:file = l:dir . "/" . s:ctags_db

  if !filereadable(l:file)
    return
  endif

  call s:Ctags_db_gen("", "")
endfunction
au BufWritePost * call UpdateCtags()

"Add db while startup
call s:Add_DBs()
