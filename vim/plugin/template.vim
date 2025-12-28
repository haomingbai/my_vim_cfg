" 新文件自动插入模板（复刻 lua/config/tpl.lua）

if exists('g:loaded_repo_template')
  finish
endif
let g:loaded_repo_template = 1

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
  " 只处理带后缀的新文件
  let l:ext = fnamemodify(a:filepath, ':e')
  if empty(l:ext)
    return
  endif

  " 模板目录：与仓库布局一致（vim/vim/templates）
  let l:repo_root = fnamemodify(expand('<sfile>:p'), ':h:h:h')
  let l:tpl_path = l:repo_root . '/templates/' . l:ext . '.tpl'

  if !filereadable(l:tpl_path)
    return
  endif

  let l:lines = readfile(l:tpl_path)
  let l:lines = s:ApplyTemplateVars(l:lines, a:filepath)

  " 插入到文件顶部
  call append(0, l:lines)

  " 如果文件原本是一个空行，插入后会在模板后保留那行空行；这里保持简单不强删。
endfunction

augroup RepoNewFileTemplate
  autocmd!
  autocmd BufNewFile *.* call s:InsertTemplateForNewFile(expand('<afile>:p'))
augroup END
