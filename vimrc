" Vim 配置入口（部署到 ~/.vimrc 的推荐方式见本目录 README.md）
" 目标：复刻你现有的 Neovim 工作流（模板、运行、LSP/补全、状态栏等）

" ============ 基础设置（对齐你当前 init.lua） ============
set nocompatible

set number
set relativenumber
set mouse=a

set hlsearch
set ignorecase
set smartcase

set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set fileencoding=utf-8

set tabstop=2
set shiftwidth=2
set expandtab

" 颜色
if has('termguicolors')
  set termguicolors
endif
silent! colorscheme vim
if !exists('g:colors_name')
  colorscheme default
endif

set updatetime=300

" ============ 命令行补全（避免被状态栏刷新影响） ============
" 使用 Vim 原生命令行补全（wildmenu）。
set wildmenu
set wildmode=longest:full,full

" 给命令行多留一行，避免消息/补全被状态栏重绘顶掉
set cmdheight=2

" 命令行补全闪烁：多数来自 Coc 的 CursorHold/CursorHoldI 定时刷新触发重绘。
" 这里不改 updatetime（避免 Tab 变卡），而是在命令行期间临时忽略 Hold 事件。
let s:repo_saved_eventignore = ''
augroup RepoCmdlineStable
  autocmd!
  autocmd CmdlineEnter * let s:repo_saved_eventignore = &eventignore | set eventignore+=CursorHold,CursorHoldI
  autocmd CmdlineLeave * let &eventignore = s:repo_saved_eventignore
augroup END

" ============ 补全体验（尽量接近 VS Code） ============
" 不自动插入/不强制预选，让你显式选择后再确认
set completeopt=menuone,noinsert,noselect

let mapleader = "\\"

" ============ 将运行时目录指向本仓库内 vim/vim ============
" 这样可以让你把整个 vim/ 文件夹作为可携带的 Vim 配置。
" 注意：如果 vimrc 通过软链接部署到 ~/.vimrc，需要 resolve() 获取真实路径。
let s:repo_root = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:runtime_dir = s:repo_root . '/vim'
execute 'set runtimepath^=' . fnameescape(s:runtime_dir)
execute 'set runtimepath+=' . fnameescape(s:runtime_dir . '/after')

" ============ 插件管理（vim-plug） ============
" 注意：不在仓库内提交 plug.vim，本地需按 README 安装。
call plug#begin(s:repo_root . '/plugged')

" 括号自动补全（替代 nvim-autopairs）
Plug 'jiangmiao/auto-pairs'

" 状态栏（替代 lualine；你当前 icons_enabled=false，所以选 lightline）
Plug 'itchyny/lightline.vim'

" LSP/补全（推荐路线：coc.nvim）
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" ============ Coc 配置位置（让 coc-settings.json 跟仓库走） ============
let g:coc_config_home = s:repo_root

" ============ Coc 扩展自动安装（近似 Mason 的 ensure_installed） ============
" 说明：这里自动安装的是 Coc 扩展（客户端侧集成），不是语言服务器二进制本体。
let g:coc_global_extensions = [
  \ 'coc-clangd',
  \ 'coc-pyright',
  \ 'coc-lua',
  \ 'coc-rust-analyzer',
  \ 'coc-texlab',
  \ ]

" ============ 你的“肌肉记忆键位” ============
" 运行代码：<F5>
" 跳转：<F12>
" 引用：<S-F12> 在 Vim 里通常显示为 <F24>
" hover：<Leader>h
" signature：<Leader>s
" format：尽量保留 <C-I>，但 Vim 中 <C-I> 与 <Tab> 等价，可能与跳转列表冲突

" coc：跳转/引用/hover/签名/格式化
nmap <silent> <F12> <Plug>(coc-definition)
" Shift+F12 通常是 <F24>
nmap <silent> <F24> <Plug>(coc-references)

" Ctrl+左键点击：跳转到定义（需要终端/GUI 能上报 Ctrl+鼠标事件）
nnoremap <silent> <C-LeftMouse> <LeftMouse><Plug>(coc-definition)

nnoremap <silent> <Leader>h :call CocActionAsync('doHover')<CR>
nnoremap <silent> <Leader>s :call CocActionAsync('showSignatureHelp')<CR>

" 保留你原来的 <C-I>：格式化
nnoremap <silent> <C-I> :call CocAction('format')<CR>

" Insert 模式补全交互（coc.nvim 官方推荐写法，兼容 Vim 的 PUM/浮动补全）
function! s:CheckBackspace() abort
  let l:col = col('.') - 1
  return !l:col || getline('.')[l:col - 1]  =~# '\\s'
endfunction

" Tab/Shift-Tab：在补全菜单中切换；否则按需触发补全/插入 Tab
inoremap <silent><expr> <Tab>
  \ coc#pum#visible() ? coc#pum#next(1) :
  \ <SID>CheckBackspace() ? "\<Tab>" :
  \ coc#refresh()

inoremap <silent><expr> <S-Tab>
  \ coc#pum#visible() ? coc#pum#prev(1) :
  \ "\<C-h>"

" Up/Down：在补全菜单里移动（否则正常方向键）
inoremap <silent><expr> <Down> coc#pum#visible() ? coc#pum#next(1) : "\<Down>"
inoremap <silent><expr> <Up> coc#pum#visible() ? coc#pum#prev(1) : "\<Up>"

" Enter：只有在“已选中候选项”时才确认；否则保持正常回车（即使菜单可见）
inoremap <silent><expr> <CR>
  \ coc#pum#visible() && get(coc#pum#info(), 'index', -1) >= 0 ? coc#pum#confirm() : "\<CR>"

" Esc：关闭补全弹窗
inoremap <silent><expr> <Esc> coc#pum#visible() ? coc#pum#cancel() . "\<Esc>" : "\<Esc>"

" ============ 复制到系统剪贴板（Ctrl+Shift+C） ============
" 说明：需要 Vim 编译时带 +clipboard，且终端不拦截该快捷键。
vnoremap <silent> <C-S-C> "+y
nnoremap <silent> <C-S-C> "+yy
inoremap <silent> <C-S-C> <Esc>"+yygi

" ============ 加载仓库内的功能脚本（模板/运行/状态栏） ============
" 这些脚本位于 vim/vim/plugin/ 下，会被 runtimepath 自动加载。

" ============ 文件类型特化（markdown 缩进） ============
" 见 vim/vim/after/ftplugin/markdown.vim
