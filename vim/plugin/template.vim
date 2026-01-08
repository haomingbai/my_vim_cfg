" 新文件自动插入模板（复刻 lua/config/tpl.lua）

if exists('g:loaded_repo_template')
  finish
endif
let g:loaded_repo_template = 1

" 在脚本加载时固定仓库根目录，避免在 autocmd 回调里 expand('<sfile>') 失效。
let s:repo_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')

function! s:ApplyTemplateVars(lines, filepath) abort
  let l:filename = fnamemodify(a:filepath, ':t')
  let l:date = strftime('%Y-%m-%d')
  let l:year = strftime('%Y')

  let l:out = []
  for l:line in a:lines
    let l:line = substitute(l:line, '\${FILE}', l:filename, 'g')
    let l:line = substitute(l:line, '\${DATE}', l:date, 'g')
    let l:line = substitute(l:line, '\${YEAR}', l:year, 'g')
    call add(l:out, l:line)
  endfor
  return l:out
endfunction

function! s:InsertTemplateForNewFile(filepath) abort
  " 避免重复插入（BufNewFile + BufWritePre）
  if exists('b:repo_template_applied') && b:repo_template_applied
    return
  endif

  let l:target = a:filepath
  if empty(l:target)
    let l:target = expand('%:p')
  endif
  if empty(l:target)
    return
  endif

  " 只在“空缓冲区”上自动插入，避免影响已有内容。
  if line('$') != 1 || getline(1) !=# ''
    return
  endif

  " 只处理带后缀的新文件
  let l:ext = fnamemodify(l:target, ':e')
  if empty(l:ext)
    return
  endif

  let l:tpl_path = s:repo_root . '/templates/' . l:ext . '.tpl'

  if !filereadable(l:tpl_path)
    return
  endif

  let l:lines = readfile(l:tpl_path)
  let l:lines = s:ApplyTemplateVars(l:lines, l:target)

  " 插入到文件顶部：空缓冲区用 setline 避免多一个空行。
  call setline(1, l:lines)
  let b:repo_template_applied = 1

  " 命中模板时，将光标移动到最后一行。
  " 使用 keepjumps 避免污染跳转列表。
  silent! keepjumps call cursor(line('$'), 1)

  " 如果文件原本是一个空行，插入后会在模板后保留那行空行；这里保持简单不强删。
endfunction

augroup RepoNewFileTemplate
  autocmd!
  autocmd BufNewFile * call s:InsertTemplateForNewFile(expand('<afile>:p'))
  " 支持从无名缓冲区直接 :w foo.ext 创建新文件的场景
  autocmd BufWritePre * if !filereadable(expand('<afile>:p')) | call s:InsertTemplateForNewFile(expand('<afile>:p')) | endif
augroup END
