" <F5> 运行当前文件：替代 code_runner.nvim

if exists('g:loaded_repo_run_code')
  finish
endif
let g:loaded_repo_run_code = 1

function! s:RunInTerminal(cmd) abort
  " 尽量复用：每次在底部分屏打开终端
  silent! write
  botright split
  resize 12
  " 通过 shell 执行命令，确保支持 cd/&& 等 shell 语法。
  " 否则 Vim 会尝试直接执行 `cd`（可能落到 /usr/bin/cd），导致“参数太多”。
  if exists('*term_start')
    call term_start([&shell, &shellcmdflag, a:cmd], {'curwin': v:true})
  else
    execute 'terminal ' . &shell . ' ' . &shellcmdflag . ' ' . shellescape(a:cmd)
  endif
  startinsert
endfunction

function! RepoRunCode() abort
  let l:ft = &filetype
  let l:full = expand('%:p')
  let l:dir = expand('%:p:h')
  let l:name_noext = expand('%:t:r')

  if empty(l:full)
    echoerr 'No file name'
    return
  endif

  if l:ft ==# 'python'
    call s:RunInTerminal('python3 -u ' . shellescape(l:full))
    return
  endif

  if l:ft ==# 'c'
    let l:more = input('Add more args: ')
    let l:out = '/tmp/' . l:name_noext
    let l:cmd = 'cd ' . shellescape(l:dir) . ' && cc ' . shellescape(l:full) . ' -o ' . shellescape(l:out) . ' -Wall '
    if !empty(l:more)
      let l:cmd .= l:more . ' '
    endif
    let l:cmd .= '&& time ' . shellescape(l:out) . ' && rm ' . shellescape(l:out)
    call s:RunInTerminal(l:cmd)
    return
  endif

  if l:ft ==# 'cpp'
    let l:more = input('Add more args: ')
    let l:out = '/tmp/' . l:name_noext
    let l:cmd = 'cd ' . shellescape(l:dir) . ' && c++ -std=c++23 -fmodules -fsearch-include-path ' . shellescape(l:full) . ' -o ' . shellescape(l:out) . ' -Wall '
    if !empty(l:more)
      let l:cmd .= l:more . ' '
    endif
    let l:cmd .= '&& time ' . shellescape(l:out) . ' && rm ' . shellescape(l:out)
    call s:RunInTerminal(l:cmd)
    return
  endif

  echo 'No runner for filetype: ' . l:ft
endfunction

nnoremap <silent> <F5> :call RepoRunCode()<CR>
