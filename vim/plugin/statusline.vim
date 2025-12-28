" lightline 配置：替代 lualine

if exists('g:loaded_repo_statusline')
  finish
endif
let g:loaded_repo_statusline = 1

" 总是显示底部状态栏（Vim 默认 single-window 可能不显示）
set laststatus=2
" lightline 已展示模式，避免额外的 "-- INSERT --"
set noshowmode

let g:lightline = {
      \ 'colorscheme': 'powerline',
      \ 'separator': { 'left': '|', 'right': '|' },
      \ 'subseparator': { 'left': '-', 'right': '-' },
      \ }
